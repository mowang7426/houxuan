#import <UIKit/UIKit.h>
#import "KBGlowManager.h"

%hook UIWindow

- (void)sendEvent:(UIEvent *)event {
    %orig;
    @try {
        KBGlowManager *mgr = [KBGlowManager sharedManager];
        if (![mgr isCurrentKeyboardEnabled]) return;
        if (event.type != UIEventTypeTouches) return;
        for (UITouch *touch in [event allTouches]) {
            if (touch.phase != UITouchPhaseBegan) continue;
            UIView *view = touch.view;
            if (!view) continue;
            CGPoint point = [touch locationInView:view];
            [mgr triggerGlowInView:view atPoint:point];
        }
    } @catch (NSException *e) {
    }
}

%end
