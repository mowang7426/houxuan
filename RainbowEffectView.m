#import "RainbowEffectView.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

static NSString * const RKPrefs = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";
static NSString * const RKChangedNotification = @"com.minis.rainbowkeyboard.changed";

@interface RainbowEffectView ()
@property(nonatomic,strong) CADisplayLink *displayLink;
@property(nonatomic) CGFloat phase;
@property(nonatomic) BOOL enabled;
@property(nonatomic) BOOL rippleEnabled;
@property(nonatomic) CGFloat speed;
@property(nonatomic) CGFloat brightness;
@property(nonatomic) CGFloat opacityValue;
@end

static void RKPrefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    RainbowEffectView *view = (__bridge RainbowEffectView *)observer;
    dispatch_async(dispatch_get_main_queue(), ^{
        [view reloadConfiguration];
    });
}

@implementation RainbowEffectView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = UIColor.clearColor;
        self.clipsToBounds = YES;
        [self reloadConfiguration];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        (__bridge const void *)self,
                                        RKPrefsChanged,
                                        (__bridge CFStringRef)RKChangedNotification,
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    return self;
}

- (void)dealloc {
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       (__bridge const void *)self,
                                       (__bridge CFStringRef)RKChangedNotification,
                                       NULL);
    [self stopAnimation];
}

- (void)reloadConfiguration {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:RKPrefs] ?: @{};
    self.enabled = d[@"Enabled"] ? [d[@"Enabled"] boolValue] : YES;
    self.rippleEnabled = d[@"RippleEnabled"] ? [d[@"RippleEnabled"] boolValue] : YES;
    self.speed = d[@"Speed"] ? [d[@"Speed"] doubleValue] : .45;
    self.brightness = d[@"Brightness"] ? [d[@"Brightness"] doubleValue] : .85;
    self.opacityValue = d[@"Opacity"] ? [d[@"Opacity"] doubleValue] : .72;
    // No permanent gradient: the effect is click-triggered only.
    [self stopAnimation];
}

- (void)startAnimation { /* Deliberately disabled: no always-on bottom glow. */ }
- (void)stopAnimation { [self.displayLink invalidate]; self.displayLink = nil; }

- (void)showRippleAtPoint:(CGPoint)point {
    if (!self.enabled || !self.rippleEnabled) return;

    // Ignore the candidate strip. The effect starts below it and is clipped
    // to this view, so it cannot paint over candidate words.
    CGFloat candidateHeight = MIN(64.0, self.bounds.size.height * .18);
    if (point.y < candidateHeight || point.y > self.bounds.size.height) return;

    CGFloat maxSide = MIN(self.bounds.size.width, self.bounds.size.height) * .42;
    maxSide = MAX(76.0, MIN(maxSide, 190.0));
    CGFloat hue = fmod(self.phase + point.x / MAX(self.bounds.size.width, 1.0), 1.0);
    UIColor *color = [UIColor colorWithHue:hue
                               saturation:.88
                               brightness:MAX(.45, self.brightness)
                                    alpha:MAX(.25, self.opacityValue)];
    UIColor *bright = [UIColor colorWithHue:hue saturation:.55 brightness:1.0 alpha:.95];

    // 1) A bright touch flash at the exact key position.
    CGFloat dotSize = 18.0;
    CALayer *flash = [CALayer layer];
    flash.frame = CGRectMake(point.x - dotSize / 2, point.y - dotSize / 2, dotSize, dotSize);
    flash.cornerRadius = dotSize / 2;
    flash.backgroundColor = bright.CGColor;
    flash.shadowColor = bright.CGColor;
    flash.shadowOpacity = .95;
    flash.shadowRadius = 13.0;
    flash.shadowOffset = CGSizeZero;
    [self.layer addSublayer:flash];

    // 2) A soft halo grows with the water ripple.
    CALayer *halo = [CALayer layer];
    halo.frame = CGRectMake(point.x - 10, point.y - 10, 20, 20);
    halo.cornerRadius = 10;
    halo.backgroundColor = color.CGColor;
    halo.shadowColor = bright.CGColor;
    halo.shadowOpacity = .85;
    halo.shadowRadius = 16.0;
    halo.shadowOffset = CGSizeZero;
    [self.layer addSublayer:halo];

    // 3) Two rings make the expansion look like illuminated water, not a
    // single thin outline.
    NSMutableArray *rings = [NSMutableArray array];
    for (NSInteger i = 0; i < 2; i++) {
        CAShapeLayer *ring = [CAShapeLayer layer];
        ring.fillColor = UIColor.clearColor.CGColor;
        ring.strokeColor = (i == 0 ? bright : color).CGColor;
        ring.lineWidth = (i == 0 ? 2.8 : 6.0);
        ring.shadowColor = bright.CGColor;
        ring.shadowOpacity = (i == 0 ? .9 : .55);
        ring.shadowRadius = (i == 0 ? 8.0 : 13.0);
        ring.shadowOffset = CGSizeZero;
        ring.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - 2, point.y - 2, 4, 4)].CGPath;
        [self.layer addSublayer:ring];
        [rings addObject:ring];

        CGFloat delay = i == 0 ? 0.0 : .055;
        CGFloat end = maxSide * (i == 0 ? .5 : .62);
        CABasicAnimation *path = [CABasicAnimation animationWithKeyPath:@"path"];
        path.fromValue = (id)ring.path;
        path.toValue = (id)[UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - end / 2, point.y - end / 2, end, end)].CGPath;
        path.beginTime = delay;
        path.duration = .52;
        path.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fade.fromValue = @(.95); fade.toValue = @0;
        fade.beginTime = delay; fade.duration = .52;
        [ring addAnimation:path forKey:@"ripplePath"];
        [ring addAnimation:fade forKey:@"rippleFade"];
    }

    // The flash fades quickly while the halo blooms, giving a visible click.
    CABasicAnimation *flashFade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    flashFade.fromValue = @(.95); flashFade.toValue = @0;
    flashFade.duration = .20;
    [flash addAnimation:flashFade forKey:@"flashFade"];
    CABasicAnimation *haloScale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    haloScale.fromValue = @(.6); haloScale.toValue = @(maxSide / 34.0);
    haloScale.duration = .46;
    haloScale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [halo addAnimation:haloScale forKey:@"haloScale"];
    CABasicAnimation *haloFade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    haloFade.fromValue = @(.35); haloFade.toValue = @0; haloFade.duration = .46;
    [halo addAnimation:haloFade forKey:@"haloFade"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [flash removeFromSuperlayer];
        [halo removeFromSuperlayer];
        for (CALayer *ring in rings) [ring removeFromSuperlayer];
    });
}
@end
