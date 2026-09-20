#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
static NSString * const RKPath = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";
@interface RKBRootListController : PSListController
@end
@implementation RKBRootListController
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"RainbowKeyboard" target:self];
    return _specifiers;
}
- (void)viewDidLoad { [super viewDidLoad]; self.title = @"彩虹键盘光效"; }
- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSDictionary *values = [NSDictionary dictionaryWithContentsOfFile:RKPath];
    return (key ? values[key] : nil) ?: [specifier propertyForKey:@"default"];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key || !value) return;
    NSMutableDictionary *values = [[NSDictionary dictionaryWithContentsOfFile:RKPath] mutableCopy] ?: [NSMutableDictionary dictionary];
    values[key] = value;
    if ([key isEqualToString:@"Preset"]) {
        NSInteger preset = [value integerValue];
        NSArray *options = @[
            @{@"Opacity":@.4,@"Brightness":@.8,@"Duration":@.6,@"Spread":@1.5,@"Softness":@10,@"CoreStrength":@.3,@"MaxEffects":@3},
            @{@"Opacity":@.75,@"Brightness":@1,@"Duration":@.55,@"Spread":@2.2,@"Softness":@8,@"CoreStrength":@.65,@"MaxEffects":@4},
            @{@"Opacity":@.6,@"Brightness":@.95,@"Duration":@.25,@"Spread":@1.3,@"Softness":@5,@"CoreStrength":@.6,@"MaxEffects":@3},
            @{@"Opacity":@.65,@"Brightness":@.95,@"Duration":@.55,@"Spread":@2,@"Softness":@8,@"CoreStrength":@.5,@"MaxEffects":@4}
        ];
        if (preset >= 0 && preset < (NSInteger)options.count) {
            [values addEntriesFromDictionary:options[preset]];
            values[@"ColorMode"] = @0;
            values[@"BackgroundFeedback"] = @YES;
            values[@"BackgroundStrength"] = @.18;
            values[@"BackgroundDuration"] = @.4;
        }
    } else values[@"Preset"] = @(-1);
    if (![values writeToFile:RKPath atomically:YES]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"保存失败" message:@"配置文件未写入，请检查偏好设置目录权限。" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [self reloadSpecifiers];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.minis.rainbowkeyboard.changed"), NULL, NULL, YES);
}
@end
