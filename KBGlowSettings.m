#import "KBGlowSettings.h"

static NSString *const kSettingsPath = @"/var/mobile/Library/Preferences/com.mowang.kbglow.plist";
static CFStringRef const kNotify = CFSTR("com.mowang.kbglow.settingsChanged");

@implementation KBGlowSettings

+ (NSMutableDictionary *)loadDict {
    @try {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:kSettingsPath];
        if (!dict) dict = [NSMutableDictionary dictionary];
        return dict;
    } @catch (NSException *e) {
        return [NSMutableDictionary dictionary];
    }
}

+ (void)saveDict:(NSDictionary *)dict {
    @try {
        [dict writeToFile:kSettingsPath atomically:YES];
    } @catch (NSException *e) {
    }
}

+ (id)objectForKey:(NSString *)key {
    if (!key) return nil;
    @try {
        NSDictionary *dict = [self loadDict];
        return dict[key];
    } @catch (NSException *e) {
        return nil;
    }
}

+ (void)setObject:(id)value forKey:(NSString *)key {
    if (!key) return;
    @try {
        NSMutableDictionary *dict = [self loadDict];
        if (value) {
            dict[key] = value;
        } else {
            [dict removeObjectForKey:key];
        }
        [self saveDict:dict];
    } @catch (NSException *e) {
    }
}

+ (BOOL)boolForKey:(NSString *)key default:(BOOL)def {
    @try {
        id value = [self objectForKey:key];
        if ([value isKindOfClass:[NSNumber class]]) {
            return [value boolValue];
        }
    } @catch (NSException *e) {
    }
    return def;
}

+ (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

+ (double)doubleForKey:(NSString *)key default:(double)def {
    @try {
        id value = [self objectForKey:key];
        if ([value isKindOfClass:[NSNumber class]]) {
            return [value doubleValue];
        }
    } @catch (NSException *e) {
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
    @try {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kNotify, NULL, NULL, true);
    } @catch (NSException *e) {
    }
}

@end
