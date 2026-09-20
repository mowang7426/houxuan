#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "../RKCandidateTransport.h"
static NSString * const RKPath = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";
static NSDictionary *RKReadPreferences(void) {
    NSDictionary *values = [NSDictionary dictionaryWithContentsOfFile:RKPath];
    if (values) return values;
    CFDictionaryRef stored = CFPreferencesCopyMultiple(NULL, CFSTR("com.minis.rainbowkeyboard"),
        kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    return CFBridgingRelease(stored) ?: @{};
}
static BOOL RKSyncPreferences(NSDictionary *values) {
    // We persist only via -writeToFile: on the plist below. Writing through
    // CFPreferences here is dangerous: CFPreferencesAppSynchronize flushes the
    // whole in-memory dictionary back to the SAME plist file, and when the
    // Preferences process's in-memory view is incomplete it overwrites the
    // on-disk config with a partial one, which makes every setting jump back
    // to its default. The keyboard process reads the plist file directly, so
    // CFPreferences is not needed; we only re-publish the notify color state.
    return RKPublishColorState(values);
}
@interface RKBRootListController : PSListController <UIColorPickerViewControllerDelegate>
@property(nonatomic,copy) NSString *editingColorKey;
@end
@implementation RKBRootListController
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"RainbowKeyboard" target:self];
    return _specifiers;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"彩虹键盘光效";
    NSDictionary *values = RKReadPreferences();
    if (values) RKSyncPreferences(values);
}
- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSDictionary *values = RKReadPreferences();
    return (key ? values[key] : nil) ?: [specifier propertyForKey:@"default"];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key || !value) return;
    NSMutableDictionary *values = [RKReadPreferences() mutableCopy];
    values[key] = value;
    if ([key isEqualToString:@"Preset"]) {
        NSInteger preset = [value integerValue];
        NSArray *options = @[
            @{@"Opacity":@.4,@"Brightness":@.8,@"NeonSaturation":@.4,@"Duration":@.6,@"Spread":@1.5,@"Softness":@10,@"CoreStrength":@.3,@"MaxEffects":@3},
            @{@"Opacity":@.75,@"Brightness":@1,@"NeonSaturation":@1,@"Duration":@.55,@"Spread":@2.2,@"Softness":@8,@"CoreStrength":@.65,@"MaxEffects":@4},
            @{@"Opacity":@.6,@"Brightness":@.95,@"NeonSaturation":@.72,@"Duration":@.25,@"Spread":@1.3,@"Softness":@5,@"CoreStrength":@.6,@"MaxEffects":@3},
            @{@"Opacity":@.65,@"Brightness":@.95,@"NeonSaturation":@.72,@"Duration":@.55,@"Spread":@2,@"Softness":@8,@"CoreStrength":@.5,@"MaxEffects":@4}
        ];
        if (preset >= 0 && preset < (NSInteger)options.count) {
            [values addEntriesFromDictionary:options[preset]];
            values[@"EffectStyle"] = @0;
            values[@"AmbientGlow"] = @YES;
            values[@"AmbientStrength"] = @.85;
            values[@"PureBlackKeyboard"] = @YES;
            values[@"ColorMode"] = @0;
            values[@"BackgroundFeedback"] = @YES;
            values[@"BackgroundStrength"] = @.18;
            values[@"BackgroundDuration"] = @.4;
        }
    } else values[@"Preset"] = @(-1);
    BOOL fileSaved = [values writeToFile:RKPath atomically:YES];
    BOOL notifyPublished = RKSyncPreferences(values);
    if (!fileSaved && !notifyPublished) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"保存失败" message:@"配置文件未写入，请检查偏好设置目录权限。" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [self reloadSpecifiers];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.minis.rainbowkeyboard.changed"), NULL, NULL, YES);
}

- (void)chooseCandidateStart { [self openCandidatePicker:@"CandidateStart"]; }
- (void)chooseCandidateEnd { [self openCandidatePicker:@"CandidateEnd"]; }
- (void)openCandidatePicker:(NSString *)key {
    self.editingColorKey = key;
    UIColorPickerViewController *picker = [UIColorPickerViewController new];
    picker.delegate = self;
    picker.supportsAlpha = NO;
    picker.title = [key isEqualToString:@"CandidateStart"] ? @"候选词起始颜色" : @"候选词结束颜色";
    NSDictionary *values = RKReadPreferences();
    id rgb = values[key];
    if ([rgb isKindOfClass:NSArray.class] && [rgb count] == 3 &&
        [rgb[0] isKindOfClass:NSNumber.class] && [rgb[1] isKindOfClass:NSNumber.class] && [rgb[2] isKindOfClass:NSNumber.class]) {
        picker.selectedColor = [UIColor colorWithRed:[rgb[0] doubleValue] green:[rgb[1] doubleValue] blue:[rgb[2] doubleValue] alpha:1];
    } else picker.selectedColor = [key isEqualToString:@"CandidateStart"] ?
        [UIColor colorWithRed:0 green:.65 blue:1 alpha:1] : [UIColor colorWithRed:.85 green:.15 blue:1 alpha:1];
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)picker {
    CGFloat r=0,g=0,b=0,a=1;
    NSString *key = self.editingColorKey;
    if (!key || ![picker.selectedColor getRed:&r green:&g blue:&b alpha:&a]) return;
    NSMutableDictionary *values = [RKReadPreferences() mutableCopy];
    values[key] = @[@(r),@(g),@(b)];
    BOOL fileSaved = [values writeToFile:RKPath atomically:YES];
    BOOL notifyPublished = RKSyncPreferences(values);
    BOOL saved = fileSaved || notifyPublished;
    self.editingColorKey = nil;
    [picker dismissViewControllerAnimated:YES completion:^{
        if (!saved) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"颜色保存失败" message:@"请检查配置文件权限。" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),CFSTR("com.minis.rainbowkeyboard.changed"),NULL,NULL,YES);
        }
    }];
}
@end
