#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "KBGlowManager.h"

static BOOL KBGlowSupportedProcess(void) {
    NSString *bid = [[[NSBundle mainBundle] bundleIdentifier] lowercaseString];
    NSString *proc = [[[NSProcessInfo processInfo] processName] lowercaseString];
    return ([bid containsString:@"wetype"] || [bid containsString:@"wechatinput"] || [bid containsString:@"wcinput"] ||
            [bid containsString:@"baidu.input"] || [bid containsString:@"baidu.inputmethod"] ||
            [bid containsString:@"sogou"] || [bid containsString:@"sohu.inputmethod"] ||
            [proc containsString:@"wetype"] || [proc containsString:@"wechatinput"] || [proc containsString:@"wcinput"] ||
            [proc containsString:@"baidu"] || [proc containsString:@"sogou"]);
}

%hook UIWindow
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (!event || event.type != UIEventTypeTouches || !KBGlowSupportedProcess()) return;
    KBGlowManager *m=[KBGlowManager sharedManager];
    if (!m.enabled || ![m isCurrentKeyboardEnabled]) return;
    NSSet<UITouch *> *touches=event.allTouches;
    for (UITouch *t in touches) {
        UIView *v=t.view; UIWindow *w=v.window;
        if (!v || !w) continue;
        CGPoint p=[t locationInView:w];
        switch (t.phase) {
            case UITouchPhaseBegan:
                [m beginTouch:t inWindow:w atPoint:p];
                break;
            case UITouchPhaseMoved:
            case UITouchPhaseStationary:
                [m moveTouch:t inWindow:w atPoint:p];
                break;
            case UITouchPhaseEnded:
            case UITouchPhaseCancelled:
                [m endTouch:t inWindow:w atPoint:p cancelled:(t.phase==UITouchPhaseCancelled)];
                break;
            default: break;
        }
    }
}
%end

%ctor { @autoreleasepool { [KBGlowManager sharedManager]; } }
