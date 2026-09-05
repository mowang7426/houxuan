#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, KBGlowAnimationType){ KBGlowAnimationTypeRipple=0, KBGlowAnimationTypeGlow=1, KBGlowAnimationTypeParticle=2 };
@interface KBGlowView:UIView <CAAnimationDelegate>
@property(nonatomic,strong)UIColor *glowColor;
@property(nonatomic,assign)CGFloat glowSize;
@property(nonatomic,assign)CGFloat glowDuration;
@property(nonatomic,assign)CGFloat glowOpacity;
@property(nonatomic,assign)KBGlowAnimationType animationType;
- (void)startTrackingAtPoint:(CGPoint)p;
- (void)updateTrackingPoint:(CGPoint)p;
- (void)finishTrackingAtPoint:(CGPoint)p cancelled:(BOOL)cancelled;
- (void)stopAnimation;
@end
