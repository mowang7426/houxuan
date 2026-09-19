#import "RainbowEffectView.h"
#import <QuartzCore/QuartzCore.h>

static NSString * const RKPrefs = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";

@interface RainbowEffectView ()
@property(nonatomic,strong) CAGradientLayer *gradient;
@property(nonatomic,strong) CADisplayLink *displayLink;
@property(nonatomic) CGFloat phase;
@property(nonatomic) BOOL enabled;
@property(nonatomic) BOOL rippleEnabled;
@property(nonatomic) CGFloat speed;
@property(nonatomic) CGFloat brightness;
@property(nonatomic) CGFloat opacityValue;
@end

@implementation RainbowEffectView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = UIColor.clearColor;
        [self reloadConfiguration];
        _gradient = [CAGradientLayer layer];
        _gradient.frame = self.bounds;
        _gradient.startPoint = CGPointMake(0, .5);
        _gradient.endPoint = CGPointMake(1, .5);
        _gradient.colors = @[
            (id)[UIColor colorWithRed:1 green:.05 blue:.18 alpha:1].CGColor,
            (id)[UIColor colorWithRed:1 green:.55 blue:.03 alpha:1].CGColor,
            (id)[UIColor colorWithRed:.95 green:.95 blue:.05 alpha:1].CGColor,
            (id)[UIColor colorWithRed:.05 green:1 blue:.35 alpha:1].CGColor,
            (id)[UIColor colorWithRed:.02 green:.75 blue:1 alpha:1].CGColor,
            (id)[UIColor colorWithRed:.25 green:.15 blue:1 alpha:1].CGColor,
            (id)[UIColor colorWithRed:.9 green:.05 blue:.8 alpha:1].CGColor
        ];
        _gradient.opacity = self.opacityValue;
        [self.layer addSublayer:_gradient];
        self.layer.compositingFilter = @"screenBlendMode";
    }
    return self;
}

- (void)layoutSubviews { [super layoutSubviews]; self.gradient.frame = self.bounds; }

- (void)reloadConfiguration {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:RKPrefs] ?: @{};
    self.enabled = d[@"Enabled"] ? [d[@"Enabled"] boolValue] : YES;
    self.rippleEnabled = d[@"RippleEnabled"] ? [d[@"RippleEnabled"] boolValue] : YES;
    self.speed = d[@"Speed"] ? [d[@"Speed"] doubleValue] : .45;
    self.brightness = d[@"Brightness"] ? [d[@"Brightness"] doubleValue] : .85;
    self.opacityValue = d[@"Opacity"] ? [d[@"Opacity"] doubleValue] : .72;
    self.gradient.opacity = self.enabled ? self.opacityValue : 0;
}

- (void)startAnimation {
    if (!self.enabled || self.displayLink) return;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}
- (void)stopAnimation { [self.displayLink invalidate]; self.displayLink = nil; }
- (void)tick:(CADisplayLink *)link {
    self.phase += self.speed * .004;
    if (self.phase > 1) self.phase -= 1;
    CGFloat p = self.phase;
    self.gradient.startPoint = CGPointMake(-1.0 + p * 2.0, .5);
    self.gradient.endPoint = CGPointMake(1.0 + p * 2.0, .5);
}

- (void)showRippleAtPoint:(CGPoint)point {
    if (!self.enabled || !self.rippleEnabled) return;
    CGFloat maxSide = MAX(self.bounds.size.width, self.bounds.size.height) * .75;
    CAShapeLayer *ripple = [CAShapeLayer layer];
    ripple.fillColor = UIColor.clearColor.CGColor;
    ripple.strokeColor = [UIColor colorWithHue:(self.phase) saturation:.9 brightness:1 alpha:.9].CGColor;
    ripple.lineWidth = 2.5;
    ripple.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x, point.y, 2, 2)].CGPath;
    [self.layer addSublayer:ripple];
    CABasicAnimation *path = [CABasicAnimation animationWithKeyPath:@"path"];
    path.fromValue = (id)ripple.path;
    path.toValue = (id)[UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x-maxSide/2, point.y-maxSide/2, maxSide, maxSide)].CGPath;
    path.duration = .42;
    path.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @(.85); fade.toValue = @0; fade.duration = .42;
    [ripple addAnimation:path forKey:@"path"]; [ripple addAnimation:fade forKey:@"fade"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [ripple removeFromSuperlayer]; });
}
@end
