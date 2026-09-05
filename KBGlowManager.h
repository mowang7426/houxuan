#import <UIKit/UIKit.h>
#import "KBGlowView.h"
@interface KBGlowManager : NSObject
+ (instancetype)sharedManager;
@property(nonatomic,assign) BOOL enabled;
@property(nonatomic,assign) KBGlowAnimationType animationType;
@property(nonatomic,assign) CGFloat glowSize;
@property(nonatomic,assign) CGFloat glowDuration;
@property(nonatomic,assign) CGFloat glowOpacity;
@property(nonatomic,strong) UIColor *glowColor;
@property(nonatomic,assign) BOOL followFinger;
@property(nonatomic,assign) BOOL wechatEnabled;
@property(nonatomic,assign) BOOL baiduEnabled;
@property(nonatomic,assign) BOOL sogouEnabled;
- (void)reloadSettings;
- (BOOL)isCurrentKeyboardEnabled;
- (void)beginTouch:(UITouch *)touch inWindow:(UIWindow *)window atPoint:(CGPoint)point;
- (void)moveTouch:(UITouch *)touch inWindow:(UIWindow *)window atPoint:(CGPoint)point;
- (void)endTouch:(UITouch *)touch inWindow:(UIWindow *)window atPoint:(CGPoint)point cancelled:(BOOL)cancelled;
@end
