#import "KBGlowManager.h"

static NSString *const kKBGlowDomain = @"com.mowang.kbglow";
static CFStringRef const kKBGlowDarwinNotification = CFSTR("com.mowang.kbglow.settingsChanged");

static void KBGlowDarwinSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    KBGlowManager *mgr = (__bridge KBGlowManager *)observer;
    dispatch_async(dispatch_get_main_queue(), ^{ [mgr reloadSettings]; });
}

@implementation KBGlowManager
+ (instancetype)sharedManager { static KBGlowManager *m; static dispatch_once_t once; dispatch_once(&once, ^{ m=[KBGlowManager new]; [m reloadSettings]; }); return m; }
- (instancetype)init {
    if ((self=[super init])) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), KBGlowDarwinSettingsChanged, kKBGlowDarwinNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    return self;
}
- (void)dealloc { CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), kKBGlowDarwinNotification, NULL); }
- (void)reloadSettings {
    NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:kKBGlowDomain];
    self.enabled = [d objectForKey:@"enabled"] ? [d boolForKey:@"enabled"] : YES;
    NSInteger type=[d objectForKey:@"animationType"] ? [d integerForKey:@"animationType"] : 0;
    if (type<0 || type>2) type=0; self.animationType=(KBGlowAnimationType)type;
    self.glowSize=[d objectForKey:@"glowSize"] ? [d doubleForKey:@"glowSize"] : 55.0;
    self.glowDuration=[d objectForKey:@"glowDuration"] ? [d doubleForKey:@"glowDuration"] : 0.45;
    self.glowOpacity=[d objectForKey:@"glowOpacity"] ? [d doubleForKey:@"glowOpacity"] : 0.75;
    self.followFinger=[d objectForKey:@"followFinger"] ? [d boolForKey:@"followFinger"] : YES;
    self.wechatEnabled=[d objectForKey:@"wechatEnabled"] ? [d boolForKey:@"wechatEnabled"] : YES;
    self.baiduEnabled=[d objectForKey:@"baiduEnabled"] ? [d boolForKey:@"baiduEnabled"] : YES;
    self.sogouEnabled=[d objectForKey:@"sogouEnabled"] ? [d boolForKey:@"sogouEnabled"] : YES;
    NSArray *c=[d objectForKey:@"colorRGB"];
    if ([c isKindOfClass:NSArray.class] && c.count>=3) self.glowColor=[UIColor colorWithRed:[c[0] doubleValue] green:[c[1] doubleValue] blue:[c[2] doubleValue] alpha:1];
    else self.glowColor=[UIColor colorWithRed:0 green:.55 blue:1 alpha:1];
}
- (BOOL)isCurrentKeyboardEnabled {
    if (!self.enabled) return NO;
    NSString *b=[[[NSBundle mainBundle] bundleIdentifier] lowercaseString];
    NSString *p=[[[NSProcessInfo processInfo] processName] lowercaseString];
    if ([b containsString:@"wetype"] || [b containsString:@"wechatinput"] || [b containsString:@"wcinput"] || [p containsString:@"wetype"] || [p containsString:@"wechatinput"] || [p containsString:@"wcinput"]) return self.wechatEnabled;
    if ([b containsString:@"baidu"] || [p containsString:@"baidu"]) return self.baiduEnabled;
    if ([b containsString:@"sogou"] || [b containsString:@"sohu.inputmethod"] || [p containsString:@"sogou"]) return self.sogouEnabled;
    return NO;
}
- (UIView *)findKeyViewFromView:(UIView *)view {
    UIView *v=view; UIView *control=nil;
    for (NSInteger i=0; v && i<16; i++, v=v.superview) {
        NSString *n=NSStringFromClass(v.class).lowercaseString;
        if ([n containsString:@"keyboardkey"] || [n containsString:@"keyview"] || [n containsString:@"keyplane"] || [n containsString:@"keybutton"] || [n containsString:@"imebutton"]) return v;
        if (!control && [v isKindOfClass:UIControl.class]) control=v;
    }
    return control ?: view;
}
- (void)handleGlowGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan || !self.enabled || ![self isCurrentKeyboardEnabled]) return;
    UIView *v=gesture.view; UIWindow *w=v.window; if (!v || !w) return;
    CGPoint p=[gesture locationInView:w];
    [self triggerGlowInView:w atPoint:p];
}
- (void)triggerGlowInView:(UIView *)view atPoint:(CGPoint)point {
    if (!view || !self.enabled) return;
    UIWindow *window = [view isKindOfClass:UIWindow.class] ? (UIWindow *)view : view.window;
    if (!window) return;
    KBGlowView *glow=[[KBGlowView alloc] initWithFrame:window.bounds];
    glow.glowColor=self.glowColor ?: [UIColor colorWithRed:0 green:.55 blue:1 alpha:1];
    glow.glowSize=MAX(12,self.glowSize); glow.glowDuration=MAX(.08,self.glowDuration); glow.glowOpacity=MIN(1,MAX(.05,self.glowOpacity)); glow.animationType=self.animationType;
    glow.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [window addSubview:glow]; [glow startAnimationAtPoint:point];
}
- (void)notifySettingsChanged { CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kKBGlowDarwinNotification, NULL, NULL, true); }
- (BOOL)isKeyView:(UIView *)view { return [self findKeyViewFromView:view] != view || [view isKindOfClass:UIControl.class]; }
@end
