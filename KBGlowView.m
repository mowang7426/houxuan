#import "KBGlowView.h"
#import <QuartzCore/QuartzCore.h>

@interface KBGlowView ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CAEmitterLayer *emitterLayer;
@property (nonatomic, assign) BOOL isAnimating;
@end

@implementation KBGlowView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;

        _glowColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        _glowSize = 60.0;
        _glowDuration = 0.6;
        _glowOpacity = 0.8;
        _animationType = KBGlowAnimationTypeRipple;
    }
    return self;
}

- (void)startAnimationAtPoint:(CGPoint)point {
    if (self.isAnimating) {
        [self stopAnimation];
    }
    self.isAnimating = YES;

    switch (self.animationType) {
        case KBGlowAnimationTypeRipple:
            [self animateRippleAtPoint:point];
            break;
        case KBGlowAnimationTypeGlow:
            [self animateGlowAtPoint:point];
            break;
        case KBGlowAnimationTypeParticle:
            [self animateParticleAtPoint:point];
            break;
    }
}

- (void)animateRippleAtPoint:(CGPoint)point {
    [self.gradientLayer removeFromSuperlayer];
    [self.emitterLayer removeFromSuperlayer];

    CGFloat size = MAX(24.0, self.glowSize * 2.0);
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = CGRectMake(0, 0, size, size);
    self.gradientLayer.position = point;
    self.gradientLayer.type = kCAGradientLayerRadial;
    UIColor *c = self.glowColor ?: [UIColor systemBlueColor];
    self.gradientLayer.colors = @[
        (__bridge id)[c colorWithAlphaComponent:self.glowOpacity * 0.95].CGColor,
        (__bridge id)[c colorWithAlphaComponent:self.glowOpacity * 0.30].CGColor,
        (__bridge id)[UIColor clearColor].CGColor
    ];
    self.gradientLayer.locations = @[@0.0, @0.28, @1.0];
    self.gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    self.gradientLayer.endPoint = CGPointMake(1.0, 1.0);
    [self.layer addSublayer:self.gradientLayer];

    // 真正的“涟漪”：从小圆快速扩张并逐渐消失，而不是只显示一团静态光。
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @0.10;
    scale.toValue = @1.35;
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.fromValue = @1.0;
    opacity.toValue = @0.0;
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scale, opacity];
    group.duration = MAX(0.20, self.glowDuration);
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    group.delegate = self;
    [self.gradientLayer addAnimation:group forKey:@"kbglow.ripple"];
}

- (void)animateGlowAtPoint:(CGPoint)point {
    [self.gradientLayer removeFromSuperlayer];
    [self.emitterLayer removeFromSuperlayer];

    CGFloat size = MAX(24.0, self.glowSize * 2.0);
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = CGRectMake(0, 0, size, size);
    self.gradientLayer.position = point;
    self.gradientLayer.type = kCAGradientLayerRadial;
    UIColor *c = self.glowColor ?: [UIColor systemBlueColor];
    self.gradientLayer.colors = @[
        (__bridge id)[c colorWithAlphaComponent:self.glowOpacity].CGColor,
        (__bridge id)[c colorWithAlphaComponent:self.glowOpacity * 0.42].CGColor,
        (__bridge id)[UIColor clearColor].CGColor
    ];
    self.gradientLayer.locations = @[@0.0, @0.42, @1.0];
    self.gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    self.gradientLayer.endPoint = CGPointMake(1.0, 1.0);
    [self.layer addSublayer:self.gradientLayer];

    // “常驻光晕”做成呼吸脉冲，避免看起来和普通颜色高亮完全一样。
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.fromValue = @0.18;
    opacity.toValue = @1.0;
    opacity.duration = MAX(0.18, self.glowDuration * 0.45);
    opacity.autoreverses = YES;
    opacity.repeatCount = 2.0;
    opacity.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @0.78;
    scale.toValue = @1.08;
    scale.duration = MAX(0.18, self.glowDuration * 0.45);
    scale.autoreverses = YES;
    scale.repeatCount = 2.0;
    scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[opacity, scale];
    group.duration = MAX(0.45, self.glowDuration * 1.8);
    group.delegate = self;
    [self.gradientLayer addAnimation:group forKey:@"kbglow.breathe"];
}

- (void)animateParticleAtPoint:(CGPoint)point {
    [self.gradientLayer removeFromSuperlayer];
    [self.emitterLayer removeFromSuperlayer];

    self.emitterLayer = [CAEmitterLayer layer];
    self.emitterLayer.frame = self.bounds;
    self.emitterLayer.emitterPosition = point;
    self.emitterLayer.emitterSize = CGSizeMake(2, 2);
    self.emitterLayer.emitterShape = kCAEmitterLayerPoint;
    self.emitterLayer.renderMode = kCAEmitterLayerAdditive;
    self.emitterLayer.birthRate = 1.0;

    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.birthRate = 55.0;
    cell.lifetime = MAX(0.25, self.glowDuration * 0.75);
    cell.lifetimeRange = cell.lifetime * 0.25;
    cell.velocity = MAX(40.0, self.glowSize * 1.8);
    cell.velocityRange = MAX(20.0, self.glowSize * 0.8);
    cell.emissionRange = (CGFloat)M_PI * 2.0;
    cell.spin = 1.5;
    cell.spinRange = 3.0;
    cell.scale = 0.11;
    cell.scaleRange = 0.06;
    cell.alphaSpeed = -1.8;
    cell.color = (self.glowColor ?: [UIColor systemBlueColor]).CGColor;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 18), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(5, 5, 8, 8));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.contents = (__bridge id)image.CGImage;

    self.emitterLayer.emitterCells = @[cell];
    [self.layer addSublayer:self.emitterLayer];

    // 一次性爆发，然后让粒子自然消散。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.06 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.emitterLayer) self.emitterLayer.birthRate = 0.0;
    });

    CAKeyframeAnimation *burst = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    burst.values = @[@1.0, @1.0, @0.0];
    burst.keyTimes = @[@0.0, @0.12, @1.0];
    burst.duration = MAX(0.35, self.glowDuration);
    burst.delegate = self;
    [self.emitterLayer addAnimation:burst forKey:@"kbglow.particleEnd"];
}

- (void)stopAnimation {
    self.isAnimating = NO;
    [self.gradientLayer removeAllAnimations];
    [self.emitterLayer removeAllAnimations];
    [self.gradientLayer removeFromSuperlayer];
    [self.emitterLayer removeFromSuperlayer];
    self.gradientLayer = nil;
    self.emitterLayer = nil;
    [self removeFromSuperview];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (!flag) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isAnimating) [self stopAnimation];
    });
}

@end
