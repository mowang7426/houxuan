#import <UIKit/UIKit.h>

static NSString * const RKPrefsPath = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";

@interface RKBRootListController : UITableViewController
@property(nonatomic,strong) UISwitch *enabledSwitch;
@property(nonatomic,strong) UISwitch *rippleSwitch;
@property(nonatomic,strong) UISwitch *nativeSwitch;
@property(nonatomic,strong) UISwitch *wechatSwitch;
@property(nonatomic,strong) UISlider *speedSlider;
@property(nonatomic,strong) UISlider *brightnessSlider;
@property(nonatomic,strong) UISlider *opacitySlider;
@end

@implementation RKBRootListController

- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"彩虹键盘光效";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    [self loadValues];
}

- (NSMutableDictionary *)values {
    return [NSMutableDictionary dictionaryWithContentsOfFile:RKPrefsPath] ?: [NSMutableDictionary dictionary];
}
- (void)loadValues {
    NSDictionary *d = [self values];
    _enabledSwitch = [self sw:d[@"Enabled"] ? [d[@"Enabled"] boolValue] : YES];
    _rippleSwitch = [self sw:d[@"RippleEnabled"] ? [d[@"RippleEnabled"] boolValue] : YES];
    _nativeSwitch = [self sw:d[@"NativeKeyboard"] ? [d[@"NativeKeyboard"] boolValue] : YES];
    _wechatSwitch = [self sw:d[@"WeChatKeyboard"] ? [d[@"WeChatKeyboard"] boolValue] : YES];
    _speedSlider = [self slider:d[@"Speed"] ? [d[@"Speed"] floatValue] : .45];
    _brightnessSlider = [self slider:d[@"Brightness"] ? [d[@"Brightness"] floatValue] : .85];
    _opacitySlider = [self slider:d[@"Opacity"] ? [d[@"Opacity"] floatValue] : .72];
}
- (UISwitch *)sw:(BOOL)on { UISwitch *s = [UISwitch new]; s.on = on; [s addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged]; return s; }
- (UISlider *)slider:(float)value { UISlider *s = [UISlider new]; s.minimumValue=.05; s.maximumValue=1; s.value=value; [s addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged]; return s; }
- (void)save:(NSString *)key value:(id)value { NSMutableDictionary *d = [self values]; d[key] = value; [d writeToFile:RKPrefsPath atomically:YES]; CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.minis.rainbowkeyboard.changed"), NULL, NULL, YES); }
- (void)changed:(id)sender {
    if (sender == _enabledSwitch) [self save:@"Enabled" value:@(_enabledSwitch.on)];
    else if (sender == _rippleSwitch) [self save:@"RippleEnabled" value:@(_rippleSwitch.on)];
    else if (sender == _nativeSwitch) [self save:@"NativeKeyboard" value:@(_nativeSwitch.on)];
    else if (sender == _wechatSwitch) [self save:@"WeChatKeyboard" value:@(_wechatSwitch.on)];
    else if (sender == _speedSlider) [self save:@"Speed" value:@(_speedSlider.value)];
    else if (sender == _brightnessSlider) [self save:@"Brightness" value:@(_brightnessSlider.value)];
    else if (sender == _opacitySlider) [self save:@"Opacity" value:@(_opacitySlider.value)];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 3; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return s == 0 ? 1 : (s == 1 ? 3 : 4); }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return @[@"总开关", @"光效参数", @"输入法"][s]; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    c.selectionStyle = UITableViewCellSelectionStyleNone;
    if (p.section == 0) { c.textLabel.text=@"启用彩虹键盘光效"; c.accessoryView=_enabledSwitch; }
    if (p.section == 1) { NSArray *a=@[@"动画速度",@"光效亮度",@"光效透明度"]; c.textLabel.text=a[p.row]; c.accessoryView=@[_speedSlider,_brightnessSlider,_opacitySlider][p.row]; }
    if (p.section == 2) { NSArray *a=@[@"按键扩散波纹",@"原生键盘",@"微信输入法",@"恢复默认设置"]; c.textLabel.text=a[p.row]; if(p.row<3)c.accessoryView=@[_rippleSwitch,_nativeSwitch,_wechatSwitch][p.row]; else c.textLabel.textColor=UIColor.systemRedColor; }
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p { if(p.section==2 && p.row==3){ [[NSFileManager defaultManager] removeItemAtPath:RKPrefsPath error:nil]; [self loadValues]; [self.tableView reloadData]; } }
@end
