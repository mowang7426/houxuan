#import "KBGlowManager.h"
#import <objc/runtime.h>

static NSString *const kKBGlowDomain = @"com.mowang.kbglow";

@implementation KBGlowManager

+ (instancetype)sharedManager {
    static KBGlowManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[KBGlowManager alloc] init];
        [instance reloadSettings];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 监听设置变化
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadSettings)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadSettings {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kKBGlowDomain];

    self.enabled = [defaults boolForKey:@"enabled"] ?: YES;
    self.animationType = [defaults integerForKey:@"animationType"] ?: KBGlowAnimationTypeRipple;
    self.glowSize = [defaults doubleForKey:@"glowSize"] ?: 60.0;
    self.glowDuration = [defaults doubleForKey:@"glowDuration"] ?: 0.6;
    self.glowOpacity = [defaults doubleForKey:@"glowOpacity"] ?: 0.8;
    self.followFinger = [defaults boolForKey:@"followFinger"] ?: YES;

    self.wechatEnabled = [defaults boolForKey:@"wechatEnabled"] ?: YES;
    self.baiduEnabled = [defaults boolForKey:@"baiduEnabled"] ?: YES;
    self.sogouEnabled = [defaults boolForKey:@"sogouEnabled"] ?: YES;

    // 颜色
    NSArray *colorComponents = [defaults arrayForKey:@"glowColor"];
    if (colorComponents && colorComponents.count >= 3) {
        CGFloat r = [colorComponents[0] floatValue];
        CGFloat g = [colorComponents[1] floatValue];
        CGFloat b = [colorComponents[2] floatValue];
        CGFloat a = colorComponents.count >= 4 ? [colorComponents[3] floatValue] : 1.0;
        self.glowColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
    } else {
        // 默认绿色
        self.glowColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    }
}

- (BOOL)isCurrentKeyboardEnabled {
    if (!self.enabled) return NO;

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (!bundleID) return NO;

    NSString *lower = [bundleID lowercaseString];

    if ([lower containsString:@"wechat"] || [lower containsString:@"wcinput"]) {
        return self.wechatEnabled;
    }
    if ([lower containsString:@"baidu"]) {
        return self.baiduEnabled;
    }
    if ([lower containsString:@"sogou"] || [lower containsString:@"sohu"]) {
        return self.sogouEnabled;
    }

    return NO;
}

- (BOOL)isKeyView:(UIView *)view {
    if (!view) return NO;

    // 向上遍历3层，检查类名是否包含按键关键词
    UIView *current = view;
    for (NSInteger i = 0; i < 4 && current; i++) {
        NSString *className = NSStringFromClass([current class]);
        NSString *lower = [className lowercaseString];

        // 排除明显不是按键的类
        if ([lower containsString:@"textfield"] ||
            [lower containsString:@"textview"] ||
            [lower containsString:@"scrollview"] ||
            [lower containsString:@"tableview"] ||
            [lower containsString:@"collectionview"]) {
            return NO;
        }

        // 匹配按键类名
        if ([lower containsString:@"key"] ||
            [lower containsString:@"button"] ||
            [lower containsString:@"keyview"] ||
            [lower containsString:@"keyplane"] ||
            [lower containsString:@"keyboardkey"]) {
            return YES;
        }

        current = current.superview;
    }

    return NO;
}

- (UIView *)findKeyViewFromView:(UIView *)view {
    UIView *current = view;
    for (NSInteger i = 0; i < 4 && current; i++) {
        NSString *className = NSStringFromClass([current class]);
        NSString *lower = [className lowercaseString];
        if ([lower containsString:@"key"] ||
            [lower containsString:@"button"] ||
            [lower containsString:@"keyview"] ||
            [lower containsString:@"keyplane"]) {
            return current;
        }
        current = current.superview;
    }
    return view; // 找不到就用原 view
}

- (void)triggerGlowInView:(UIView *)view atPoint:(CGPoint)point {
    if (!self.enabled || !view) return;
    if (![self isCurrentKeyboardEnabled]) return;

    UIView *keyView = [self findKeyViewFromView:view];
    UIView *container = keyView.superview ?: keyView;

    // 转换坐标到 container
    CGPoint convertedPoint = [keyView convertPoint:point toView:container];
    if (!self.followFinger) {
        // 不跟随手指时，用按键中心
        convertedPoint = CGPointMake(CGRectGetMidX(keyView.frame), CGRectGetMidY(keyView.frame));
    }

    // 创建发光视图
    KBGlowView *glowView = [[KBGlowView alloc] initWithFrame:container.bounds];
    glowView.glowColor = self.glowColor;
    glowView.glowSize = self.glowSize;
    glowView.glowDuration = self.glowDuration;
    glowView.glowOpacity = self.glowOpacity;
    glowView.animationType = self.animationType;
    glowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [container addSubview:glowView];
    [glowView startAnimationAtPoint:convertedPoint];
}

@end
