#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSInteger, KBGlowAnimationType) {
    KBGlowAnimationTypeRipple = 0,    // 涟漪扩散
    KBGlowAnimationTypeGlow = 1,      // 常驻光晕
    KBGlowAnimationTypeParticle = 2,  // 粒子爆发
};

@interface KBGlowView : UIView <CAAnimationDelegate>

@property (nonatomic, strong) UIColor *glowColor;
@property (nonatomic, assign) CGFloat glowSize;         // 发光半径
@property (nonatomic, assign) CGFloat glowDuration;     // 动画时长
@property (nonatomic, assign) CGFloat glowOpacity;      // 最大不透明度
@property (nonatomic, assign) KBGlowAnimationType animationType;

- (void)startAnimationAtPoint:(CGPoint)point;
- (void)stopAnimation;
- (void)updateAnimationPoint:(CGPoint)point;
- (void)finishAnimation;

@end
