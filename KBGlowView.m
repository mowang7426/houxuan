#import "KBGlowView.h"
#import <QuartzCore/QuartzCore.h>

@implementation KBGlowView {
    CAGradientLayer *_glowLayer;
    BOOL _finished;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = UIColor.clearColor;
        _glowSize = 55.0;
        _glowDuration = .45;
        _glowOpacity = .75;
        _animationType = KBGlowAnimationTypeRipple;
        _followFinger = YES;
    }
    return self;
}

- (void)startAnimationAtPoint:(CGPoint)p {
    [_glowLayer removeFromSuperlayer];

    CGFloat diameter = MAX(12, self.glowSize * 2.0);
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = CGRectMake(0, 0, diameter, diameter);
    g.position = p;
    g.type = kCAGradientLayerRadial;
    g.startPoint = CGPointMake(.5, .5);
    g.endPoint = CGPointMake(1, 1);
    g.cornerRadius = diameter / 2.0;

    UIColor *c = self.glowColor ?: UIColor.systemBlueColor;
    CGFloat a = MIN(1, MAX(.05, self.glowOpacity));

    g.colors = @[
        (id)[c colorWithAlphaComponent:a].CGColor,
        (id)[c colorWithAlphaComponent:a * .35].CGColor,
        (id)UIColor.clearColor.CGColor
    ];
    g.locations = @[@0, @.45, @1];

    [self.layer addSublayer:g];
    _glowLayer = g;
    _finished = NO;

    if (self.animationType == KBGlowAnimationTypeGlow) {
        g.opacity = a;

        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
        pulse.fromValue = @(a * .45);
        pulse.toValue = @(a);
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        pulse.duration = MAX(.12, self.glowDuration * .5);
        [g addAnimation:pulse forKey:@"pulse"];
    } else {
        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.fromValue = @.25;
        scale.toValue = (self.animationType == KBGlowAnimationTypeParticle) ? @1.15 : @1.65;

        CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fade.fromValue = @(a);
        fade.toValue = @0;

        CAAnimationGroup *grp = [CAAnimationGroup animation];
        grp.animations = @[scale, fade];
        grp.duration = MAX(.12, self.glowDuration);
        grp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        grp.delegate = self;

        [g addAnimation:grp forKey:@"glow"];
    }
}

- (void)updateAnimationAtPoint:(CGPoint)p {
    if (_finished || !_glowLayer) return;

    // 使用 presentation layer 以外的 model layer 位置，移动不会产生额外 UIView 布局开销。
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _glowLayer.position = p;
    [CATransaction commit];
}

- (void)finishAnimation {
    if (_finished) return;
    _finished = YES;

    if (!_glowLayer) {
        [self removeFromSuperview];
        return;
    }

    [_glowLayer removeAllAnimations];

    CGFloat currentOpacity = _glowLayer.opacity;
    if (currentOpacity <= 0.01) {
        [self removeFromSuperview];
        return;
    }

    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @(currentOpacity);
    fade.toValue = @0;
    fade.duration = MIN(.16, MAX(.06, self.glowDuration * .25));
    fade.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    fade.delegate = self;
    [_glowLayer addAnimation:fade forKey:@"finish"];
    _glowLayer.opacity = 0;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeFromSuperview];
    });
}

- (void)stopAnimation {
    _finished = YES;
    [_glowLayer removeAllAnimations];
    [_glowLayer removeFromSuperlayer];
    _glowLayer = nil;
    [self removeFromSuperview];
}

@end
