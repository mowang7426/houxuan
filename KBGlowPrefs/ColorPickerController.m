#import <CoreFoundation/CoreFoundation.h>
#import "ColorPickerController.h"

static CFStringRef const kAppID = CFSTR("com.mowang.kbglow");
static CFStringRef const kNotify = CFSTR("com.mowang.kbglow.settingsChanged");

static void KBGlowPrefsSet(NSString *key, id value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, kAppID);
}

static id KBGlowPrefsGet(NSString *key) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, kAppID);
    if (value) return (__bridge_transfer id)value;
    return nil;
}

static void KBGlowPrefsSetBool(NSString *key, BOOL value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, value ? kCFBooleanTrue : kCFBooleanFalse, kAppID);
}

static BOOL KBGlowPrefsGetBool(NSString *key, BOOL def) {
    Boolean exists = false;
    Boolean value = CFPreferencesGetAppBooleanValue((__bridge CFStringRef)key, kAppID, &exists);
    return exists ? (BOOL)value : def;
}

static double KBGlowPrefsGetDouble(NSString *key, double def) {
    id value = KBGlowPrefsGet(key);
    if ([value isKindOfClass:[NSNumber class]]) return [value doubleValue];
    return def;
}

static void KBGlowPrefsSyncAndNotify(void) {
    CFPreferencesAppSynchronize(kAppID);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kNotify, NULL, NULL, true);
}

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
    NSArray *keys = @[@"colorGreen", @"colorBlue", @"colorRed", @"colorPurple", @"colorOrange", @"colorCyan", @"colorPink", @"colorWhite"];
    for (NSString *key in keys) KBGlowPrefsSetBool(key, [key isEqualToString:selected]);
    CFPreferencesSetAppValue(CFSTR("customColor"), NULL, kAppID);
    KBGlowPrefsSyncAndNotify();
    [self reloadSpecifiers];
    [self showToast:@"颜色已应用"];
}

- (id)readPresetValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"colorKey"];
    if (!key) return @NO;
    if (KBGlowPrefsGetBool(key, NO)) return @YES;
    return [key isEqualToString:@"colorGreen"] ? @YES : @NO;
}

- (void)setCustomValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) return;
    KBGlowPrefsSet(key, value);
    CFPreferencesAppSynchronize(kAppID);
}

- (id)readCustomValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    id value = KBGlowPrefsGet(key);
    return value ?: [specifier propertyForKey:@"default"];
}

- (void)applyCustomColor:(PSSpecifier *)specifier {
    CGFloat r = KBGlowPrefsGetDouble(@"customR", 0.0);
    CGFloat g = KBGlowPrefsGetDouble(@"customG", 1.0);
    CGFloat b = KBGlowPrefsGetDouble(@"customB", 0.0);
    for (NSString *key in @[@"colorGreen", @"colorBlue", @"colorRed", @"colorPurple", @"colorOrange", @"colorCyan", @"colorPink", @"colorWhite"]) {
        KBGlowPrefsSetBool(key, NO);
    }
    KBGlowPrefsSet(@"customColor", @[@(r), @(g), @(b), @1.0]);
    KBGlowPrefsSyncAndNotify();
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
