#import <CoreFoundation/CoreFoundation.h>
#import "AnimationPickerController.h"

static NSString *const kSuite = @"com.mowang.kbglow";

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
                                                                     set:nil
                                                                     get:nil
                                                                  detail:nil
                                                                    cell:PSButtonCell
                                                                    edit:nil];
            [spec setProperty:item[@"key"] forKey:@"animationKey"];
            spec.buttonAction = @selector(selectAnimation:);
            [specs addObject:spec];
        }
        [specs addObject:[PSSpecifier preferenceSpecifierNamed:@"说明：同一时间只启用一种动画。"
                                                             target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil]];
        _specifiers = specs;
    }
    return _specifiers;
}

- (void)selectAnimation:(PSSpecifier *)specifier {
    NSString *selected = [specifier propertyForKey:@"animationKey"];
    if (!selected) return;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [defaults setBool:[selected isEqualToString:@"animRipple"] forKey:@"animRipple"];
    [defaults setBool:[selected isEqualToString:@"animGlow"] forKey:@"animGlow"];
    [defaults setBool:[selected isEqualToString:@"animParticle"] forKey:@"animParticle"];
    [defaults synchronize];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.mowang.kbglow.settingsChanged"), NULL, NULL, true);
    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
    [self reloadSpecifiers];
}

@end
