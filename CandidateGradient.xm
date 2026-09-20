#import <UIKit/UIKit.h>

static NSDictionary *RKCandidatePrefs;
static NSHashTable<UILabel *> *RKCandidateLabels;
static NSString * const RKCandidatePath = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";

static BOOL RKCandidateRegion(UIView *view) {
    for (UIView *p = view; p; p = p.superview) {
        NSString *name = NSStringFromClass(p.class).lowercaseString;
        if ([name containsString:@"candidate"] || [name containsString:@"prediction"] || [name containsString:@"suggestion"]) return YES;
        if ([p isKindOfClass:UIWindow.class]) break;
    }
    return NO;
}
static UIColor *RKCandidateColor(id value, UIColor *fallback) {
    if (![value isKindOfClass:NSArray.class] || [value count] != 3) return fallback;
    for (id component in value) if (![component isKindOfClass:NSNumber.class]) return fallback;
    return [UIColor colorWithRed:MIN(1,MAX(0,[value[0] doubleValue]))
                           green:MIN(1,MAX(0,[value[1] doubleValue]))
                            blue:MIN(1,MAX(0,[value[2] doubleValue])) alpha:1];
}
static void RKCandidateReload(void) {
    RKCandidatePrefs = [NSDictionary dictionaryWithContentsOfFile:RKCandidatePath] ?: @{};
    for (UILabel *label in RKCandidateLabels) [label setNeedsDisplay];
}
static void RKCandidateChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef info) {
    dispatch_async(dispatch_get_main_queue(), ^{ RKCandidateReload(); });
}
%hook UILabel
- (void)drawTextInRect:(CGRect)rect {
    if (!RKCandidateRegion(self)) { %orig; return; }
    [RKCandidateLabels addObject:self];
    if (![RKCandidatePrefs[@"CandidateGradient"] boolValue]) { %orig; return; }
    NSString *bid = NSBundle.mainBundle.bundleIdentifier.lowercaseString ?: @"";
    NSString *scope = [bid containsString:@"wetype"] ? @"CandidateWeType" : @"CandidateNative";
    if (RKCandidatePrefs[scope] && ![RKCandidatePrefs[scope] boolValue]) { %orig; return; }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];
    if (!ctx || CGRectIsEmpty(textRect)) { %orig; return; }
    UIColor *first = RKCandidateColor(RKCandidatePrefs[@"CandidateStart"], [UIColor colorWithRed:0 green:.65 blue:1 alpha:1]);
    UIColor *last = RKCandidateColor(RKCandidatePrefs[@"CandidateEnd"], [UIColor colorWithRed:.85 green:.15 blue:1 alpha:1]);
    NSArray *colors = @[(id)first.CGColor,(id)last.CGColor];
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, NULL);
    CGColorSpaceRelease(space);
    if (!gradient) { %orig; return; }
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx,rect);
    // Isolate original glyph drawing, then color only its alpha. Never change
    // textColor/attributedText or touch the label's background and hit testing.
    CGContextBeginTransparencyLayer(ctx,NULL);
    %orig;
    CGContextSetBlendMode(ctx,kCGBlendModeSourceIn);
    CGContextDrawLinearGradient(ctx, gradient,
        CGPointMake(CGRectGetMinX(textRect),CGRectGetMidY(textRect)),
        CGPointMake(CGRectGetMaxX(textRect),CGRectGetMidY(textRect)),
        kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextEndTransparencyLayer(ctx);
    CGContextRestoreGState(ctx);
    CGGradientRelease(gradient);
}
%end
%ctor {
    @autoreleasepool {
        RKCandidateLabels = [NSHashTable weakObjectsHashTable];
        RKCandidateReload();
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, RKCandidateChanged,
            CFSTR("com.minis.rainbowkeyboard.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) { RKCandidateReload(); }];
    }
}
