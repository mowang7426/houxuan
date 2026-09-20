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

    // The upper part of the input view is normally the candidate strip.
    // Do not draw over it; only accept touches in the key area.
    CGFloat candidateHeight = MIN(64.0, self.bounds.size.height * .18);
    if (point.y < candidateHeight || point.y > self.bounds.size.height) return;

    CGFloat maxSide = MIN(self.bounds.size.width, self.bounds.size.height) * .42;
    maxSide = MAX(70.0, MIN(maxSide, 180.0));
    CGFloat hue = fmod(self.phase + point.x / MAX(self.bounds.size.width, 1.0), 1.0);
    CAShapeLayer *ripple = [CAShapeLayer layer];
    ripple.fillColor = UIColor.clearColor.CGColor;
    ripple.strokeColor = [UIColor colorWithHue:hue saturation:.9 brightness:MAX(.4, self.brightness) alpha:MAX(.25, self.opacityValue)].CGColor;
    ripple.lineWidth = 2.0;
    CGRect startRect = CGRectMake(point.x - 1, point.y - 1, 2, 2);
    CGRect endRect = CGRectMake(point.x - maxSide / 2, point.y - maxSide / 2, maxSide, maxSide);
    ripple.path = [UIBezierPath bezierPathWithOvalInRect:startRect].CGPath;
    [self.layer addSublayer:ripple];

    CABasicAnimation *path = [CABasicAnimation animationWithKeyPath:@"path"];
    path.fromValue = (id)ripple.path;
    path.toValue = (id)[UIBezierPath bezierPathWithOvalInRect:endRect].CGPath;
    path.duration = .42;
    path.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @(.9); fade.toValue = @0; fade.duration = .42;
    [ripple addAnimation:path forKey:@"path"];
    [ripple addAnimation:fade forKey:@"fade"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [ripple removeFromSuperlayer];
    });
}
@end
