#import <UIKit/UIKit.h>
// Preferences.framework is private and does not need to be linked into the
// PreferenceBundle. PreferenceLoader/Preferences.app supplies these classes at runtime.
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface RKBRootListController : PSListController
@end

@implementation RKBRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"RainbowKeyboard" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"彩虹键盘光效";
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];
    NSString *notification = [specifier propertyForKey:@"PostNotification"];
    if (notification.length) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                              (__bridge CFStringRef)notification,
                                              NULL, NULL, YES);
    }
}

@end
