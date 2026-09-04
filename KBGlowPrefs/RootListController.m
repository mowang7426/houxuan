#import "RootListController.h"
#import "ColorPickerController.h"

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

        PSSpecifier *animType = [self linkListSpecifierWithName:@"动画类型"
                                                              key:@"animationType"
                                                           titles:@[@"涟漪扩散", @"常驻光晕", @"粒子爆发"]
                                                           values:@[@0, @1, @2]];
        [specs addObject:animType];

        PSSpecifier *colorSpec = [PSSpecifier preferenceSpecifierNamed:@"发光颜色"
                                                                   target:self
                                                                      set:@selector(setPreferenceValue:specifier:)
                                                                      get:@selector(readPreferenceValue:)
                                                                   detail:[ColorPickerController class]
                                                                     cell:PSLinkCell
                                                                     edit:nil];
        [colorSpec setProperty:@"glowColor" forKey:@"key"];
        [specs addObject:colorSpec];

        [specs addObject:[self sliderSpecifierWithName:@"发光大小" key:@"glowSize" min:20 max:150 default:60]];
        [specs addObject:[self sliderSpecifierWithName:@"动画时长(秒)" key:@"glowDuration" min:0.1 max:2.0 default:0.6]];
        [specs addObject:[self sliderSpecifierWithName:@"不透明度" key:@"glowOpacity" min:0.1 max:1.0 default:0.8]];
        [specs addObject:[self switchSpecifierWithName:@"跟随手指位置" key:@"followFinger" default:YES]];

        [specs addObject:[self groupSpecifierWithName:@"其他"]];

        PSSpecifier *resetBtn = [PSSpecifier preferenceSpecifierNamed:@"重置所有设置"
                                                                 target:self
                                                                    set:nil
                                                                    get:nil
                                                                 detail:nil
                                                                   cell:PSButtonCell
                                                                   edit:nil];
        [resetBtn setProperty:NSStringFromSelector(@selector(resetSettings)) forKey:@"action"];
        [specs addObject:resetBtn];

        [specs addObject:[self groupSpecifierWithName:@"关于"]];
        PSSpecifier *about = [PSSpecifier preferenceSpecifierNamed:@"KBGlow v1.0.0"
                                                               target:self
                                                                  set:nil
                                                                  get:nil
                                                               detail:nil
                                                                 cell:PSStaticTextCell
                                                                 edit:nil];
        [specs addObject:about];
        PSSpecifier *author = [PSSpecifier preferenceSpecifierNamed:@"作者: MoWang"
                                                                target:self
                                                                   set:nil
                                                                   get:nil
                                                                detail:nil
                                                                  cell:PSStaticTextCell
                                                                  edit:nil];
        [specs addObject:author];

        _specifiers = specs;
    }
    return _specifiers;
}

- (PSSpecifier *)groupSpecifierWithName:(NSString *)name {
    return [PSSpecifier preferenceSpecifierNamed:name target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
}

- (PSSpecifier *)switchSpecifierWithName:(NSString *)name key:(NSString *)key default:(BOOL)def {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                          target:self
                                                             set:@selector(setPreferenceValue:specifier:)
                                                             get:@selector(readPreferenceValue:)
                                                          detail:nil
                                                            cell:PSSwitchCell
                                                            edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:@(def) forKey:@"default"];
    return spec;
}

- (PSSpecifier *)sliderSpecifierWithName:(NSString *)name key:(NSString *)key min:(CGFloat)min max:(CGFloat)max default:(CGFloat)def {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                          target:self
                                                             set:@selector(setPreferenceValue:specifier:)
                                                             get:@selector(readPreferenceValue:)
                                                          detail:nil
                                                            cell:PSSliderCell
                                                            edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:@(min) forKey:@"minimumValue"];
    [spec setProperty:@(max) forKey:@"maximumValue"];
    [spec setProperty:@(def) forKey:@"default"];
    return spec;
}

- (PSSpecifier *)linkListSpecifierWithName:(NSString *)name key:(NSString *)key titles:(NSArray *)titles values:(NSArray *)values {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                          target:self
                                                             set:@selector(setPreferenceValue:specifier:)
                                                             get:@selector(readPreferenceValue:)
                                                          detail:NSClassFromString(@"PSListItemsController")
                                                            cell:PSLinkCell
                                                            edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:titles forKey:@"titles"];
    [spec setProperty:values forKey:@"values"];
    [spec setProperty:@(0) forKey:@"default"];
    return spec;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) return;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) return nil;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    id value = [defaults objectForKey:key];
    if (value == nil) {
        value = [specifier propertyForKey:@"default"];
    }
    return value;
}

- (void)resetSettings {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认重置"
                                                                     message:@"将恢复所有设置为默认值，确定吗？"
                                                              preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"重置" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
        [defaults removeObjectForKey:@"enabled"];
        [defaults removeObjectForKey:@"animationType"];
        [defaults removeObjectForKey:@"glowColor"];
        [defaults removeObjectForKey:@"glowSize"];
        [defaults removeObjectForKey:@"glowDuration"];
        [defaults removeObjectForKey:@"glowOpacity"];
        [defaults removeObjectForKey:@"followFinger"];
        [defaults removeObjectForKey:@"wechatEnabled"];
        [defaults removeObjectForKey:@"baiduEnabled"];
        [defaults removeObjectForKey:@"sogouEnabled"];
        [defaults synchronize];
        _specifiers = nil;
        [self reloadSpecifiers];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
