#import "KBGlowSettings.h"

static NSString *const kSettingsPath = @"/var/mobile/Library/Preferences/com.mowang.kbglow.plist";
static CFStringRef const kNotify = CFSTR("com.mowang.kbglow.settingsChanged");

@implementation KBGlowSettings

+ (NSMutableDictionary *)loadDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:kSettingsPath];
    if (!dict) dict = [NSMutableDictionary dictionary];
    return dict;
}

+ (void)saveDict:(NSDictionary *)dict {
    [dict writeToFile:kSettingsPath atomically:YES];
}

+ (id)objectForKey:(NSString *)key {
    if (!key) return nil;
    @synchronized (self) {
        NSDictionary *dict = [self loadDict];
        return dict[key];
    }
}

+ (void)setObject:(id)value forKey:(NSString *)key {
    if (!key) return;
    @synchronized (self) {
        NSMutableDictionary *dict = [self loadDict];
        if (value) {
            dict[key] = value;
        } else {
            [dict removeObjectForKey:key];
        }
        [self saveDict:dict];
    }
}

+ (BOOL)boolForKey:(NSString *)key default:(BOOL)def {
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    return def;
}

+ (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
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
    [self setObject:nil forKey:key];
}

+ (void)synchronize {
}

+ (void)notifyChanged {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kNotify, NULL, NULL, true);
}

@end
