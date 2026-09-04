#import "ColorPickerController.h"

static NSString *const kSuite = @"com.mowang.kbglow";
static NSString *const kColorKey = @"glowColor";

@implementation ColorPickerController

- (NSArray *)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *specs = [NSMutableArray array];

        // 预设颜色
        [specs addObject:[self groupSpecifierWithName:@"预设颜色"]];

        NSArray *presets = @[
            @{@"name": @"绿色", @"color": [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0]},
            @{@"name": @"蓝色", @"color": [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0]},
            @{@"name": @"红色", @"color": [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0]},
            @{@"name": @"紫色", @"color": [UIColor colorWithRed:0.6 green:0.2 blue:1.0 alpha:1.0]},
            @{@"name": @"橙色", @"color": [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0]},
            @{@"name": @"青色", @"color": [UIColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:1.0]},
            @{@"name": @"粉色", @"color": [UIColor colorWithRed:1.0 green:0.4 blue:0.7 alpha:1.0]},
            @{@"name": @"白色", @"color": [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]},
        ];

        for (NSDictionary *preset in presets) {
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:preset[@"name"]
                                                                  target:self
                                                                     set:nil
                                                                     get:nil
                                                                  detail:nil
                                                                    cell:PSButtonCell
                                                                    edit:nil];
            [spec setProperty:preset[@"color"] forKey:@"color"];
            [spec setProperty:@selector(selectPresetColor:) forKey:@"action"];
            [specs addObject:spec];
        }

        // 自定义颜色
        [specs addObject:[self groupSpecifierWithName:@"自定义颜色"]];
        [specs addObject:[self sliderSpecifierWithName:@"红色 R" key:@"customR" min:0 max:1 default:0]];
        [specs addObject:[self sliderSpecifierWithName:@"绿色 G" key:@"customG" min:0 max:1 default:1]];
        [specs addObject:[self sliderSpecifierWithName:@"蓝色 B" key:@"customB" min:0 max:1 default:0]];

        // 应用自定义颜色按钮
        PSSpecifier *applyBtn = [PSSpecifier preferenceSpecifierNamed:@"应用自定义颜色"
                                                                  target:self
                                                                     set:nil
                                                                     get:nil
                                                                  detail:nil
                                                                    cell:PSButtonCell
                                                                    edit:nil];
        [applyBtn setProperty:@selector(applyCustomColor) forKey:@"action"];
        [specs addObject:applyBtn];

        _specifiers = specs;
    }
    return _specifiers;
}

- (PSSpecifier *)groupSpecifierWithName:(NSString *)name {
    return [PSSpecifier preferenceSpecifierNamed:name target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
}

- (PSSpecifier *)sliderSpecifierWithName:(NSString *)name key:(NSString *)key min:(CGFloat)min max:(CGFloat)max default:(CGFloat)def {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                          target:self
                                                             set:@selector(setCustomValue:specifier:)
                                                             get:@selector(readCustomValue:)
                                                          detail:nil
                                                            cell:PSSliderCell
                                                            edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:@(min) forKey:@"minimumValue"];
    [spec setProperty:@(max) forKey:@"maximumValue"];
    [spec setProperty:@(def) forKey:@"default"];
    return spec;
}

#pragma mark - 预设颜色

- (void)selectPresetColor:(PSSpecifier *)specifier {
    UIColor *color = [specifier propertyForKey:@"color"];
    [self saveColor:color];
    [self showToast:@"颜色已应用"];
}

#pragma mark - 自定义颜色

- (void)setCustomValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

- (id)readCustomValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    id value = [defaults objectForKey:key];
    if (value == nil) {
        value = [specifier propertyForKey:@"default"];
    }
    return value;
}

- (void)applyCustomColor {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    CGFloat r = [[defaults objectForKey:@"customR"] floatValue] ?: 0;
    CGFloat g = [[defaults objectForKey:@"customG"] floatValue] ?: 1;
    CGFloat b = [[defaults objectForKey:@"customB"] floatValue] ?: 0;
    UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    [self saveColor:color];
    [self showToast:@"自定义颜色已应用"];
}

#pragma mark - 保存颜色

- (void)saveColor:(UIColor *)color {
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    NSArray *components = @[@(r), @(g), @(b), @(a)];

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [defaults setObject:components forKey:kColorKey];
    [defaults synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)showToast:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
