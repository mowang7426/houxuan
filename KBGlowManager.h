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

// 各键盘独立开关
@property (nonatomic, assign) BOOL wechatEnabled;
@property (nonatomic, assign) BOOL baiduEnabled;
@property (nonatomic, assign) BOOL sogouEnabled;

+ (instancetype)sharedManager;
- (void)reloadSettings;

// 在指定 view 的指定位置触发光效
- (void)triggerGlowInView:(UIView *)view atPoint:(CGPoint)point;

// 判断当前进程是否是支持的键盘且已启用
- (BOOL)isCurrentKeyboardEnabled;

// 判断 view 是否是按键视图
- (BOOL)isKeyView:(UIView *)view;

@end
