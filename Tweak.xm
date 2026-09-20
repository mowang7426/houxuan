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

static BOOL RKIsCandidateView(UIView *v) {
    NSString *n = NSStringFromClass(v.class).lowercaseString;
    return [n containsString:@"candidate"] || [n containsString:@"suggest"] ||
           [n containsString:@"prediction"] || [n containsString:@"search"];
}

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (event.type != UIEventTypeTouches) return;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseBegan) continue;
        UIView *key = touch.view;
        UIView *keyboard = key;
        while (keyboard && !RKIsKeyboardView(keyboard)) keyboard = keyboard.superview;
        if (!keyboard || key == keyboard) continue;

        // Walk only through the touched branch. Stop at the first likely
        // candidate/suggestion view so candidate words never emit a glow.
        UIView *cursor = key;
        BOOL candidate = NO;
        while (cursor && cursor != keyboard) {
            if (RKIsCandidateView(cursor)) { candidate = YES; break; }
            cursor = cursor.superview;
        }
        if (candidate) continue;

        RainbowEffectView *e = RKEffectFor(keyboard);
        if (!e) continue;
        CGRect keyRect = [key convertRect:key.bounds toView:e];
        CGPoint center = CGPointMake(CGRectGetMidX(keyRect), CGRectGetMidY(keyRect));
        [e showGlowAtPoint:center keySize:keyRect.size];
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
