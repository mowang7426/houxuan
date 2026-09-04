#import <UIKit/UIKit.h>
#import "KBGlowManager.h"

%hook UIWindow
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (event.type != UIEventTypeTouches) return;
    KBGlowManager *m=[KBGlowManager sharedManager];
    if (![m isCurrentKeyboardEnabled]) return;
    for (UITouch *t in event.allTouches) {
        if (t.phase != UITouchPhaseBegan) continue;
        UIView *v=t.view; if (!v || !v.window) continue;
        CGPoint p=[t locationInView:v];
        [m triggerGlowInView:v atPoint:p];
    }
}
%end

%ctor { @autoreleasepool { [KBGlowManager sharedManager]; } }
