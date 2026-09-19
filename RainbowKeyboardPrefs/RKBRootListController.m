#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface RKBRootListController : PSListController
@end

@implementation RKBRootListController
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"RainbowKeyboard" target:self];
    return _specifiers;
}
- (id)readPreferenceValue:(PSSpecifier *)s {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist"] ?: @{};
    return d[s.properties[@"key"]] ?: s.properties[@"default"];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)s {
    NSString *p = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:p] ?: [NSMutableDictionary dictionary];
    d[s.properties[@"key"]] = value; [d writeToFile:p atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.minis.rainbowkeyboard.changed"), NULL, NULL, YES);
}
@end
