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

    // Keep the candidate/suggestion strip untouched.
    CGFloat candidateHeight = MIN(64.0, self.bounds.size.height * .18);
    if (point.y < candidateHeight || point.y > self.bounds.size.height) return;

    // This is a local key-sized glow, not a large outlined circle.
    CGFloat keySize = MIN(self.bounds.size.width / 9.0, 58.0);
    keySize = MAX(keySize, 38.0);
    CGFloat glowSize = keySize * 1.35;
    CGFloat hue = fmod(self.phase + point.x / MAX(self.bounds.size.width, 1.0), 1.0);
    UIColor *core = [UIColor colorWithHue:hue saturation:.45 brightness:1.0 alpha:.95];
    UIColor *glow = [UIColor colorWithHue:hue saturation:.9 brightness:MAX(.45, self.brightness) alpha:.55];

    // A soft filled blob gives the same illuminated-key impression as the reference.
    CALayer *light = [CALayer layer];
    light.frame = CGRectMake(point.x - keySize / 2, point.y - keySize / 2, keySize, keySize);
    light.cornerRadius = keySize / 2;
    light.backgroundColor = glow.CGColor;
    light.shadowColor = core.CGColor;
    light.shadowOpacity = .95;
    light.shadowRadius = keySize * .42;
    light.shadowOffset = CGSizeZero;
    [self.layer addSublayer:light];

    // A smaller hot center appears at the instant of the key press.
    CALayer *hot = [CALayer layer];
    CGFloat hotSize = keySize * .28;
    hot.frame = CGRectMake(point.x - hotSize / 2, point.y - hotSize / 2, hotSize, hotSize);
    hot.cornerRadius = hotSize / 2;
    hot.backgroundColor = core.CGColor;
    hot.shadowColor = UIColor.whiteColor.CGColor;
    hot.shadowOpacity = .8;
    hot.shadowRadius = 6.0;
    hot.shadowOffset = CGSizeZero;
    [self.layer addSublayer:hot];

    CAMediaTimingFunction *ease = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    CABasicAnimation *grow = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    grow.fromValue = @(.55); grow.toValue = @(glowSize / keySize); grow.duration = .34; grow.timingFunction = ease;
    [light addAnimation:grow forKey:@"localGlowGrow"];
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @(.95); fade.toValue = @0; fade.duration = .42; fade.timingFunction = ease;
    [light addAnimation:fade forKey:@"localGlowFade"];

    CABasicAnimation *hotFade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    hotFade.fromValue = @(.95); hotFade.toValue = @0; hotFade.duration = .18;
    [hot addAnimation:hotFade forKey:@"hotFade"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [light removeFromSuperlayer];
        [hot removeFromSuperlayer];
    });
}
@end
