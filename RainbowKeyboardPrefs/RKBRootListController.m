#import <UIKit/UIKit.h>

// PreferenceLoader/Preferences.framework 提供 PSListController。
// 这里仅声明本项目实际使用的 API，避免依赖本地 SDK 的私有 Preferences 头文件。
@interface PSListController : UITableViewController
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
@end

static NSString * const RKPrefsPath = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";

@interface RKBRootListController : PSListController
@end

@implementation RKBRootListController

- (NSArray *)specifiers {
    // 使用标准 PreferenceBundle 的 Root plist 方式，让 Preferences.app 自己创建
    // PSSwitchCell / PSSliderCell 等控件。这样也避免手工 UITableView 与
    // PSListController 内部 specifier 生命周期不一致的问题。
    NSArray *specifiers = [self loadSpecifiersFromPlistName:@"RainbowKeyboard" target:self];
    return specifiers ?: @[];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"彩虹键盘光效";
}

// 保留一个简单的默认配置入口，实际开关/滑块由 RainbowKeyboard.plist 负责保存。
// Tweak 读取同一个 plist，因此无需在这里重复实现控件。
- (void)setPreferenceValue:(id)value forKey:(NSString *)key {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:RKPrefsPath];
    if (!prefs) prefs = [NSMutableDictionary dictionary];
    if (value) prefs[key] = value;
    else [prefs removeObjectForKey:key];
    [prefs writeToFile:RKPrefsPath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                          CFSTR("com.minis.rainbowkeyboard.changed"),
                                          NULL, NULL, YES);
}

@end
