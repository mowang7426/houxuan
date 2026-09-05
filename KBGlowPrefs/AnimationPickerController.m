#import <CoreFoundation/CoreFoundation.h>
#import "AnimationPickerController.h"

static CFStringRef const kAppID = CFSTR("com.mowang.kbglow");
static CFStringRef const kNotify = CFSTR("com.mowang.kbglow.settingsChanged");

static void KBGlowPrefsSetBool(NSString *key, BOOL value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, value ? kCFBooleanTrue : kCFBooleanFalse, kAppID);
}

static BOOL KBGlowPrefsGetBool(NSString *key, BOOL def) {
    Boolean exists = false;
    Boolean value = CFPreferencesGetAppBooleanValue((__bridge CFStringRef)key, kAppID, &exists);
    return exists ? (BOOL)value : def;
}

static void KBGlowPrefsSyncAndNotify(void) {
    CFPreferencesAppSynchronize(kAppID);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kNotify, NULL, NULL, true);
}

@implementation AnimationPickerController

- (NSArray *)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *specs = [NSMutableArray array];
        [specs addObject:[PSSpecifier preferenceSpecifierNamed:@"动画类型"
                                                         target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil]];
        NSArray *items = @[
            @{ @"title": @"涟漪扩散", @"key": @"animRipple" },
            @{ @"title": @"常驻光晕", @"key": @"animGlow" },
            @{ @"title": @"粒子爆发", @"key": @"animParticle" }
        ];
        for (NSDictionary *item in items) {
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:item[@"title"]
                                                                  target:self
                                                                     set:@selector(setAnimationValue:specifier:)
                                                                     get:@selector(readAnimationValue:)
                                                                  detail:nil cell:PSSwitchCell edit:nil];
            [spec setProperty:item[@"key"] forKey:@"animationKey"];
            [spec setProperty:@NO forKey:@"default"];
            [specs addObject:spec];
        }
        [specs addObject:[PSSpecifier preferenceSpecifierNamed:@"同一时间只启用一种动画。"
                                                             target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil]];
        _specifiers = specs;
    }
    return _specifiers;
}

- (void)setAnimationValue:(id)value specifier:(PSSpecifier *)specifier {
    if (![value respondsToSelector:@selector(boolValue)]) return;
    if (![value boolValue]) return;
    NSString *selected = [specifier propertyForKey:@"animationKey"];
    if (!selected) return;
    for (NSString *key in @[@"animRipple", @"animGlow", @"animParticle"]) {
        KBGlowPrefsSetBool(key, [key isEqualToString:selected]);
    }
    KBGlowPrefsSyncAndNotify();
    [self reloadSpecifiers];
}

- (id)readAnimationValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"animationKey"];
    if (!key) return @NO;
    if (KBGlowPrefsGetBool(key, NO)) return @YES;
    return [key isEqualToString:@"animRipple"] ? @YES : @NO;
}

@end
