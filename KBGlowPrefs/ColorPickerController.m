#import <math.h>
#import <CoreFoundation/CoreFoundation.h>
#import "ColorPickerController.h"
static NSString *const suite=@"com.mowang.kbglow"; static CFStringRef const note=CFSTR("com.mowang.kbglow.settingsChanged");
@implementation ColorPickerController
- (NSArray *)specifiers { if (!_specifiers) {
 NSMutableArray*a=[NSMutableArray array]; [a addObject:[PSSpecifier groupSpecifierWithName:@"选择颜色"]];
 NSArray *items=@[@[@"冰蓝",@0,@0.55,@1],@[@"红色",@1,@0.08,@0.08],@[@"绿色",@0.1,@0.95,@0.25],@[@"紫色",@0.65,@0.2,@1],@[@"橙色",@1,@0.5,@0],@[@"粉色",@1,@0.2,@0.65],@[@"白色",@1,@1,@1]];
 for(NSArray*x in items){PSSpecifier*s=[PSSpecifier preferenceSpecifierNamed:x[0] target:self set:@selector(setColor:specifier:) get:@selector(getColor:) detail:nil cell:PSSwitchCell edit:nil]; [s setProperty:x forKey:@"rgb"]; [a addObject:s];}
 [a addObject:[PSSpecifier groupSpecifierWithName:@"自定义 RGB"]];
 [a addObject:[self slider:@"红色 R" key:@"customR"]]; [a addObject:[self slider:@"绿色 G" key:@"customG"]]; [a addObject:[self slider:@"蓝色 B" key:@"customB"]];
 PSSpecifier*b=[PSSpecifier preferenceSpecifierNamed:@"应用自定义颜色" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil]; b.buttonAction=@selector(applyCustom:); [a addObject:b];
 [a addObject:[PSSpecifier preferenceSpecifierNamed:@"三个滑条就是 RGB 三原色，范围 0–1。调整后点击“应用自定义颜色”。" target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil]]; _specifiers=a;} return _specifiers; }
- (PSSpecifier*)slider:(NSString*)name key:(NSString*)key { PSSpecifier*s=[PSSpecifier preferenceSpecifierNamed:name target:self set:@selector(setValue:specifier:) get:@selector(getValue:) detail:nil cell:PSSliderCell edit:nil]; [s setProperty:key forKey:@"key"]; [s setProperty:@0 forKey:@"minimumValue"]; [s setProperty:@1 forKey:@"maximumValue"]; [s setProperty:@YES forKey:@"isContinuous"]; return s; }
- (id)getColor:(PSSpecifier*)s { NSArray*x=[s propertyForKey:@"rgb"]; NSUserDefaults*d=[[NSUserDefaults alloc]initWithSuiteName:suite]; NSArray*c=[d objectForKey:@"colorRGB"]; return ([c isEqual:x]|| (c.count>=3&&fabs([c[0]doubleValue]-[x[1]doubleValue])<.001&&fabs([c[1]doubleValue]-[x[2]doubleValue])<.001&&fabs([c[2]doubleValue]-[x[3]doubleValue])<.001))?@YES:@NO; }
- (void)setColor:(id)value specifier:(PSSpecifier*)s { if(![value boolValue])return; NSArray*x=[s propertyForKey:@"rgb"]; NSUserDefaults*d=[[NSUserDefaults alloc]initWithSuiteName:suite]; [d setObject:@[x[1],x[2],x[3]] forKey:@"colorRGB"]; [d synchronize]; CFPreferencesAppSynchronize((__bridge CFStringRef)suite); CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),note,NULL,NULL,true); [self reloadSpecifiers]; }
- (id)getValue:(PSSpecifier*)s { NSUserDefaults*d=[[NSUserDefaults alloc]initWithSuiteName:suite]; id v=[d objectForKey:[s propertyForKey:@"key"]]; return v?:@0.0; }
- (void)setValue:(id)v specifier:(PSSpecifier*)s { NSUserDefaults*d=[[NSUserDefaults alloc]initWithSuiteName:suite]; [d setObject:v forKey:[s propertyForKey:@"key"]]; [d synchronize]; }
- (void)applyCustom:(PSSpecifier*)s { NSUserDefaults*d=[[NSUserDefaults alloc]initWithSuiteName:suite]; CGFloat r=[d doubleForKey:@"customR"],g=[d doubleForKey:@"customG"],b=[d doubleForKey:@"customB"]; [d setObject:@[@(r),@(g),@(b)] forKey:@"colorRGB"]; [d synchronize]; CFPreferencesAppSynchronize((__bridge CFStringRef)suite); CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),note,NULL,NULL,true); }
@end
