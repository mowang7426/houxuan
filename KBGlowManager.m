#import "KBGlowManager.h"
#import <objc/runtime.h>

static NSString *const kKBGlowDomain = @"com.mowang.kbglow";
static CFStringRef const kKBGlowDarwinNotification = CFSTR("com.mowang.kbglow.settingsChanged");

static id KBGlowCopyPreference(NSString *key) {
    return (__bridge_transfer id)CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR("com.mowang.kbglow"));
}

static BOOL KBGlowBoolPreference(NSString *key, BOOL fallback) {
    id value = KBGlowCopyPreference(key);
    return value ? [value boolValue] : fallback;
}

static double KBGlowDoublePreference(NSString *key, double fallback) {
    id value = KBGlowCopyPreference(key);
    return value ? [value doubleValue] : fallback;
}

static void KBGlowDarwinSettingsChanged(CFNotificationCenterRef center,
                                       void *observer,
                                       CFStringRef name,
                                       const void *object,
                                       CFDictionaryRef userInfo) {
    KBGlowManager *mgr = (__bridge KBGlowManager *)observer;
    dispatch_async(dispatch_get_main_queue(), ^{
        [mgr reloadSettings];
    });
}

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadSettings)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge const void *)(self),
                                         KBGlowDarwinSettingsChanged,
                                         kKBGlowDarwinNotification,
                                         NULL,
                                         CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        (__bridge const void *)(self),
                                        kKBGlowDarwinNotification,
                                        NULL);
}

- (void)reloadSettings {
    // 使用 CFPreferences 直接读取 app domain，确保设置面板进程和键盘扩展进程共享同一份配置。
    self.enabled = KBGlowBoolPreference(@"enabled", YES);

    // 保持 v1.0.3 原有动画选择逻辑，只修复跨进程读取。
    if (KBGlowBoolPreference(@"animParticle", NO)) {
        self.animationType = KBGlowAnimationTypeParticle;
    } else if (KBGlowBoolPreference(@"animGlow", NO)) {
        self.animationType = KBGlowAnimationTypeGlow;
    } else {
        self.animationType = KBGlowAnimationTypeRipple;
    }

    self.glowSize = KBGlowDoublePreference(@"glowSize", 60.0);
    self.glowDuration = KBGlowDoublePreference(@"glowDuration", 0.6);
    self.glowOpacity = KBGlowDoublePreference(@"glowOpacity", 0.8);
    self.followFinger = KBGlowBoolPreference(@"followFinger", YES);
    self.wechatEnabled = KBGlowBoolPreference(@"wechatEnabled", YES);
    self.baiduEnabled = KBGlowBoolPreference(@"baiduEnabled", YES);
    self.sogouEnabled = KBGlowBoolPreference(@"sogouEnabled", YES);

    NSArray *custom = KBGlowCopyPreference(@"customColor");
    if ([custom isKindOfClass:[NSArray class]] && custom.count >= 3) {
        self.glowColor = [UIColor colorWithRed:[custom[0] doubleValue]
                                         green:[custom[1] doubleValue]
                                          blue:[custom[2] doubleValue]
                                         alpha:(custom.count >= 4 ? [custom[3] doubleValue] : 1.0)];
    } else if (KBGlowBoolPreference(@"colorGreen", YES)) {
        self.glowColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    } else if (KBGlowBoolPreference(@"colorWhite", NO)) {
        self.glowColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    } else if (KBGlowBoolPreference(@"colorPink", NO)) {
        self.glowColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.7 alpha:1.0];
    } else if (KBGlowBoolPreference(@"colorCyan", NO)) {
        self.glowColor = [UIColor colorWithRed:0.0 green:0.9 blue:1.0 alpha:1.0];
    } else if (KBGlowBoolPreference(@"colorOrange", NO)) {
        self.glowColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0];
    } else if (KBGlowBoolPreference(@"colorPurple", NO)) {
        self.glowColor = [UIColor colorWithRed:0.6 green:0.2 blue:1.0 alpha:1.0];
    } else if (KBGlowBoolPreference(@"colorRed", NO)) {
        self.glowColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0];
    } else if (KBGlowBoolPreference(@"colorBlue", NO)) {
        self.glowColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    } else {
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
    UIView *current = view;
    for (NSInteger i = 0; i < 10 && current; i++) {
        NSString *lower = [NSStringFromClass(current.class) lowercaseString];
        if ([lower containsString:@"key"] ||
            [lower containsString:@"button"] ||
            [lower containsString:@"keyboardkey"] ||
            [lower containsString:@"keyplane"]) {
            return YES;
        }
        if ([current isKindOfClass:[UIControl class]]) {
            return YES;
        }
        current = current.superview;
    }
    return NO;
}

- (UIView *)findKeyViewFromView:(UIView *)view {
    UIView *current = view;
    UIView *control = nil;
    for (NSInteger i = 0; i < 10 && current; i++) {
        NSString *lower = [NSStringFromClass(current.class) lowercaseString];
        if ([lower containsString:@"keyboardkey"] ||
            [lower containsString:@"keyview"] ||
            [lower containsString:@"keyplane"] ||
            [lower containsString:@"button"] ||
            [lower containsString:@"key"]) {
            return current;
        }
        if (!control && [current isKindOfClass:[UIControl class]]) {
            control = current;
        }
        current = current.superview;
    }
    return control ?: view;
}

- (void)triggerGlowInView:(UIView *)view atPoint:(CGPoint)point {
    if (!self.enabled || !view || ![self isCurrentKeyboardEnabled]) return;

    UIView *keyView = [self findKeyViewFromView:view];
    if (!keyView) keyView = view;
    UIView *container = keyView.superview ?: keyView;
    if (!container) return;

    CGPoint convertedPoint;
    if (self.followFinger) {
        convertedPoint = [view convertPoint:point toView:container];
    } else {
        convertedPoint = [keyView convertPoint:CGPointMake(CGRectGetMidX(keyView.bounds), CGRectGetMidY(keyView.bounds))
                                       toView:container];
    }

    KBGlowView *glowView = [[KBGlowView alloc] initWithFrame:container.bounds];
    glowView.glowColor = self.glowColor ?: [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    glowView.glowSize = self.glowSize;
    glowView.glowDuration = self.glowDuration;
    glowView.glowOpacity = self.glowOpacity;
    glowView.animationType = self.animationType;
    glowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [container addSubview:glowView];
    [glowView startAnimationAtPoint:convertedPoint];
}

- (void)notifySettingsChanged {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                          kKBGlowDarwinNotification,
                                          NULL,
                                          NULL,
                                          true);
}

@end
