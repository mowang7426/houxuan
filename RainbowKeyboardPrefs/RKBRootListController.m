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
    BOOL transportPublished = RKPublishColorState(values);
    CFStringRef domain = CFSTR("com.minis.rainbowkeyboard");
    for (NSString *key in values) {
        id value = values[key];
        CFPreferencesSetAppValue((__bridge CFStringRef)key,
            (__bridge CFPropertyListRef)value, domain);
    }
    NSString *marker = NSUUID.UUID.UUIDString;
    CFPreferencesSetAppValue(CFSTR("RKProbeMarker"), (__bridge CFStringRef)marker, domain);
    BOOL synced = CFPreferencesAppSynchronize(domain);
    NSMutableDictionary *readback = [NSMutableDictionary dictionary];
    for (NSString *key in @[@"RKProbeMarker", @"CandidateGradient", @"CandidateNative", @"CandidateWeType"]) {
        id value = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key, domain));
        readback[key] = value ?: @"unset";
    }
    NSDictionary *report = @{@"version":@5, @"transportPublished":@(transportPublished), @"syncReturned":@(synced),
        @"writtenMarker":marker, @"appReadback":readback,
        @"date":[NSDate date]};
    NSString *path = @"/var/mobile/Library/Preferences/RainbowKeyboard-settings-probe.plist";
    if (![report writeToFile:path atomically:YES])
        [report writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"RainbowKeyboard-settings-probe.plist"] atomically:YES];
    return synced;
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
    NSDictionary *values = [NSDictionary dictionaryWithContentsOfFile:RKPath];
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
    BOOL fileSaved = [values writeToFile:RKPath atomically:YES];
    BOOL domainSaved = RKSyncPreferences(values);
    if (!fileSaved && !domainSaved) {
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
    NSDictionary *values = [NSDictionary dictionaryWithContentsOfFile:RKPath];
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
    NSMutableDictionary *values = [[NSDictionary dictionaryWithContentsOfFile:RKPath] mutableCopy] ?: [NSMutableDictionary dictionary];
    values[key] = @[@(r),@(g),@(b)];
    BOOL fileSaved = [values writeToFile:RKPath atomically:YES];
    BOOL domainSaved = RKSyncPreferences(values);
    BOOL saved = fileSaved || domainSaved;
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
