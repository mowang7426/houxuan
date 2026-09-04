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

    // 动画类型 - 从独立开关读取
    if ([defaults boolForKey:@"animParticle"]) {
        self.animationType = KBGlowAnimationTypeParticle;
    } else if ([defaults boolForKey:@"animGlow"]) {
        self.animationType = KBGlowAnimationTypeGlow;
    } else {
        self.animationType = KBGlowAnimationTypeRipple;
    }

    self.glowSize = [defaults doubleForKey:@"glowSize"] ?: 60.0;
    self.glowDuration = [defaults doubleForKey:@"glowDuration"] ?: 0.6;
    self.glowOpacity = [defaults doubleForKey:@"glowOpacity"] ?: 0.8;
    self.followFinger = [defaults boolForKey:@"followFinger"] ?: YES;
    self.wechatEnabled = [defaults boolForKey:@"wechatEnabled"] ?: YES;
    self.baiduEnabled = [defaults boolForKey:@"baiduEnabled"] ?: YES;
    self.sogouEnabled = [defaults boolForKey:@"sogouEnabled"] ?: YES;

    // 颜色 - 从独立开关读取
    if ([defaults boolForKey:@"colorWhite"]) {
        self.glowColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
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
    for (NSInteger i = 0; i < 4 && current; i++) {
        NSString *className = NSStringFromClass([current class]);
        NSString *lower = [className lowercaseString];
        if ([lower containsString:@"textfield"] ||
            [lower containsString:@"textview"] ||
            [lower containsString:@"scrollview"] ||
            [lower containsString:@"tableview"] ||
            [lower containsString:@"collectionview"]) {
            return NO;
        }
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
    return view;
}

- (void)triggerGlowInView:(UIView *)view atPoint:(CGPoint)point {
    if (!self.enabled || !view) return;
    if (![self isCurrentKeyboardEnabled]) return;
    UIView *keyView = [self findKeyViewFromView:view];
    UIView *container = keyView.superview ?: keyView;
    CGPoint convertedPoint = [keyView convertPoint:point toView:container];
    if (!self.followFinger) {
        convertedPoint = CGPointMake(CGRectGetMidX(keyView.frame), CGRectGetMidY(keyView.frame));
    }
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
