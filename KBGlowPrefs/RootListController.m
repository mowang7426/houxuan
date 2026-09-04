#import "RootListController.h"

@implementation RootListController

- (NSArray *)specifiers {
    if (_specifiers == nil) {
        _specifiers = @[
            [PSSpecifier preferenceSpecifierNamed:@"KBGlow 测试" target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil],
            [PSSpecifier preferenceSpecifierNamed:@"如果你看到这行，说明 bundle 加载成功" target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil]
        ];
    }
    return _specifiers;
}

@end
