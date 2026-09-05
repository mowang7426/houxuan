#import <Foundation/Foundation.h>

@interface KBGlowSettings : NSObject
+ (id)objectForKey:(NSString *)key;
+ (void)setObject:(id)value forKey:(NSString *)key;
+ (BOOL)boolForKey:(NSString *)key default:(BOOL)def;
+ (void)setBool:(BOOL)value forKey:(NSString *)key;
+ (double)doubleForKey:(NSString *)key default:(double)def;
+ (void)setDouble:(double)value forKey:(NSString *)key;
+ (void)removeObjectForKey:(NSString *)key;
+ (void)synchronize;
+ (void)notifyChanged;
@end
