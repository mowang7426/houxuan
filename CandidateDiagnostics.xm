#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <unistd.h>
#import "RKCandidateTransport.h"

static NSUInteger RKDLabelDraws;
static NSTimeInterval RKDLast;
static NSString * const RKDPrefs = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";
static NSString *RKDPreferenceSource;
static NSDictionary *RKDReadPreferences(void) {
    NSDictionary *values = RKReceiveColorState();
    if (values) { RKDPreferenceSource = @"notify-state"; return values; }
    values = [NSDictionary dictionaryWithContentsOfFile:RKDPrefs];
    if (values) { RKDPreferenceSource = @"file"; return values; }
    NSMutableDictionary *shared = [NSMutableDictionary dictionary];
    for (NSString *key in @[@"CandidateGradient", @"CandidateNative", @"CandidateWeType", @"CandidateStart", @"CandidateEnd", @"RKProbeMarker"]) {
        id value = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key,
            CFSTR("com.minis.rainbowkeyboard")));
        if (value) shared[key] = value;
    }
    RKDPreferenceSource = shared.count ? @"cfpreferences" : @"none";
    return shared;
}
static NSMutableSet *RKDClasses;
static BOOL RKDKeyboard(UIView *v) {
    NSString *n = NSStringFromClass(v.class).lowercaseString;
    return [n containsString:@"keyboard"] || [n containsString:@"keyplane"] || [n containsString:@"inputview"];
}
static NSString *RKDOwner(Class cls, SEL sel) {
    for (Class c = cls; c; c = class_getSuperclass(c)) {
        unsigned int count = 0;
        Method *methods = class_copyMethodList(c, &count);
        BOOL found = NO;
        for (unsigned int i=0; i<count; i++) if (method_getName(methods[i]) == sel) { found=YES; break; }
        free(methods);
        if (found) return NSStringFromClass(c);
    }
    return @"none";
}
static NSArray *RKDInterfaces(void) {
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    NSMutableArray *found = [NSMutableArray array];
    SEL selector = sel_registerName("renderCandidateWord:focusedStyle:atIndex:");
    for (unsigned int i = 0; i < count; i++) {
        for (int kind = 0; kind < 2; kind++) {
            Class cls = kind ? object_getClass(classes[i]) : classes[i];
            Method method = class_getInstanceMethod(cls, selector);
            if (!method) continue;
            Class parent = class_getSuperclass(cls);
            if (parent && class_getInstanceMethod(parent, selector) == method) continue;
            const char *types = method_getTypeEncoding(method);
            const char *image = class_getImageName(classes[i]);
            [found addObject:@{@"class":NSStringFromClass(classes[i]),
                @"classMethod":@(kind == 1),
                @"encoding":types ? [NSString stringWithUTF8String:types] : @"unknown",
                @"image":image ? [[NSString stringWithUTF8String:image] lastPathComponent] : @"unknown"}];
        }
    }
    free(classes);
    return found;
}
static void RKDTree(UIView *v, NSMutableArray *rows, NSUInteger depth) {
    if (depth > 12 || rows.count >= 240) return;
    NSString *name = NSStringFromClass(v.class);
    if ([name isEqualToString:@"RainbowEffectView"]) return;
    [rows addObject:@{@"class":name,@"depth":@(depth),@"size":NSStringFromCGSize(v.bounds.size),
        @"hidden":@(v.hidden),@"isLabel":@([v isKindOfClass:UILabel.class]),
        @"drawTextOwner":RKDOwner(v.class,@selector(drawTextInRect:)),
        @"drawRectOwner":RKDOwner(v.class,@selector(drawRect:))}];
    for (UIView *child in v.subviews) RKDTree(child,rows,depth+1);
}
static void RKDWriteProcessProbe(void) {
    NSDictionary *prefs = RKDReadPreferences();
    NSString *bid = NSBundle.mainBundle.bundleIdentifier ?: @"unknown";
    NSString *exec = NSProcessInfo.processInfo.arguments.firstObject ?: @"unknown";
    NSDictionary *report = @{
        @"version": @7,
        @"probe": @"startup-selector-scan",
        @"processBundle": bid,
        @"executable": exec,
        @"pid": @(getpid()),
        @"preferenceSource": RKDPreferenceSource ?: @"none",
        @"flags": @{
            @"CandidateGradient": prefs[@"CandidateGradient"] ?: @"unset",
            @"CandidateNative": prefs[@"CandidateNative"] ?: @"unset"
        },
        @"candidateInterfaces": RKDInterfaces()
    };
    NSString *file = [NSString stringWithFormat:@"RainbowKeyboard-native-probe-%@.plist", bid];
    NSString *path = [@"/var/mobile/Library/Preferences" stringByAppendingPathComponent:file];
    if (![report writeToFile:path atomically:YES])
        [report writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:file] atomically:YES];
}

%hook UILabel
- (void)drawTextInRect:(CGRect)rect {
    // Record class names only, restricted to keyboard-associated branches.
    for (UIView *p=self; p; p=p.superview) {
        if (RKDKeyboard(p)) {
            RKDLabelDraws++;
            if (RKDClasses.count < 80) [RKDClasses addObject:NSStringFromClass(self.class)];
            break;
        }
    }
    %orig;
}
%end
%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (event.type != UIEventTypeTouches) return;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseBegan) continue;
        UIView *root = nil;
        for (UIView *p=touch.view; p && ![p isKindOfClass:UIWindow.class]; p=p.superview)
            if (RKDKeyboard(p)) root=p;
        if (!root) continue;
        NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
        if (now-RKDLast < 4) return;
        RKDLast=now;
        NSMutableArray *rows=[NSMutableArray array]; RKDTree(root,rows,0);
        NSDictionary *prefs=RKDReadPreferences();
        NSMutableDictionary *flags=[NSMutableDictionary dictionary];
        for (NSString *key in @[@"CandidateGradient",@"CandidateNative",@"CandidateWeType"])
            flags[key]=prefs[key] ? @([prefs[key] boolValue]) : @"unset";
        NSString *bid=NSBundle.mainBundle.bundleIdentifier ?: @"unknown";
        NSDictionary *report=@{@"version":@5,@"receivedStart":prefs[@"CandidateStart"] ?: @"unset",@"receivedEnd":prefs[@"CandidateEnd"] ?: @"unset",@"probeMarker":prefs[@"RKProbeMarker"] ?: @"unset",@"keyCount":@(prefs.count),@"preferenceSource":RKDPreferenceSource ?: @"none",@"candidateInterfaces":RKDInterfaces(),@"processBundle":bid,@"preferencesReadable":@(prefs.count > 0),
            @"flags":flags,@"labelDrawCount":@(RKDLabelDraws),@"drawClasses":RKDClasses.allObjects ?: @[],@"views":rows};
        NSString *file=[NSString stringWithFormat:@"RainbowKeyboard-diagnostic-%@.plist",bid];
        NSString *path=[@"/var/mobile/Library/Preferences" stringByAppendingPathComponent:file];
        if (![report writeToFile:path atomically:YES])
            [report writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:file] atomically:YES];
        return;
    }
}
%end
%ctor {
    @autoreleasepool {
        RKDClasses=[NSMutableSet set];
        dispatch_async(dispatch_get_main_queue(), ^{ RKDWriteProcessProbe(); });
    }
}
