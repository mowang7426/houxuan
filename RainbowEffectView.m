#import "RainbowEffectView.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>
static NSString * const RKPath = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";
@interface RainbowEffectView ()
@property(nonatomic,strong) NSDictionary *config;
@property(nonatomic) CGFloat hue;
@property(nonatomic,strong) UIView *feedback;
@end
@implementation RainbowEffectView
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = UIColor.clearColor;
        self.clipsToBounds = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadConfiguration) name:UIApplicationDidBecomeActiveNotification object:nil];
        [self reloadConfiguration];
    }
    return self;
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)reloadConfiguration { self.config = [NSDictionary dictionaryWithContentsOfFile:RKPath] ?: @{}; }
- (CGFloat)number:(NSString *)key fallback:(CGFloat)fallback low:(CGFloat)low high:(CGFloat)high {
    id x = self.config[key];
    CGFloat v = [x respondsToSelector:@selector(doubleValue)] ? [x doubleValue] : fallback;
    return isfinite(v) ? MIN(high,MAX(low,v)) : fallback;
}
- (BOOL)flag:(NSString *)key { return !self.config[key] || [self.config[key] boolValue]; }
- (void)showRippleAtPoint:(CGPoint)point {
    [self reloadConfiguration];
    [self.feedback.layer removeAllAnimations];
    self.feedback.layer.opacity = 0;
    NSString *bid = NSBundle.mainBundle.bundleIdentifier.lowercaseString ?: @"";
    BOOL weType = [bid containsString:@"wetype"];
    if (![self flag:@"Enabled"] || ![self flag:@"RippleEnabled"] || ![self flag:weType ? @"WeChatKeyboard" : @"NativeKeyboard"]) {
        for (CALayer *l in self.layer.sublayers.copy) [l removeFromSuperlayer];
        return;
    }
    CGFloat alpha = [self number:@"Opacity" fallback:.65 low:0 high:1];
    CGFloat brightness = [self number:@"Brightness" fallback:.95 low:0 high:1];
    CGFloat duration = [self number:@"Duration" fallback:.55 low:.15 high:1.2];
    CGFloat spread = [self number:@"Spread" fallback:2 low:.5 high:3];
    CGFloat softness = [self number:@"Softness" fallback:8 low:0 high:24];
    CGFloat core = [self number:@"CoreStrength" fallback:.5 low:0 high:1];
    NSUInteger limit = (NSUInteger)[self number:@"MaxEffects" fallback:4 low:1 high:8];
    while (self.layer.sublayers.count >= limit) [self.layer.sublayers.firstObject removeFromSuperlayer];
    NSInteger mode = (NSInteger)[self number:@"ColorMode" fallback:0 low:0 high:2];
    self.hue = fmod(self.hue + .137, 1);
    CGFloat hue = mode == 1 ? [self number:@"Hue" fallback:.55 low:0 high:1] : (mode == 2 ? point.x / MAX(1,self.bounds.size.width) : self.hue);
    if ([self flag:@"BackgroundFeedback"] && self.superview) {
        if (!self.feedback) {
            self.feedback = [[UIView alloc] initWithFrame:self.superview.bounds];
            self.feedback.userInteractionEnabled = NO;
            self.feedback.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
        UIView *host = self.superview;
        self.feedback.frame = host.bounds;
        [host insertSubview:self.feedback atIndex:0];
        CAShapeLayer *sourceMask = (CAShapeLayer *)self.layer.mask;
        if ([sourceMask isKindOfClass:CAShapeLayer.class]) {
            CAShapeLayer *copyMask = [CAShapeLayer layer];
            copyMask.frame = self.feedback.bounds;
            copyMask.path = sourceMask.path;
            copyMask.fillRule = sourceMask.fillRule;
            self.feedback.layer.mask = copyMask;
        }
        self.feedback.backgroundColor = [UIColor colorWithHue:hue saturation:.75 brightness:brightness alpha:1];
        CGFloat strength = [self number:@"BackgroundStrength" fallback:.18 low:0 high:.6];
        CGFloat time = [self number:@"BackgroundDuration" fallback:.4 low:.1 high:1.5];
        CAKeyframeAnimation *feedback = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        feedback.values = @[@0,@(strength),@0];
        feedback.keyTimes = @[@0,@.12,@1]; feedback.duration = time;
        self.feedback.layer.opacity = 0;
        [self.feedback.layer addAnimation:feedback forKey:@"backgroundFeedback"];
    }
    CGFloat radius = MIN(160, MAX(24, self.bounds.size.width / 10.0 * spread));
    CALayer *pulse = [CALayer layer];
    pulse.frame = self.bounds;
    pulse.opacity = 0; // Model state remains invisible after animation removal.
    [self.layer addSublayer:pulse];
    NSMutableArray *colors = [NSMutableArray array];
    for (NSInteger i=0;i<5;i++) {
        CGFloat h = mode == 1 ? hue : fmod(hue + i * .12, 1);
        [colors addObject:(id)[UIColor colorWithHue:h saturation:.85 brightness:brightness alpha:1].CGColor];
    }
    CAGradientLayer *rainbow = [CAGradientLayer layer];
    rainbow.frame = self.bounds;
    rainbow.colors = colors;
    rainbow.startPoint = CGPointMake(0,0);
    rainbow.endPoint = CGPointMake(1,1);
    [pulse addSublayer:rainbow];
    CAShapeLayer *ring = [CAShapeLayer layer];
    ring.frame = self.bounds;
    ring.fillColor = UIColor.clearColor.CGColor;
    ring.strokeColor = UIColor.whiteColor.CGColor;
    ring.lineWidth = 4 + softness * .4;
    ring.shadowColor = UIColor.whiteColor.CGColor;
    ring.shadowOpacity = .8;
    ring.shadowRadius = softness;
    ring.shadowOffset = CGSizeZero;
    UIBezierPath *start = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x-3,point.y-3,6,6)];
    UIBezierPath *end = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x-radius,point.y-radius,2*radius,2*radius)];
    ring.path = end.CGPath;
    rainbow.mask = ring;
    CABasicAnimation *expand = [CABasicAnimation animationWithKeyPath:@"path"];
    expand.fromValue = (__bridge id)start.CGPath;
    expand.toValue = (__bridge id)end.CGPath;
    expand.duration = duration;
    expand.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [ring addAnimation:expand forKey:@"expand"];
    CALayer *flash = [CALayer layer];
    flash.frame = CGRectMake(point.x-9,point.y-9,18,18);
    flash.cornerRadius = 9;
    UIColor *tint = [UIColor colorWithHue:hue saturation:.5 brightness:brightness alpha:1];
    flash.backgroundColor = tint.CGColor;
    flash.shadowColor = tint.CGColor;
    flash.shadowRadius = softness;
    flash.shadowOpacity = .8;
    flash.shadowOffset = CGSizeZero;
    flash.opacity = 0;
    [pulse addSublayer:flash];
    CABasicAnimation *flashFade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    flashFade.fromValue = @(core); flashFade.toValue = @0; flashFade.duration = MIN(.2,duration*.5);
    [flash addAnimation:flashFade forKey:@"flash"];
    CAKeyframeAnimation *fade = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    fade.values = @[@0,@(alpha),@(alpha*.6),@0];
    fade.keyTimes = @[@0,@.08,@.45,@1];
    fade.duration = duration;
    [pulse addAnimation:fade forKey:@"fade"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)((duration+.05)*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ [pulse removeFromSuperlayer]; });
}
@end
