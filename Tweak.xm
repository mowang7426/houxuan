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

            // 不再依赖第三方键盘私有类名。触摸事件已经来自
            // KBGlow.plist 过滤的键盘进程，交给管理器统一处理。
            UIView *keyView = [mgr findKeyViewFromView:touchView];
            if (!keyView) keyView = touchView;

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
