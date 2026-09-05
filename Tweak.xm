#import <UIKit/UIKit.h>
#import "KBGlowManager.h"

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
        [bid containsString:@"sohu.inputmethod"]) {
        return YES;
    }

    if ([proc containsString:@"wetype"] ||
        [proc containsString:@"wechatinput"] ||
        [proc containsString:@"wcinput"] ||
        [proc containsString:@"baidu"] ||
        [proc containsString:@"sogou"]) {
        return YES;
    }

    return NO;
}

%hook UIWindow

- (void)sendEvent:(UIEvent *)event {
    %orig;

    if (event.type != UIEventTypeTouches || !KBGlowSupportedProcess()) {
        return;
    }

    KBGlowManager *manager = [KBGlowManager sharedManager];
    if (!manager.enabled || ![manager isCurrentKeyboardEnabled]) {
        return;
    }

    for (UITouch *touch in event.allTouches) {
        UIWindow *window = touch.window ?: self;
        [manager handleTouch:touch inWindow:window];
    }
}

%end

%ctor {
    @autoreleasepool {
        [KBGlowManager sharedManager];
    }
}
