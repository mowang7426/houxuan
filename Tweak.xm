#import <UIKit/UIKit.h>
#import "KBGlowManager.h"

%hook UIWindow

- (void)sendEvent:(UIEvent *)event {
    %orig;

    @autoreleasepool {
        if (event.type != UIEventTypeTouches) return;
        KBGlowManager *mgr = [KBGlowManager sharedManager];
        if (![mgr isCurrentKeyboardEnabled]) return;

        for (UITouch *touch in event.allTouches) {
            UIView *view = touch.view;
            if (!view) continue;

            CGPoint point = [touch locationInView:view];
            switch (touch.phase) {
                case UITouchPhaseBegan:
                    if ([mgr isKeyView:view]) {
                        [mgr beginGlowForTouch:touch inView:view atPoint:point];
                    }
                    break;
                case UITouchPhaseMoved:
                    [mgr moveGlowForTouch:touch inView:view atPoint:point];
                    break;
                case UITouchPhaseEnded:
                case UITouchPhaseCancelled:
                    [mgr endGlowForTouch:touch];
                    break;
                default:
                    break;
            }
        }
    }
}

%end
