#import "KBGlowManager.h"
#import <objc/runtime.h>

static NSString *const kKBGlowDomain= @"com.mowang.kbglow";
static CFStringRef const kKBGlowDarwinNotification=CFSTR("com.mowang.kbglow.settingsChanged");
static const void *kTouchGlowKey=&kTouchGlowKey;

static void KBGlowSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
    KBGlowManager *m=(__bridge KBGlowManager *)observer;
    dispatch_async(dispatch_get_main_queue(), ^{ [m reloadSettings]; });
}

@implementation KBGlowManager
+ (instancetype)sharedManager { static KBGlowManager *m; static dispatch_once_t once; dispatch_once(&once, ^{ m=[KBGlowManager new]; [m reloadSettings]; }); return m; }
- (instancetype)init { if((self=[super init])) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),KBGlowSettingsChanged,kKBGlowDarwinNotification,NULL,CFNotificationSuspensionBehaviorDeliverImmediately); return self; }
- (void)dealloc { CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self),kKBGlowDarwinNotification,NULL); }
- (void)reloadSettings {
    NSUserDefaults *d=[[NSUserDefaults alloc] initWithSuiteName:kKBGlowDomain];
    [d synchronize];
    self.enabled=[d objectForKey:@"enabled"] ? [d boolForKey:@"enabled"] : YES;
    NSInteger t=[d objectForKey:@"animationType"] ? [d integerForKey:@"animationType"] : 0; if(t<0||t>2)t=0; self.animationType=(KBGlowAnimationType)t;
    self.glowSize=[d objectForKey:@"glowSize"]?[d doubleForKey:@"glowSize"]:55;
    self.glowDuration=[d objectForKey:@"glowDuration"]?[d doubleForKey:@"glowDuration"]:.45;
    self.glowOpacity=[d objectForKey:@"glowOpacity"]?[d doubleForKey:@"glowOpacity"]:.75;
    self.followFinger=[d objectForKey:@"followFinger"]?[d boolForKey:@"followFinger"]:YES;
    self.wechatEnabled=[d objectForKey:@"wechatEnabled"]?[d boolForKey:@"wechatEnabled"]:YES;
    self.baiduEnabled=[d objectForKey:@"baiduEnabled"]?[d boolForKey:@"baiduEnabled"]:YES;
    self.sogouEnabled=[d objectForKey:@"sogouEnabled"]?[d boolForKey:@"sogouEnabled"]:YES;
    NSArray *c=[d objectForKey:@"colorRGB"];
    if([c isKindOfClass:NSArray.class]&&c.count>=3) self.glowColor=[UIColor colorWithRed:MAX(0,MIN(1,[c[0] doubleValue])) green:MAX(0,MIN(1,[c[1] doubleValue])) blue:MAX(0,MIN(1,[c[2] doubleValue])) alpha:1];
    else self.glowColor=[UIColor colorWithRed:0 green:.55 blue:1 alpha:1];
}
- (BOOL)isCurrentKeyboardEnabled {
    NSString *b=[[[NSBundle mainBundle] bundleIdentifier] lowercaseString]; NSString *p=[[[NSProcessInfo processInfo] processName] lowercaseString];
    if([b containsString:@"wetype"]||[b containsString:@"wechatinput"]||[b containsString:@"wcinput"]||[p containsString:@"wetype"]||[p containsString:@"wechatinput"]||[p containsString:@"wcinput"]) return self.wechatEnabled;
    if([b containsString:@"baidu"]||[p containsString:@"baidu"]) return self.baiduEnabled;
    if([b containsString:@"sogou"]||[b containsString:@"sohu.inputmethod"]||[p containsString:@"sogou"]) return self.sogouEnabled;
    return NO;
}
- (void)beginTouch:(UITouch *)touch inWindow:(UIWindow *)window atPoint:(CGPoint)point {
    if(!touch||!window) return;
    KBGlowView *old=objc_getAssociatedObject(touch,kTouchGlowKey); if(old) [old stopAnimation];
    KBGlowView *g=[[KBGlowView alloc] initWithFrame:window.bounds];
    g.glowColor=self.glowColor; g.glowSize=MAX(12,self.glowSize); g.glowDuration=MAX(.08,self.glowDuration); g.glowOpacity=MIN(1,MAX(.05,self.glowOpacity)); g.animationType=self.animationType;
    g.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; [window addSubview:g];
    [g startTrackingAtPoint:point];
    objc_setAssociatedObject(touch,kTouchGlowKey,g,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)moveTouch:(UITouch *)touch inWindow:(UIWindow *)window atPoint:(CGPoint)point {
    KBGlowView *g=objc_getAssociatedObject(touch,kTouchGlowKey); if(!g) { if(self.followFinger) [self beginTouch:touch inWindow:window atPoint:point]; return; }
    if(self.followFinger) [g updateTrackingPoint:point];
}
- (void)endTouch:(UITouch *)touch inWindow:(UIWindow *)window atPoint:(CGPoint)point cancelled:(BOOL)cancelled {
    KBGlowView *g=objc_getAssociatedObject(touch,kTouchGlowKey); if(!g) return;
    [g finishTrackingAtPoint:point cancelled:cancelled]; objc_setAssociatedObject(touch,kTouchGlowKey,nil,OBJC_ASSOCIATION_ASSIGN);
}
@end
