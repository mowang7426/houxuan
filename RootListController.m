#import <CoreFoundation/CoreFoundation.h>
#import "RootListController.h"
#import "ColorPickerController.h"
#import "AnimationPickerController.h"

static NSString *const kSuite = @"com.mowang.kbglow";

@implementation RootListController

- (NSArray *)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *specs = [NSMutableArray array];

        [specs addObject:[self groupSpecifierWithName:@"总开关"]];
        [specs addObject:[self switchSpecifierWithName:@"启用 KBGlow" key:@"enabled" default:YES]];

        [specs addObject:[self groupSpecifierWithName:@"启用键盘"]];
        [specs addObject:[self switchSpecifierWithName:@"微信输入法" key:@"wechatEnabled" default:YES]];
        [specs addObject:[self switchSpecifierWithName:@"百度输入法" key:@"baiduEnabled" default:YES]];
        [specs addObject:[self switchSpecifierWithName:@"搜狗输入法" key:@"sogouEnabled" default:YES]];

        [specs addObject:[self groupSpecifierWithName:@"发光效果"]];

        PSSpecifier *animType = [PSSpecifier preferenceSpecifierNamed:@"动画类型"
                                                                  target:self
                                                                     set:nil get:nil
                                                                  detail:[AnimationPickerController class]
                                                                    cell:PSLinkCell edit:nil];
        [specs addObject:animType];

        PSSpecifier *colorSpec = [PSSpecifier preferenceSpecifierNamed:@"发光颜色"
                                                                   target:self
                                                                      set:nil get:nil
                                                                   detail:[ColorPickerController class]
                                                                     cell:PSLinkCell edit:nil];
        [specs addObject:colorSpec];

        [specs addObject:[self sliderSpecifierWithName:@"发光大小" key:@"glowSize" min:20 max:150 default:60]];
        [specs addObject:[self sliderSpecifierWithName:@"动画时长(秒)" key:@"glowDuration" min:0.1 max:2.0 default:0.6]];
        [specs addObject:[self sliderSpecifierWithName:@"不透明度" key:@"glowOpacity" min:0.1 max:1.0 default:0.8]];
        [specs addObject:[self switchSpecifierWithName:@"跟随手指位置" key:@"followFinger" default:YES]];

        [specs addObject:[self groupSpecifierWithName:@"其他"]];
        PSSpecifier *resetBtn = [PSSpecifier preferenceSpecifierNamed:@"重置所有设置"
                                                                 target:self
                                                                    set:nil
                                                                    get:nil detail:nil cell:PSButtonCell edit:nil];
        resetBtn.buttonAction = @selector(resetSettings:);
        [specs addObject:resetBtn];

        [specs addObject:[self groupSpecifierWithName:@"关于"]];
        [specs addObject:[PSSpecifier preferenceSpecifierNamed:@"KBGlow v1.0.2"
                                                         target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil]];
        [specs addObject:[PSSpecifier preferenceSpecifierNamed:@"作者: MoWang"
                                                         target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil]];

        _specifiers = specs;
    }
    return _specifiers;
}

- (PSSpecifier *)groupSpecifierWithName:(NSString *)name {
    return [PSSpecifier preferenceSpecifierNamed:name target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
}

- (PSSpecifier *)switchSpecifierWithName:(NSString *)name key:(NSString *)key default:(BOOL)def {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name target:self
                                                             set:@selector(setPreferenceValue:specifier:)
                                                             get:@selector(readPreferenceValue:)
                                                          detail:nil cell:PSSwitchCell edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:@(def) forKey:@"default"];
    return spec;
}

- (PSSpecifier *)sliderSpecifierWithName:(NSString *)name key:(NSString *)key min:(CGFloat)min max:(CGFloat)max default:(CGFloat)def {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name target:self
                                                             set:@selector(setPreferenceValue:specifier:)
                                                             get:@selector(readPreferenceValue:)
                                                          detail:nil cell:PSSliderCell edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:@(min) forKey:@"minimumValue"];
    [spec setProperty:@(max) forKey:@"maximumValue"];
    [spec setProperty:@(def) forKey:@"default"];
    return spec;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) return;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.mowang.kbglow.settingsChanged"), NULL, NULL, true);
    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) return nil;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    id value = [defaults objectForKey:key];
    return value ?: [specifier propertyForKey:@"default"];
}

- (void)resetSettings:(PSSpecifier *)specifier {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    NSArray *keys = @[@"enabled", @"animRipple", @"animGlow", @"animParticle", @"animationType",
                     @"glowColor", @"colorWhite", @"colorPink", @"colorCyan", @"colorOrange",
                     @"colorPurple", @"colorRed", @"colorBlue", @"customColor", @"glowSize",
                     @"glowDuration", @"glowOpacity", @"followFinger", @"wechatEnabled",
                     @"baiduEnabled", @"sogouEnabled", @"customR", @"customG", @"customB"];
    for (NSString *key in keys) [defaults removeObjectForKey:key];
    [defaults synchronize];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.mowang.kbglow.settingsChanged"), NULL, NULL, true);
    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
    [self reloadSpecifiers];
}

@end
