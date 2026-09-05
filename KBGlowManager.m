#import "KBGlowManager.h"

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

@implementation KBGlowManager {
    NSMapTable<UITouch *, KBGlowView *> *_activeGlows;
}

+ (instancetype)sharedManager {
    static KBGlowManager *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        m = [KBGlowManager new];
        [m reloadSettings];
    });
    return m;
}

- (instancetype)init {
    if ((self = [super init])) {
        _activeGlows = [NSMapTable weakToStrongObjectsMapTable];

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            KBGlowDarwinSettingsChanged,
            kKBGlowDarwinNotification,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

- (void)dealloc {
    CFNotificationCenterRemoveObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge const void *)(self),
        kKBGlowDarwinNotification,
        NULL
    );
}

- (NSUserDefaults *)settings {
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:kKBGlowDomain];
    return d;
}

- (void)reloadSettings {
    NSUserDefaults *d = [self settings];

    self.enabled = [d objectForKey:@"enabled"] ? [d boolForKey:@"enabled"] : YES;

    NSInteger type = [d objectForKey:@"animationType"] ? [d integerForKey:@"animationType"] : 0;
    if (type < 0 || type > 2) type = 0;
    self.animationType = (KBGlowAnimationType)type;

    self.glowSize = [d objectForKey:@"glowSize"] ? [d doubleForKey:@"glowSize"] : 55.0;
    self.glowDuration = [d objectForKey:@"glowDuration"] ? [d doubleForKey:@"glowDuration"] : 0.45;
    self.glowOpacity = [d objectForKey:@"glowOpacity"] ? [d doubleForKey:@"glowOpacity"] : 0.75;
    self.followFinger = [d objectForKey:@"followFinger"] ? [d boolForKey:@"followFinger"] : YES;

    self.wechatEnabled = [d objectForKey:@"wechatEnabled"] ? [d boolForKey:@"wechatEnabled"] : YES;
    self.baiduEnabled = [d objectForKey:@"baiduEnabled"] ? [d boolForKey:@"baiduEnabled"] : YES;
    self.sogouEnabled = [d objectForKey:@"sogouEnabled"] ? [d boolForKey:@"sogouEnabled"] : YES;

    NSArray *c = [d objectForKey:@"colorRGB"];
    if ([c isKindOfClass:NSArray.class] && c.count >= 3) {
        self.glowColor = [UIColor colorWithRed:MAX(0, MIN(1, [c[0] doubleValue]))
                                         green:MAX(0, MIN(1, [c[1] doubleValue]))
                                          blue:MAX(0, MIN(1, [c[2] doubleValue]))
                                         alpha:1];
    } else {
        self.glowColor = [UIColor colorWithRed:0 green:.55 blue:1 alpha:1];
    }
}

- (BOOL)isCurrentKeyboardEnabled {
    if (!self.enabled) return NO;

    NSString *b = [[[NSBundle mainBundle] bundleIdentifier] lowercaseString];
    NSString *p = [[[NSProcessInfo processInfo] processName] lowercaseString];

    if ([b containsString:@"wetype"] ||
        [b containsString:@"wechatinput"] ||
        [b containsString:@"wcinput"] ||
        [p containsString:@"wetype"] ||
        [p containsString:@"wechatinput"] ||
        [p containsString:@"wcinput"]) {
        return self.wechatEnabled;
    }

    if ([b containsString:@"baidu"] || [p containsString:@"baidu"]) {
        return self.baiduEnabled;
    }

    if ([b containsString:@"sogou"] ||
        [b containsString:@"sohu.inputmethod"] ||
        [p containsString:@"sogou"]) {
        return self.sogouEnabled;
    }

    return NO;
}

- (void)handleTouch:(UITouch *)touch inWindow:(UIWindow *)window {
    if (!touch || !window || !self.enabled || ![self isCurrentKeyboardEnabled]) return;

    UITouchPhase phase = touch.phase;

    if (phase == UITouchPhaseBegan) {
        CGPoint p = [touch locationInView:window];

        // 一个手指只维护一个光效，避免重复叠加导致发热和掉帧。
        KBGlowView *old = [_activeGlows objectForKey:touch];
        [old stopAnimation];

        KBGlowView *glow = [[KBGlowView alloc] initWithFrame:window.bounds];
        glow.glowColor = self.glowColor ?: [UIColor colorWithRed:0 green:.55 blue:1 alpha:1];
        glow.glowSize = MAX(12, self.glowSize);
        glow.glowDuration = MAX(.08, self.glowDuration);
        glow.glowOpacity = MIN(1, MAX(.05, self.glowOpacity));
        glow.animationType = self.animationType;
        glow.followFinger = self.followFinger;
        glow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [window addSubview:glow];
        [glow startAnimationAtPoint:p];

        [_activeGlows setObject:glow forKey:touch];
        return;
    }

    KBGlowView *glow = [_activeGlows objectForKey:touch];
    if (!glow) return;

    if ((phase == UITouchPhaseMoved ||
         phase == UITouchPhaseStationary) && self.followFinger) {
        [glow updateAnimationAtPoint:[touch locationInView:window]];
    }

    if (phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled) {
        [glow finishAnimation];
        [_activeGlows removeObjectForKey:touch];
    }
}

- (void)triggerGlowInView:(UIView *)view atPoint:(CGPoint)point {
    if (!view || !self.enabled) return;

    UIWindow *window = [view isKindOfClass:UIWindow.class] ? (UIWindow *)view : view.window;
    if (!window) return;

    KBGlowView *glow = [[KBGlowView alloc] initWithFrame:window.bounds];
    glow.glowColor = self.glowColor ?: [UIColor colorWithRed:0 green:.55 blue:1 alpha:1];
    glow.glowSize = MAX(12, self.glowSize);
    glow.glowDuration = MAX(.08, self.glowDuration);
    glow.glowOpacity = MIN(1, MAX(.05, self.glowOpacity));
    glow.animationType = self.animationType;
    glow.followFinger = self.followFinger;
    glow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [window addSubview:glow];
    [glow startAnimationAtPoint:point];
}

- (void)notifySettingsChanged {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        kKBGlowDarwinNotification,
        NULL,
        NULL,
        true
    );
}

- (BOOL)isKeyView:(UIView *)view {
    return [view isKindOfClass:UIControl.class];
}

- (UIView *)findKeyViewFromView:(UIView *)view {
    return view;
}

@end
