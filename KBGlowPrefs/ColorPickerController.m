#import <CoreFoundation/CoreFoundation.h>
#import "ColorPickerController.h"

static NSString *const kSuite = @"com.mowang.kbglow";
static CFStringRef const kNotify = CFSTR("com.mowang.kbglow.settingsChanged");

@implementation ColorPickerController

- (NSArray *)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *specs = [NSMutableArray array];
        [specs addObject:[self groupSpecifierWithName:@"预设颜色"]];
        NSArray *presets = @[
            @{ @"name": @"绿色", @"key": @"colorGreen" },
            @{ @"name": @"蓝色", @"key": @"colorBlue" },
            @{ @"name": @"红色", @"key": @"colorRed" },
            @{ @"name": @"紫色", @"key": @"colorPurple" },
            @{ @"name": @"橙色", @"key": @"colorOrange" },
            @{ @"name": @"青色", @"key": @"colorCyan" },
            @{ @"name": @"粉色", @"key": @"colorPink" },
            @{ @"name": @"白色", @"key": @"colorWhite" }
        ];
        for (NSDictionary *preset in presets) {
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:preset[@"name"]
                                                                  target:self
                                                                     set:@selector(setPresetValue:specifier:)
                                                                     get:@selector(readPresetValue:)
                                                                  detail:nil cell:PSSwitchCell edit:nil];
            [spec setProperty:preset[@"key"] forKey:@"colorKey"];
            [spec setProperty:@NO forKey:@"default"];
            [specs addObject:spec];
        }

        [specs addObject:[self groupSpecifierWithName:@"自定义颜色"]];
        [specs addObject:[self sliderSpecifierWithName:@"红色 R" key:@"customR" min:0 max:1 default:0]];
        [specs addObject:[self sliderSpecifierWithName:@"绿色 G" key:@"customG" min:0 max:1 default:1]];
        [specs addObject:[self sliderSpecifierWithName:@"蓝色 B" key:@"customB" min:0 max:1 default:0]];
        PSSpecifier *applyBtn = [PSSpecifier preferenceSpecifierNamed:@"应用自定义颜色"
                                                                  target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
        applyBtn.buttonAction = @selector(applyCustomColor:);
        [specs addObject:applyBtn];
        _specifiers = specs;
    }
    return _specifiers;
}

- (PSSpecifier *)groupSpecifierWithName:(NSString *)name {
    return [PSSpecifier preferenceSpecifierNamed:name target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
}

- (PSSpecifier *)sliderSpecifierWithName:(NSString *)name key:(NSString *)key min:(CGFloat)min max:(CGFloat)max default:(CGFloat)def {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name target:self
                                                             set:@selector(setCustomValue:specifier:)
                                                             get:@selector(readCustomValue:)
                                                          detail:nil cell:PSSliderCell edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:@(min) forKey:@"minimumValue"];
    [spec setProperty:@(max) forKey:@"maximumValue"];
    [spec setProperty:@(def) forKey:@"default"];
    return spec;
}

- (void)setPresetValue:(id)value specifier:(PSSpecifier *)specifier {
    if (![value respondsToSelector:@selector(boolValue)] || ![value boolValue]) return;
    NSString *selected = [specifier propertyForKey:@"colorKey"];
    if (!selected) return;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    NSArray *keys = @[@"colorGreen", @"colorBlue", @"colorRed", @"colorPurple", @"colorOrange", @"colorCyan", @"colorPink", @"colorWhite"];
    for (NSString *key in keys) [defaults setBool:[key isEqualToString:selected] forKey:key];
    [defaults removeObjectForKey:@"customColor"];
    [defaults setObject:selected forKey:@"colorType"];
    [defaults synchronize];
    CFPreferencesAppSynchronize((__bridge CFStringRef)kSuite);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kNotify, NULL, NULL, true);
    [self reloadSpecifiers];
    [self showToast:@"颜色已应用"];
}

- (id)readPresetValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"colorKey"];
    if (!key) return @NO;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    if ([defaults objectForKey:key]) return @([defaults boolForKey:key]);
    return [key isEqualToString:@"colorGreen"] ? @YES : @NO;
}

- (void)setCustomValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) return;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [defaults setDouble:[value doubleValue] forKey:key];
    [defaults synchronize];
    CFPreferencesAppSynchronize((__bridge CFStringRef)kSuite);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kNotify, NULL, NULL, true);
}

- (id)readCustomValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    id value = [defaults objectForKey:key];
    return value ?: [specifier propertyForKey:@"default"];
}

- (void)applyCustomColor:(PSSpecifier *)specifier {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    CGFloat r = [defaults objectForKey:@"customR"] ? [defaults doubleForKey:@"customR"] : 0.0;
    CGFloat g = [defaults objectForKey:@"customG"] ? [defaults doubleForKey:@"customG"] : 1.0;
    CGFloat b = [defaults objectForKey:@"customB"] ? [defaults doubleForKey:@"customB"] : 0.0;
    for (NSString *key in @[@"colorGreen", @"colorBlue", @"colorRed", @"colorPurple", @"colorOrange", @"colorCyan", @"colorPink", @"colorWhite"]) {
        [defaults setBool:NO forKey:key];
    }
    [defaults setObject:@[@(r), @(g), @(b), @1.0] forKey:@"customColor"];
    [defaults setObject:@"custom" forKey:@"colorType"];
    [defaults synchronize];
    CFPreferencesAppSynchronize((__bridge CFStringRef)kSuite);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kNotify, NULL, NULL, true);
    [self reloadSpecifiers];
    [self showToast:@"自定义颜色已应用"];
}

- (void)showToast:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
