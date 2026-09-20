#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

static NSString * const RKPrefsPath = @"/var/mobile/Library/Preferences/com.minis.rainbowkeyboard.plist";
static NSString * const RKChangedNotification = @"com.minis.rainbowkeyboard.changed";

@interface RKBRootListController : PSListController
@property(nonatomic,strong) UISwitch *enabledSwitch;
@property(nonatomic,strong) UISegmentedControl *modeControl;
@property(nonatomic,strong) UISlider *speedSlider;
@property(nonatomic,strong) UISlider *brightnessSlider;
@property(nonatomic,strong) UISlider *opacitySlider;
@property(nonatomic,strong) UISwitch *rippleSwitch;
@property(nonatomic,strong) UISwitch *nativeSwitch;
@property(nonatomic,strong) UISwitch *wechatSwitch;
@end

@implementation RKBRootListController

// Do not load a Preferences specifier plist. Relaxin's PreferenceLoader can
// show a generic error for unsupported PS*Cell specifiers on iOS 17.
- (NSArray *)specifiers { return @[]; }

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) self.title = @"彩虹键盘光效";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"彩虹键盘光效";
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self buildControls];
}

- (NSMutableDictionary *)values {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:RKPrefsPath];
    return d ?: [NSMutableDictionary dictionary];
}

- (BOOL)boolValue:(NSDictionary *)d key:(NSString *)key fallback:(BOOL)value {
    return d[key] ? [d[key] boolValue] : value;
}

- (float)floatValue:(NSDictionary *)d key:(NSString *)key fallback:(float)value {
    return d[key] ? [d[key] floatValue] : value;
}

- (void)buildControls {
    NSDictionary *d = [self values];
    _enabledSwitch = [self switchWithValue:[self boolValue:d key:@"Enabled" fallback:YES]];
    _rippleSwitch = [self switchWithValue:[self boolValue:d key:@"RippleEnabled" fallback:YES]];
    _nativeSwitch = [self switchWithValue:[self boolValue:d key:@"NativeKeyboard" fallback:YES]];
    _wechatSwitch = [self switchWithValue:[self boolValue:d key:@"WeChatKeyboard" fallback:YES]];

    _modeControl = [[UISegmentedControl alloc] initWithItems:@[@"动态", @"静态", @"呼吸"]];
    _modeControl.selectedSegmentIndex = MIN(2, MAX(0, (NSInteger)[self floatValue:d key:@"Mode" fallback:0]));
    [_modeControl addTarget:self action:@selector(controlChanged:) forControlEvents:UIControlEventValueChanged];

    _speedSlider = [self sliderWithValue:[self floatValue:d key:@"Speed" fallback:.45]];
    _brightnessSlider = [self sliderWithValue:[self floatValue:d key:@"Brightness" fallback:.85]];
    _opacitySlider = [self sliderWithValue:[self floatValue:d key:@"Opacity" fallback:.72]];
}

- (UISwitch *)switchWithValue:(BOOL)value {
    UISwitch *s = [UISwitch new];
    s.on = value;
    [s addTarget:self action:@selector(controlChanged:) forControlEvents:UIControlEventValueChanged];
    return s;
}

- (UISlider *)sliderWithValue:(float)value {
    UISlider *s = [UISlider new];
    s.minimumValue = .05f;
    s.maximumValue = 1.0f;
    s.value = MIN(1.0f, MAX(.05f, value));
    [s addTarget:self action:@selector(controlChanged:) forControlEvents:UIControlEventValueChanged];
    return s;
}

- (void)saveKey:(NSString *)key value:(id)value {
    NSMutableDictionary *d = [self values];
    d[key] = value;
    [d writeToFile:RKPrefsPath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)RKChangedNotification, NULL, NULL, YES);
}

- (void)controlChanged:(id)sender {
    if (sender == _enabledSwitch) [self saveKey:@"Enabled" value:@(_enabledSwitch.on)];
    else if (sender == _modeControl) [self saveKey:@"Mode" value:@(_modeControl.selectedSegmentIndex)];
    else if (sender == _speedSlider) [self saveKey:@"Speed" value:@(_speedSlider.value)];
    else if (sender == _brightnessSlider) [self saveKey:@"Brightness" value:@(_brightnessSlider.value)];
    else if (sender == _opacitySlider) [self saveKey:@"Opacity" value:@(_opacitySlider.value)];
    else if (sender == _rippleSwitch) [self saveKey:@"RippleEnabled" value:@(_rippleSwitch.on)];
    else if (sender == _nativeSwitch) [self saveKey:@"NativeKeyboard" value:@(_nativeSwitch.on)];
    else if (sender == _wechatSwitch) [self saveKey:@"WeChatKeyboard" value:@(_wechatSwitch.on)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : (section == 1 ? 4 : 3);
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @[@"总开关", @"光效参数", @"输入法与波纹"][section];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0) {
        cell.textLabel.text = @"启用彩虹键盘光效";
        cell.accessoryView = _enabledSwitch;
    } else if (indexPath.section == 1) {
        NSArray *names = @[@"光效模式", @"动画速度", @"光效亮度", @"光效透明度"];
        cell.textLabel.text = names[indexPath.row];
        cell.accessoryView = indexPath.row == 0 ? _modeControl : @[_speedSlider, _brightnessSlider, _opacitySlider][indexPath.row - 1];
    } else {
        NSArray *names = @[@"按键扩散波纹", @"原生键盘", @"微信输入法"];
        cell.textLabel.text = names[indexPath.row];
        cell.accessoryView = @[_rippleSwitch, _nativeSwitch, _wechatSwitch][indexPath.row];
    }
    return cell;
}
@end
