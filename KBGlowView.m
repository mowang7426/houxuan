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

    CGFloat size = self.glowSize * 2;
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = CGRectMake(0, 0, size, size);
    self.gradientLayer.position = point;
    self.gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    self.gradientLayer.endPoint = CGPointMake(1.0, 1.0);
    self.gradientLayer.type = kCAGradientLayerRadial;

    UIColor *color = self.glowColor;
    self.gradientLayer.colors = @[
        (__bridge id)[color colorWithAlphaComponent:self.glowOpacity].CGColor,
        (__bridge id)[color colorWithAlphaComponent:self.glowOpacity * 0.4].CGColor,
        (__bridge id)[UIColor clearColor].CGColor
    ];
    self.gradientLayer.locations = @[@0.0, @0.5, @1.0];
    self.gradientLayer.cornerRadius = size / 2;
    self.gradientLayer.masksToBounds = YES;

    [self.layer addSublayer:self.gradientLayer];

    // 缩放 + 透明度动画
    CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnim.fromValue = @(0.2);
    scaleAnim.toValue = @(1.5);
    scaleAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnim.fromValue = @(1.0);
    opacityAnim.toValue = @(0.0);
    opacityAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scaleAnim, opacityAnim];
    group.duration = self.glowDuration;
    group.delegate = self;
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;

    [self.gradientLayer addAnimation:group forKey:@"ripple"];
}

- (void)animateGlowAtPoint:(CGPoint)point {
    [self.gradientLayer removeFromSuperlayer];

    CGFloat size = self.glowSize * 2;
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = CGRectMake(0, 0, size, size);
    self.gradientLayer.position = point;
    self.gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    self.gradientLayer.endPoint = CGPointMake(1.0, 1.0);
    self.gradientLayer.type = kCAGradientLayerRadial;

    UIColor *color = self.glowColor;
    self.gradientLayer.colors = @[
        (__bridge id)[color colorWithAlphaComponent:self.glowOpacity].CGColor,
        (__bridge id)[color colorWithAlphaComponent:self.glowOpacity * 0.3].CGColor,
        (__bridge id)[UIColor clearColor].CGColor
    ];
    self.gradientLayer.locations = @[@0.0, @0.6, @1.0];
    self.gradientLayer.cornerRadius = size / 2;
    self.gradientLayer.masksToBounds = YES;
    self.gradientLayer.opacity = 0;

    [self.layer addSublayer:self.gradientLayer];

    // 淡入
    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.fromValue = @(0);
    fadeIn.toValue = @(1.0);
    fadeIn.duration = 0.1;
    fadeIn.removedOnCompletion = NO;
    fadeIn.fillMode = kCAFillModeForwards;
    [self.gradientLayer addAnimation:fadeIn forKey:@"fadeIn"];
}

- (void)animateParticleAtPoint:(CGPoint)point {
    [self.emitterLayer removeFromSuperlayer];

    self.emitterLayer = [CAEmitterLayer layer];
    self.emitterLayer.emitterPosition = point;
    self.emitterLayer.emitterSize = CGSizeMake(self.glowSize * 0.3, self.glowSize * 0.3);
    self.emitterLayer.emitterShape = kCAEmitterLayerCircle;
    self.emitterLayer.renderMode = kCAEmitterLayerAdditive;
    self.emitterLayer.birthRate = 1;

    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.birthRate = 80;
    cell.lifetime = self.glowDuration;
    cell.lifetimeRange = self.glowDuration * 0.3;
    cell.velocity = self.glowSize * 2;
    cell.velocityRange = self.glowSize;
    cell.emissionRange = M_PI * 2;
    cell.spin = 2.0;
    cell.spinRange = 2.0;
    cell.scale = 0.15;
    cell.scaleRange = 0.1;
    cell.alphaSpeed = -2.5;
    cell.color = self.glowColor.CGColor;

    // 用一个小的渐变圆作为粒子内容
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = {0.0, 1.0};
    NSArray *colors = @[(__bridge id)[UIColor whiteColor].CGColor, (__bridge id)[UIColor clearColor].CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    CGContextDrawRadialGradient(ctx, gradient, CGPointMake(10, 10), 0, CGPointMake(10, 10), 10, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIImage *particleImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cell.contents = (__bridge id)particleImage.CGImage;

    self.emitterLayer.emitterCells = @[cell];
    [self.layer addSublayer:self.emitterLayer];

    // 触发一次粒子爆发
    CABasicAnimation *birthAnim = [CABasicAnimation animationWithKeyPath:@"birthRate"];
    birthAnim.fromValue = @(1.0);
    birthAnim.toValue = @(0);
    birthAnim.duration = 0.1;
    birthAnim.removedOnCompletion = NO;
    birthAnim.fillMode = kCAFillModeForwards;
    birthAnim.delegate = self;
    [self.emitterLayer addAnimation:birthAnim forKey:@"burst"];
}

- (void)stopAnimation {
    self.isAnimating = NO;

    if (self.animationType == KBGlowAnimationTypeGlow && self.gradientLayer) {
        // 淡出
        CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeOut.fromValue = @(1.0);
        fadeOut.toValue = @(0);
        fadeOut.duration = 0.2;
        fadeOut.removedOnCompletion = NO;
        fadeOut.fillMode = kCAFillModeForwards;
        [self.gradientLayer addAnimation:fadeOut forKey:@"fadeOut"];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.gradientLayer removeFromSuperlayer];
            self.gradientLayer = nil;
            [self removeFromSuperview];
        });
    } else {
        [self.gradientLayer removeFromSuperlayer];
        [self.emitterLayer removeFromSuperlayer];
        self.gradientLayer = nil;
        self.emitterLayer = nil;
        [self removeFromSuperview];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (self.animationType != KBGlowAnimationTypeGlow) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopAnimation];
        });
    }
}

@end
