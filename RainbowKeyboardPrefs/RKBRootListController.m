#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

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

@end
