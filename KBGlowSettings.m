#import "KBGlowSettings.h"
#import <CoreFoundation/CoreFoundation.h>

static NSString *const kAppID = @"com.mowang.kbglow";
static CFStringRef const kNotify = CFSTR("com.mowang.kbglow.settingsChanged");

@implementation KBGlowSettings

+ (id)objectForKey:(NSString *)key {
    if (!key) return nil;
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)kAppID);
    if (value) {
        return (__bridge_transfer id)value;
    }
    return nil;
}

+ (void)setObject:(id)value forKey:(NSString *)key {
    if (!key) return;
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, (__bridge CFStringRef)kAppID);
}

+ (BOOL)boolForKey:(NSString *)key default:(BOOL)def {
    if (!key) return def;
    Boolean exists = false;
    Boolean value = CFPreferencesGetAppBooleanValue((__bridge CFStringRef)key, (__bridge CFStringRef)kAppID, &exists);
    return exists ? (BOOL)value : def;
}

+ (void)setBool:(BOOL)value forKey:(NSString *)key {
    if (!key) return;
    CFPreferencesSetAppValue((__bridge CFStringRef)key, value ? kCFBooleanTrue : kCFBooleanFalse, (__bridge CFStringRef)kAppID);
}

+ (double)doubleForKey:(NSString *)key default:(double)def {
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value doubleValue];
    }
    return def;
}

+ (void)setDouble:(double)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

+ (void)removeObjectForKey:(NSString *)key {
    if (!key) return;
    CFPreferencesSetAppValue((__bridge CFStringRef)key, NULL, (__bridge CFStringRef)kAppID);
}

+ (void)synchronize {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kAppID);
}

+ (void)notifyChanged {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kNotify, NULL, NULL, true);
}

@end
