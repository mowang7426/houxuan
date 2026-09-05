#import <CoreFoundation/CoreFoundation.h>
#import "AnimationPickerController.h"

static NSString *const kSuite = @"com.mowang.kbglow";
static CFStringRef const kNotify = CFSTR("com.mowang.kbglow.settingsChanged");

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
        CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)@([key isEqualToString:selected]), CFSTR("com.mowang.kbglow"));
    }
    CFPreferencesAppSynchronize(CFSTR("com.mowang.kbglow"));
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kNotify, NULL, NULL, true);
    [self reloadSpecifiers];
}

- (id)readAnimationValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"animationKey"];
    if (!key) return @NO;
    id value = (__bridge_transfer id)CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR("com.mowang.kbglow"));
    if (value) return @([value boolValue]);
    return [key isEqualToString:@"animRipple"] ? @YES : @NO;
}

@end
