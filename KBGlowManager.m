#import "KBGlowManager.h"
#import "KBGlowSettings.h"
#import <objc/runtime.h>

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
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        (__bridge const void *)(self),
                                        kKBGlowDarwinNotification,
                                        NULL);
}

- (void)reloadSettings {
    self.enabled = [KBGlowSettings boolForKey:@"enabled" default:YES];

    if ([KBGlowSettings boolForKey:@"animParticle" default:NO]) {
        self.animationType = KBGlowAnimationTypeParticle;
    } else if ([KBGlowSettings boolForKey:@"animGlow" default:NO]) {
        self.animationType = KBGlowAnimationTypeGlow;
    } else {
        self.animationType = KBGlowAnimationTypeRipple;
    }

    self.glowSize = [KBGlowSettings doubleForKey:@"glowSize" default:60.0];
    self.glowDuration = [KBGlowSettings doubleForKey:@"glowDuration" default:0.6];
    self.glowOpacity = [KBGlowSettings doubleForKey:@"glowOpacity" default:0.8];
    self.followFinger = [KBGlowSettings boolForKey:@"followFinger" default:YES];
    self.wechatEnabled = [KBGlowSettings boolForKey:@"wechatEnabled" default:YES];
    self.baiduEnabled = [KBGlowSettings boolForKey:@"baiduEnabled" default:YES];
    self.sogouEnabled = [KBGlowSettings boolForKey:@"sogouEnabled" default:YES];

    NSArray *custom = [KBGlowSettings objectForKey:@"customColor"];
    if ([custom isKindOfClass:[NSArray class]] && custom.count >= 3) {
        self.glowColor = [UIColor colorWithRed:[custom[0] doubleValue]
                                         green:[custom[1] doubleValue]
                                          blue:[custom[2] doubleValue]
                                         alpha:(custom.count >= 4 ? [custom[3] doubleValue] : 1.0)];
    } else if ([KBGlowSettings boolForKey:@"colorGreen" default:NO]) {
        self.glowColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    } else if ([KBGlowSettings boolForKey:@"colorWhite" default:NO]) {
        self.glowColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    } else if ([KBGlowSettings boolForKey:@"colorPink" default:NO]) {
        self.glowColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.7 alpha:1.0];
    } else if ([KBGlowSettings boolForKey:@"colorCyan" default:NO]) {
        self.glowColor = [UIColor colorWithRed:0.0 green:0.9 blue:1.0 alpha:1.0];
    } else if ([KBGlowSettings boolForKey:@"colorOrange" default:NO]) {
        self.glowColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0];
    } else if ([KBGlowSettings boolForKey:@"colorPurple" default:NO]) {
        self.glowColor = [UIColor colorWithRed:0.6 green:0.2 blue:1.0 alpha:1.0];
    } else if ([KBGlowSettings boolForKey:@"colorRed" default:NO]) {
        self.glowColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0];
    } else if ([KBGlowSettings boolForKey:@"colorBlue" default:NO]) {
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
    if ([lower containsString:@"wechat"] || [lower containsString:@"wcinput"] || [lower containsString:@"wetype"]) {
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
    [KBGlowSettings notifyChanged];
}

@end
