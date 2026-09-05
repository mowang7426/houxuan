#import <CoreFoundation/CoreFoundation.h>
#import <Preferences/Preferences.h>
#import "AnimationPickerController.h"
static NSString *const suite=@"com.mowang.kbglow"; static CFStringRef const note=CFSTR("com.mowang.kbglow.settingsChanged");
@implementation AnimationPickerController
- (NSArray *)specifiers { if (!_specifiers) {
 NSMutableArray *a=[NSMutableArray array]; [a addObject:[PSSpecifier groupSpecifierWithName:@"选择一种动画"]];
 NSArray *names=@[@"涟漪扩散",@"常驻光晕",@"粒子爆发"]; for (NSInteger i=0;i<3;i++){ PSSpecifier *s=[PSSpecifier preferenceSpecifierNamed:names[i] target:self set:@selector(setAnimation:specifier:) get:@selector(getAnimation:) detail:nil cell:PSSwitchCell edit:nil]; [s setProperty:@(i) forKey:@"animationValue"]; [a addObject:s]; }
 [a addObject:[PSSpecifier groupSpecifierWithName:@"说明"]]; [a addObject:[PSSpecifier preferenceSpecifierNamed:@"每次只能启用一种动画，修改后立即同步到键盘进程。" target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil]]; _specifiers=a; } return _specifiers; }
- (id)getAnimation:(PSSpecifier *)s { NSInteger v=[[s propertyForKey:@"animationValue"] integerValue]; NSUserDefaults*d=[[NSUserDefaults alloc]initWithSuiteName:suite]; return @([d integerForKey:@"animationType"]==v); }
- (void)setAnimation:(id)value specifier:(PSSpecifier *)s { if (![value boolValue]) return; NSInteger v=[[s propertyForKey:@"animationValue"] integerValue]; NSUserDefaults*d=[[NSUserDefaults alloc]initWithSuiteName:suite]; [d setInteger:v forKey:@"animationType"]; [d synchronize]; CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),note,NULL,NULL,true); [self reloadSpecifiers]; }
@end
