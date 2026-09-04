#import "KBGlowManager.h"
#import <objc/runtime.h>

static NSString *const kKBGlowDomain = @"com.mowang.kbglow";
static CFStringRef const kKBGlowDarwinNotification = CFSTR("com.mowang.kbglow.settingsChanged");

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
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kKBGlowDomain];

    self.enabled = [defaults objectForKey:@"enabled"] ? [defaults boolForKey:@"enabled"] : YES;

    // 动画：设置页始终保证只有一个模式有效。
    if ([defaults boolForKey:@"animParticle"]) {
        self.animationType = KBGlowAnimationTypeParticle;
    } else if ([defaults boolForKey:@"animGlow"]) {
        self.animationType = KBGlowAnimationTypeGlow;
    } else {
        self.animationType = KBGlowAnimationTypeRipple;
    }

    self.glowSize = [defaults objectForKey:@"glowSize"] ? [defaults doubleForKey:@"glowSize"] : 60.0;
    self.glowDuration = [defaults objectForKey:@"glowDuration"] ? [defaults doubleForKey:@"glowDuration"] : 0.6;
    self.glowOpacity = [defaults objectForKey:@"glowOpacity"] ? [defaults doubleForKey:@"glowOpacity"] : 0.8;
    self.followFinger = [defaults objectForKey:@"followFinger"] ? [defaults boolForKey:@"followFinger"] : YES;
    self.wechatEnabled = [defaults objectForKey:@"wechatEnabled"] ? [defaults boolForKey:@"wechatEnabled"] : YES;
    self.baiduEnabled = [defaults objectForKey:@"baiduEnabled"] ? [defaults boolForKey:@"baiduEnabled"] : YES;
    self.sogouEnabled = [defaults objectForKey:@"sogouEnabled"] ? [defaults boolForKey:@"sogouEnabled"] : YES;

    NSArray *custom = [defaults objectForKey:@"customColor"];
    if ([custom isKindOfClass:[NSArray class]] && custom.count >= 3) {
        self.glowColor = [UIColor colorWithRed:[custom[0] doubleValue]
                                         green:[custom[1] doubleValue]
                                          blue:[custom[2] doubleValue]
                                         alpha:(custom.count >= 4 ? [custom[3] doubleValue] : 1.0)];
    } else if ([defaults boolForKey:@"colorWhite"]) {
        self.glowColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    } else if ([defaults boolForKey:@"colorPink"]) {
        self.glowColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.7 alpha:1.0];
    } else if ([defaults boolForKey:@"colorCyan"]) {
        self.glowColor = [UIColor colorWithRed:0.0 green:0.9 blue:1.0 alpha:1.0];
    } else if ([defaults boolForKey:@"colorOrange"]) {
        self.glowColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0];
    } else if ([defaults boolForKey:@"colorPurple"]) {
        self.glowColor = [UIColor colorWithRed:0.6 green:0.2 blue:1.0 alpha:1.0];
    } else if ([defaults boolForKey:@"colorRed"]) {
        self.glowColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0];
    } else if ([defaults boolForKey:@"colorBlue"]) {
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
