#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "RainbowEffectView.h"

static char kRKEffectKey;
static BOOL RKIsKeyboardView(UIView *v) {
    NSString *n = NSStringFromClass(v.class).lowercaseString;
    return [n containsString:@"keyboard"] || [n containsString:@"inputview"] || [n containsString:@"uiinput"];
}
static RainbowEffectView *RKEffectFor(UIView *v) {
    RainbowEffectView *e = objc_getAssociatedObject(v, &kRKEffectKey);
    if (!e && RKIsKeyboardView(v)) {
        e = [[RainbowEffectView alloc] initWithFrame:v.bounds];
        e.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        objc_setAssociatedObject(v, &kRKEffectKey, e, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [v addSubview:e];
        [e startAnimation];
    }
    return e;
}

%hook UIView
- (void)didMoveToWindow {
    %orig;
    if (self.window && RKIsKeyboardView(self) && self.superview) {
        RKEffectFor(self);
    }
}
%end

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (event.type != UIEventTypeTouches) return;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseBegan) continue;
        UIView *v = touch.view;
        while (v && !RKIsKeyboardView(v)) v = v.superview;
        RainbowEffectView *e = v ? RKEffectFor(v) : nil;
        if (e) [e showRippleAtPoint:[touch locationInView:e]];
    }
}
%end

%ctor {
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            for (UIWindow *w in UIApplication.sharedApplication.windows) {
                for (UIView *v in w.subviews) if (RKIsKeyboardView(v)) RKEffectFor(v);
            }
        }];
    }
}
