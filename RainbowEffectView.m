#import "RainbowEffectView.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

static NSString * const RKPrefs = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";
static NSString * const RKChangedNotification = @"com.minis.rainbowkeyboard.changed";

@interface RainbowEffectView ()
@property(nonatomic,strong) CADisplayLink *displayLink;
@property(nonatomic) CGFloat phase;
@property(nonatomic,strong) NSDictionary *configuration;
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
    self.configuration = d;
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

- (CGFloat)valueForKey:(NSString *)key fallback:(CGFloat)value low:(CGFloat)low high:(CGFloat)high {
    id number = self.configuration[key];
    CGFloat result = number ? [number doubleValue] : value;
    return isfinite(result) ? MIN(high, MAX(low, result)) : value;
}

- (void)showRippleAtPoint:(CGPoint)point {
    [self showGlowAtPoint:point keySize:CGSizeMake(44.0, 44.0)];
}

- (void)showGlowAtPoint:(CGPoint)point keySize:(CGSize)keySize {
    [self reloadConfiguration]; // Also refresh on touch if a notification was missed.
    NSString *bundle = NSBundle.mainBundle.bundleIdentifier.lowercaseString ?: @"";
    BOOL weType = [bundle containsString:@"wetype"];
    NSString *scope = weType ? @"WeChatKeyboard" : @"NativeKeyboard";
    if (self.configuration[scope] && ![self.configuration[scope] boolValue]) return;
    if (!self.enabled || !self.rippleEnabled) {
        for (CALayer *layer in self.layer.sublayers.copy) [layer removeFromSuperlayer];
        return;
    }

    // Keep the candidate/suggestion strip untouched.
    CGFloat candidateHeight = MIN(64.0, self.bounds.size.height * .18);
    if (point.y < candidateHeight || point.y > self.bounds.size.height) return;

    // This is a local key-sized glow, not a large outlined circle.
    CGFloat diameter = MIN(MAX(keySize.width, keySize.height), 58.0);
    diameter = MAX(diameter, 38.0);
    CGFloat glowSize = diameter * [self valueForKey:@"Spread" fallback:1.35 low:.5 high:3];
    CGFloat duration = [self valueForKey:@"Duration" fallback:.42 low:.15 high:1.2];
    CGFloat alpha = [self valueForKey:@"Opacity" fallback:.45 low:0 high:1];
    CGFloat brightness = [self valueForKey:@"Brightness" fallback:.85 low:0 high:1];
    CGFloat softness = [self valueForKey:@"Softness" fallback:8 low:0 high:24];
    CGFloat coreStrength = [self valueForKey:@"CoreStrength" fallback:.6 low:0 high:1];
    NSInteger limit = (NSInteger)[self valueForKey:@"MaxEffects" fallback:4 low:1 high:8];
    while (self.layer.sublayers.count >= (NSUInteger)(limit * 2))
        [self.layer.sublayers.firstObject removeFromSuperlayer];
    NSInteger mode = [self.configuration[@"ColorMode"] integerValue];
    self.phase = fmod(self.phase + .137, 1.0);
    CGFloat hue = mode == 1 ? [self valueForKey:@"Hue" fallback:.55 low:0 high:1] :
        (mode == 2 ? point.x / MAX(self.bounds.size.width, 1.0) : self.phase);
    UIColor *core = [UIColor colorWithHue:hue saturation:.45 brightness:brightness alpha:alpha * coreStrength];
    UIColor *glow = [UIColor colorWithHue:hue saturation:.9 brightness:brightness alpha:alpha];

    // A soft filled blob gives the same illuminated-key impression as the reference.
    CALayer *light = [CALayer layer];
    light.frame = CGRectMake(point.x - diameter / 2, point.y - diameter / 2, diameter, diameter);
    light.cornerRadius = diameter / 2;
    light.backgroundColor = glow.CGColor;
    light.shadowColor = core.CGColor;
    light.shadowOpacity = .95;
    light.shadowRadius = softness;
    light.shadowOffset = CGSizeZero;
    light.opacity = 0;
    [self.layer addSublayer:light];

    // A smaller hot center appears at the instant of the key press.
    CALayer *hot = [CALayer layer];
    CGFloat hotSize = diameter * .28;
    hot.frame = CGRectMake(point.x - hotSize / 2, point.y - hotSize / 2, hotSize, hotSize);
    hot.cornerRadius = hotSize / 2;
    hot.backgroundColor = core.CGColor;
    hot.shadowColor = UIColor.whiteColor.CGColor;
    hot.shadowOpacity = .8;
    hot.shadowRadius = softness * .5;
    hot.shadowOffset = CGSizeZero;
    hot.opacity = 0;
    [self.layer addSublayer:hot];

    CAMediaTimingFunction *ease = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    CABasicAnimation *grow = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    grow.fromValue = @(.55); grow.toValue = @(glowSize / diameter); grow.duration = duration; grow.timingFunction = ease;
    [light addAnimation:grow forKey:@"localGlowGrow"];
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @(.95); fade.toValue = @0; fade.duration = duration; fade.timingFunction = ease;
    [light addAnimation:fade forKey:@"localGlowFade"];

    CABasicAnimation *hotFade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    hotFade.fromValue = @(.95); hotFade.toValue = @0; hotFade.duration = MIN(.18, duration * .45);
    [hot addAnimation:hotFade forKey:@"hotFade"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((duration + .05) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [light removeFromSuperlayer];
        [hot removeFromSuperlayer];
    });
}
@end
