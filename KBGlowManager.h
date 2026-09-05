#import <UIKit/UIKit.h>
#import "KBGlowView.h"

@interface KBGlowManager : NSObject
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) KBGlowAnimationType animationType;
@property (nonatomic, strong) UIColor *glowColor;
@property (nonatomic, assign) CGFloat glowSize;
@property (nonatomic, assign) CGFloat glowDuration;
@property (nonatomic, assign) CGFloat glowOpacity;
@property (nonatomic, assign) BOOL followFinger;
@property (nonatomic, assign) BOOL wechatEnabled;
@property (nonatomic, assign) BOOL baiduEnabled;
@property (nonatomic, assign) BOOL sogouEnabled;
+ (instancetype)sharedManager;
- (void)reloadSettings;
- (void)notifySettingsChanged;
- (void)triggerGlowInView:(UIView *)view atPoint:(CGPoint)point;
- (BOOL)isCurrentKeyboardEnabled;
- (BOOL)isKeyView:(UIView *)view;
- (UIView *)findKeyViewFromView:(UIView *)view;
- (void)handleGlowGesture:(UIGestureRecognizer *)gesture;
@end
