#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "KBGlowManager.h"
#import "KBGlowTouchRecognizer.h"

static const void *kKBGlowRecognizerKey = &kKBGlowRecognizerKey;

static BOOL KBGlowSupportedProcess(void) {
    NSString *bid = [[[NSBundle mainBundle] bundleIdentifier] lowercaseString];
    NSString *proc = [[[NSProcessInfo processInfo] processName] lowercaseString];
    if ([bid containsString:@"com.tencent.wetype.keyboard"] ||
        [bid containsString:@"com.tencent.wetype"] ||
        [bid containsString:@"wcinput"] ||
        [bid containsString:@"wechatinput"] ||
        [bid containsString:@"baidu.input"] ||
        [bid containsString:@"baidu.inputmethod"] ||
        [bid containsString:@"sogou"] ||
        [bid containsString:@"sohu.inputmethod"]) return YES;
    if ([proc containsString:@"wetype"] || [proc containsString:@"wechatinput"] ||
        [proc containsString:@"wcinput"] || [proc containsString:@"baidu"] ||
        [proc containsString:@"sogou"]) return YES;
    return NO;
}


static void KBGlowHandleTouch(UITouch *touch) {
    if (!touch || touch.phase != UITouchPhaseBegan) return;
    KBGlowManager *m = [KBGlowManager sharedManager];
    if (!m.enabled || !KBGlowSupportedProcess() || ![m isCurrentKeyboardEnabled]) return;
    UIView *view = touch.view;
    UIWindow *window = view.window;
    if (!view || !window) return;
    CGPoint p = [touch locationInView:window];
    [m triggerGlowInView:window atPoint:p];
}
static void KBGlowInstallRecognizer(UIView *inputView) {
    if (!inputView || objc_getAssociatedObject(inputView, kKBGlowRecognizerKey)) return;
    KBGlowTouchRecognizer *r = [[KBGlowTouchRecognizer alloc] initWithTarget:nil action:nil];
    r.cancelsTouchesInView = NO;
    r.delaysTouchesBegan = NO;
    r.delaysTouchesEnded = NO;
    [inputView addGestureRecognizer:r];
    objc_setAssociatedObject(inputView, kKBGlowRecognizerKey, r, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [r addTarget:[KBGlowManager sharedManager] action:@selector(handleGlowGesture:)];
}

%hook UIInputView
- (void)didMoveToWindow {
    %orig;
    if (self.window && KBGlowSupportedProcess()) KBGlowInstallRecognizer(self);
}
%end

%hook UIInputViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (KBGlowSupportedProcess() && self.view.window) KBGlowInstallRecognizer(self.view);
}
%end

%hook UIWindow
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (event.type != UIEventTypeTouches || !KBGlowSupportedProcess()) return;
    for (UITouch *touch in event.allTouches) KBGlowHandleTouch(touch);
}
%end

%ctor { @autoreleasepool { [KBGlowManager sharedManager]; } }
