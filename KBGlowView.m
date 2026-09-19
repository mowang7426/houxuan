#import "KBGlowView.h"
#import <QuartzCore/QuartzCore.h>

@interface KBGlowView ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CAEmitterLayer *emitterLayer;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) NSUInteger animationGeneration;
@end

@implementation KBGlowView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        _glowColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
        _glowSize = 60.0;
        _glowDuration = 0.6;
        _glowOpacity = 0.8;
        _animationType = KBGlowAnimationTypeRipple;
    }
    return self;
}

- (void)startAnimationAtPoint:(CGPoint)point {
    [self stopAnimationImmediately];
    self.isAnimating = YES;
    self.animationGeneration++;

    switch (self.animationType) {
        case KBGlowAnimationTypeGlow:
            [self animateGlowAtPoint:point];
            break;
        case KBGlowAnimationTypeParticle:
            [self animateParticleAtPoint:point];
            break;
        default:
            [self animateRippleAtPoint:point];
            break;
    }
}

- (CAGradientLayer *)gradientAtPoint:(CGPoint)point locations:(NSArray *)locations {
    CGFloat size = MAX(2.0, self.glowSize * 2.0);
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.frame = CGRectMake(0, 0, size, size);
    layer.position = point;
    layer.startPoint = CGPointMake(0.5, 0.5);
    layer.endPoint = CGPointMake(1.0, 1.0);
    layer.type = kCAGradientLayerRadial;
    UIColor *color = self.glowColor ?: UIColor.greenColor;
    layer.colors = @[
        (id)[color colorWithAlphaComponent:self.glowOpacity].CGColor,
        (id)[color colorWithAlphaComponent:self.glowOpacity * 0.35].CGColor,
        (id)UIColor.clearColor.CGColor
    ];
    layer.locations = locations;
    layer.cornerRadius = size / 2.0;
    layer.masksToBounds = YES;
    return layer;
}

- (void)animateRippleAtPoint:(CGPoint)point {
    self.gradientLayer = [self gradientAtPoint:point locations:@[@0.0, @0.5, @1.0]];
    [self.layer addSublayer:self.gradientLayer];

    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @0.2;
    scale.toValue = @1.5;
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.fromValue = @1.0;
    opacity.toValue = @0.0;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scale, opacity];
    group.duration = MAX(0.05, self.glowDuration);
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    group.delegate = self;
    [self.gradientLayer addAnimation:group forKey:@"kbglow.ripple"];
}

- (void)animateGlowAtPoint:(CGPoint)point {
    self.gradientLayer = [self gradientAtPoint:point locations:@[@0.0, @0.6, @1.0]];
    self.gradientLayer.opacity = 0.0;
    [self.layer addSublayer:self.gradientLayer];

    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.fromValue = @0.0;
    fadeIn.toValue = @1.0;
    fadeIn.duration = MIN(0.15, MAX(0.05, self.glowDuration * 0.25));
    [self.gradientLayer addAnimation:fadeIn forKey:@"kbglow.fadeIn"];

    NSUInteger generation = self.animationGeneration;
    NSTimeInterval duration = MAX(0.1, self.glowDuration);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.animationGeneration == generation && self.isAnimating) {
            [self stopAnimation];
        }
    });
}

- (void)animateParticleAtPoint:(CGPoint)point {
    self.emitterLayer = [CAEmitterLayer layer];
    self.emitterLayer.frame = self.bounds;
    self.emitterLayer.emitterPosition = point;
    self.emitterLayer.emitterSize = CGSizeMake(self.glowSize * 0.3, self.glowSize * 0.3);
    self.emitterLayer.emitterShape = kCAEmitterLayerCircle;
    self.emitterLayer.renderMode = kCAEmitterLayerAdditive;
    self.emitterLayer.birthRate = 1.0;

    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.birthRate = 80.0;
    cell.lifetime = MAX(0.1, self.glowDuration);
    cell.lifetimeRange = cell.lifetime * 0.25;
    cell.velocity = self.glowSize * 2.0;
    cell.velocityRange = self.glowSize;
    cell.emissionRange = M_PI * 2.0;
    cell.spin = 2.0;
    cell.spinRange = 2.0;
    cell.scale = 0.15;
    cell.scaleRange = 0.1;
    cell.alphaSpeed = -1.0 / cell.lifetime;
    cell.color = (self.glowColor ?: UIColor.greenColor).CGColor;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *color = self.glowColor ?: UIColor.greenColor;
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(2, 2, 16, 16));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.contents = (id)image.CGImage;

    self.emitterLayer.emitterCells = @[cell];
    [self.layer addSublayer:self.emitterLayer];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.emitterLayer.birthRate = 0.0;
    [CATransaction commit];

    CAKeyframeAnimation *burst = [CAKeyframeAnimation animationWithKeyPath:@"birthRate"];
    burst.values = @[@1.0, @1.0, @0.0];
    burst.keyTimes = @[@0.0, @0.05, @1.0];
    burst.duration = 0.1;
    [self.emitterLayer addAnimation:burst forKey:@"kbglow.burst"];

    NSUInteger generation = self.animationGeneration;
    NSTimeInterval duration = MAX(0.15, self.glowDuration * 1.4);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.animationGeneration == generation && self.isAnimating) {
            [self stopAnimation];
        }
    });
}

- (void)stopAnimationImmediately {
    self.animationGeneration++;
    self.isAnimating = NO;
    [self.gradientLayer removeAllAnimations];
    [self.emitterLayer removeAllAnimations];
    [self.gradientLayer removeFromSuperlayer];
    [self.emitterLayer removeFromSuperlayer];
    self.gradientLayer = nil;
    self.emitterLayer = nil;
}

- (void)stopAnimation {
    if (!self.isAnimating) return;
    self.isAnimating = NO;
    self.animationGeneration++;

    if (self.animationType == KBGlowAnimationTypeGlow && self.gradientLayer) {
        CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeOut.fromValue = @1.0;
        fadeOut.toValue = @0.0;
        fadeOut.duration = 0.15;
        [self.gradientLayer addAnimation:fadeOut forKey:@"kbglow.fadeOut"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.18 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopAnimationImmediately];
            [self removeFromSuperview];
        });
    } else {
        [self stopAnimationImmediately];
        [self removeFromSuperview];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished {
    if (finished && self.animationType == KBGlowAnimationTypeRipple) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopAnimation];
        });
    }
}

@end
