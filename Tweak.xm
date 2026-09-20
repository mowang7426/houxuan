#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "RainbowEffectView.h"
static char RKOverlayKey;
static NSString *RKName(UIView *v) { return NSStringFromClass(v.class).lowercaseString; }
static BOOL RKExcluded(UIView *v) {
    NSString *n = RKName(v);
    return [n containsString:@"candidate"] || [n containsString:@"prediction"] || [n containsString:@"suggestion"] || [n containsString:@"toolbar"];
}
static UIView *RKLayout(UIView *v) {
    UIView *fallback = nil;
    for (UIView *p = v; p && ![p isKindOfClass:UIWindow.class]; p = p.superview) {
        if (RKExcluded(p)) return nil;
        NSString *n = RKName(p);
        // UIKeyboardLayoutStar is the native key-layout view, not the input container.
        if ([n containsString:@"keyboardlayoutstar"]) return p;
        if (!fallback && ([n containsString:@"keyboard"] || [n containsString:@"keyplane"]) &&
            p.bounds.size.width > 180 && p.bounds.size.height > 100 && p.bounds.size.height < 500)
            fallback = p;
    }
    return fallback;
}
static void RKCollectExclusions(UIView *node, UIView *host, UIBezierPath *path, NSUInteger depth) {
    if (depth > 8) return;
    for (UIView *v in node.subviews) {
        if ([v isKindOfClass:RainbowEffectView.class] || v.hidden || v.alpha < .01) continue;
        if (RKExcluded(v)) {
            CGRect r = CGRectIntersection(host.bounds, [v convertRect:v.bounds toView:host]);
            if (!CGRectIsNull(r) && !CGRectIsEmpty(r)) [path appendPath:[UIBezierPath bezierPathWithRect:r]];
        } else RKCollectExclusions(v, host, path, depth + 1);
    }
}
%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (event.type != UIEventTypeTouches) return;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseBegan) continue;
        UIView *host = RKLayout(touch.view);
        if (!host || !host.window) continue;
        CGPoint point = [touch locationInView:host];
        if (!CGRectContainsPoint(host.bounds, point)) continue;
        RainbowEffectView *effect = objc_getAssociatedObject(host, &RKOverlayKey);
        if (!effect) {
            effect = [[RainbowEffectView alloc] initWithFrame:host.bounds];
            objc_setAssociatedObject(host, &RKOverlayKey, effect, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [host addSubview:effect];
        }
        effect.frame = host.bounds;
        [host bringSubviewToFront:effect];
        UIBezierPath *visible = [UIBezierPath bezierPathWithRect:effect.bounds];
        RKCollectExclusions(host, host, visible, 0);
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.frame = effect.bounds;
        mask.path = visible.CGPath;
        mask.fillRule = kCAFillRuleEvenOdd;
        effect.layer.mask = mask;
        [effect showRippleAtPoint:[touch locationInView:effect]];
    }
}
%end
