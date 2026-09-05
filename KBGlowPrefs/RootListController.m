#import <Preferences/Preferences.h>
#import <CoreFoundation/CoreFoundation.h>
#import "RootListController.h"
#import "ColorPickerController.h"
#import "AnimationPickerController.h"

static NSString *const suite = @"com.mowang.kbglow";
static CFStringRef const note = CFSTR("com.mowang.kbglow.settingsChanged");

static void KBGlowSyncAndNotify(void) {
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:suite];
    [d synchronize];
    CFPreferencesAppSynchronize((CFStringRef)suite);

    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        note, NULL, NULL, true
    );
}

@implementation RootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *a = [NSMutableArray array];

        [a addObject:[PSSpecifier groupSpecifierWithName:@"总开关"]];
        [a addObject:[self sw:@"启用 KBGlow" key:@"enabled" def:YES]];

        [a addObject:[PSSpecifier groupSpecifierWithName:@"启用键盘"]];
        [a addObject:[self sw:@"微信输入法" key:@"wechatEnabled" def:YES]];
        [a addObject:[self sw:@"百度输入法" key:@"baiduEnabled" def:YES]];
        [a addObject:[self sw:@"搜狗输入法" key:@"sogouEnabled" def:YES]];

        [a addObject:[PSSpecifier groupSpecifierWithName:@"发光效果"]];

        PSSpecifier *x = [PSSpecifier preferenceSpecifierNamed:@"动画类型"
                                                     target:nil set:nil get:nil
                                                     detail:AnimationPickerController.class
                                                       cell:PSLinkCell edit:nil];
        [a addObject:x];

        PSSpecifier *c = [PSSpecifier preferenceSpecifierNamed:@"发光颜色"
                                                     target:nil set:nil get:nil
                                                     detail:ColorPickerController.class
                                                       cell:PSLinkCell edit:nil];
        [a addObject:c];

        [a addObject:[self slider:@"发光大小" key:@"glowSize" min:15 max:120 def:55]];
        [a addObject:[self slider:@"动画时长" key:@"glowDuration" min:.1 max:1.5 def:.45]];
        [a addObject:[self slider:@"发光强度" key:@"glowOpacity" min:.1 max:1 def:.75]];
        [a addObject:[self sw:@"跟随手指位置" key:@"followFinger" def:YES]];

        [a addObject:[PSSpecifier groupSpecifierWithName:@"说明"]];
        [a addObject:[PSSpecifier preferenceSpecifierNamed:@"修改后会立即同步到键盘进程。"
                                                     target:nil set:nil get:nil detail:nil
                                                       cell:PSStaticTextCell edit:nil]];

        _specifiers = a;
    }
    return _specifiers;
}

- (PSSpecifier *)sw:(NSString *)name key:(NSString *)key def:(BOOL)value {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
                                                     target:self
                                                        set:@selector(setV:specifier:)
                                                        get:@selector(getV:)
                                                     detail:nil
                                                       cell:PSSwitchCell edit:nil];
    [s setProperty:key forKey:@"key"];
    [s setProperty:@(value) forKey:@"default"];
    return s;
}

- (PSSpecifier *)slider:(NSString *)name key:(NSString *)key
                    min:(CGFloat)min max:(CGFloat)max def:(CGFloat)def {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
                                                     target:self
                                                        set:@selector(setV:specifier:)
                                                        get:@selector(getV:)
                                                     detail:nil
                                                       cell:PSSliderCell edit:nil];
    [s setProperty:key forKey:@"key"];
    [s setProperty:@(min) forKey:@"minimumValue"];
    [s setProperty:@(max) forKey:@"maximumValue"];
    [s setProperty:@(def) forKey:@"default"];
    [s setProperty:@YES forKey:@"isContinuous"];
    return s;
}

- (void)setV:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:suite];

    if ([[specifier propertyForKey:@"default"] isKindOfClass:NSNumber.class] &&
        [specifier propertyForKey:@"minimumValue"]) {
        [d setDouble:[value doubleValue] forKey:key];
    } else {
        [d setBool:[value boolValue] forKey:key];
    }

    KBGlowSyncAndNotify();
}

- (id)getV:(PSSpecifier *)specifier {
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:suite];
    NSString *key = [specifier propertyForKey:@"key"];
    id v = [d objectForKey:key];
    return v ?: [specifier propertyForKey:@"default"];
}

@end
