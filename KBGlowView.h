#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSInteger, KBGlowAnimationType) {
    KBGlowAnimationTypeRipple = 0,
    KBGlowAnimationTypeGlow = 1,
    KBGlowAnimationTypeParticle = 2,
};

@interface KBGlowView : UIView <CAAnimationDelegate>

@property (nonatomic, strong) UIColor *glowColor;
@property (nonatomic, assign) CGFloat glowSize;
@property (nonatomic, assign) CGFloat glowDuration;
@property (nonatomic, assign) CGFloat glowOpacity;
@property (nonatomic, assign) KBGlowAnimationType animationType;
@property (nonatomic, assign) BOOL followFinger;

- (void)startAnimationAtPoint:(CGPoint)point;
- (void)updateAnimationAtPoint:(CGPoint)point;
- (void)finishAnimation;
- (void)stopAnimation;

@end
