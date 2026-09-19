#import <UIKit/UIKit.h>
#import "KBGlowManager.h"

%hook UIWindow

- (void)sendEvent:(UIEvent *)event {
    %orig;

    if (event.type != UIEventTypeTouches) return;
    if (self.hidden || self.alpha <= 0.01) return;

    @try {
        KBGlowManager *mgr = [KBGlowManager sharedManager];
        if (![mgr isCurrentKeyboardEnabled]) return;

        for (UITouch *touch in event.allTouches) {
            if (touch.phase != UITouchPhaseBegan) continue;

            UIView *touchView = touch.view;
            if (!touchView || !touchView.window) continue;

            UIView *keyView = [mgr findKeyViewFromView:touchView];
            if (!keyView || ![mgr isKeyView:keyView]) continue;

            CGPoint point = [touch locationInView:keyView];
            [mgr triggerGlowInView:keyView atPoint:point];
        }
    } @catch (NSException *exception) {
        // 第三方键盘的视图层级经常动态变化，不能影响键盘主线程。
    }
}

%end

%ctor {
    NSLog(@"[KBGlow] loaded in %@", [[NSBundle mainBundle] bundleIdentifier]);
}
