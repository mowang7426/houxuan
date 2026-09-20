#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "RKCandidateTransport.h"

static NSString *RKOwner(Class cls, SEL sel) {
    for (Class c = cls; c; c = class_getSuperclass(c)) {
        unsigned int n = 0; Method *ms = class_copyMethodList(c, &n); BOOL found = NO;
        for (unsigned int i = 0; i < n; i++) if (method_getName(ms[i]) == sel) { found = YES; break; }
        free(ms); if (found) return NSStringFromClass(c);
    }
    return @"none";
}
static void RKScanView(UIView *v, NSMutableArray *rows, NSUInteger depth) {
    if (!v || depth > 16 || rows.count >= 900) return;
    NSString *name = NSStringFromClass(v.class).lowercaseString;
    BOOL relevant = depth < 4 || [name containsString:@"candidate"] || [name containsString:@"predict"] ||
        [name containsString:@"suggest"] || [name containsString:@"keyboard"] || [name containsString:@"keyplane"] ||
        [name containsString:@"label"] || [name containsString:@"text"] || [name containsString:@"table"] ||
        [name containsString:@"cell"] || [name containsString:@"token"] || [name containsString:@"collection"];
    if (relevant) {
        [rows addObject:@{@"class":NSStringFromClass(v.class), @"depth":@(depth),
            @"size":NSStringFromCGSize(v.bounds.size), @"hidden":@(v.hidden),
            @"alpha":@(v.alpha), @"isLabel":@([v isKindOfClass:UILabel.class]),
            @"drawRectOwner":RKOwner(v.class, @selector(drawRect:)),
            @"drawTextOwner":RKOwner(v.class, @selector(drawTextInRect:)),
            @"subviews":@(v.subviews.count)}];
    }
    for (UIView *child in v.subviews) RKScanView(child, rows, depth + 1);
}
static void RKWriteScan(void) {
    NSMutableArray *rows = [NSMutableArray array];
    NSArray *windows = UIApplication.sharedApplication.windows ?: @[];
    for (UIWindow *window in windows) {
        if (window.hidden || window.alpha <= 0.01) continue;
        RKScanView(window, rows, 0);
    }
    NSString *bid = NSBundle.mainBundle.bundleIdentifier ?: @"unknown";
    NSDictionary *prefs = RKReceiveColorState() ?: @{};
    NSDictionary *report = @{@"version":@6, @"processBundle":bid,
        @"windowCount":@(windows.count), @"visibleWindowCount":@(rows.count),
        @"preferenceSource":RKReceiveColorState() ? @"notify-state" : @"none",
        @"flags":@{ @"CandidateGradient":prefs[@"CandidateGradient"] ?: @"unset",
                     @"CandidateNative":prefs[@"CandidateNative"] ?: @"unset" },
        @"views":rows};
    NSString *name = [NSString stringWithFormat:@"RainbowKeyboard-native-scan-%@.plist", bid];
    NSString *path = [@"/var/mobile/Library/Preferences" stringByAppendingPathComponent:name];
    if (![report writeToFile:path atomically:YES])
        [report writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:name] atomically:YES];
}
%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (event.type != UIEventTypeTouches) return;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseBegan) continue;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            RKWriteScan();
        });
        return;
    }
}
%end
%ctor { @autoreleasepool { %init; } }
