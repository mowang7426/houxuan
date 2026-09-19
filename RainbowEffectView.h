#import <UIKit/UIKit.h>

@interface RainbowEffectView : UIView
- (void)startAnimation;
- (void)stopAnimation;
- (void)reloadConfiguration;
- (void)showRippleAtPoint:(CGPoint)point;
@end
