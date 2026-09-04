#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "KBGlowManager.h"
#import "KBGlowView.h"

// 关联对象 key，用于存储当前 view 上的 KBGlowView
static const void *kKBGlowViewKey = &kKBGlowViewKey;

@interface UIView (KBGlow)
@property (nonatomic, strong) KBGlowView *kb_glowView;
@end

@implementation UIView (KBGlow)
- (KBGlowView *)kb_glowView {
    return objc_getAssociatedObject(self, kKBGlowViewKey);
}
- (void)setKb_glowView:(KBGlowView *)glowView {
    objc_setAssociatedObject(self, kKBGlowViewKey, glowView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

%hook UIView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    @try {
        KBGlowManager *mgr = [KBGlowManager sharedManager];
        if (![mgr isCurrentKeyboardEnabled]) return;
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        if ([mgr isKeyView:self]) {
            [mgr triggerGlowInView:self atPoint:point];
        }
    } @catch (NSException *e) {}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    @try {
        KBGlowView *glowView = self.kb_glowView;
        if (glowView) {
            [glowView stopAnimation];
            self.kb_glowView = nil;
        }
    } @catch (NSException *e) {}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    @try {
        KBGlowView *glowView = self.kb_glowView;
        if (glowView) {
            [glowView stopAnimation];
            self.kb_glowView = nil;
        }
    } @catch (NSException *e) {}
}

%end

%hook UIControl

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    @try {
        KBGlowManager *mgr = [KBGlowManager sharedManager];
        if (![mgr isCurrentKeyboardEnabled]) return;
        UITouch *touch = [touches anyObject];
        if (!touch) return;
        CGPoint point = [touch locationInView:self];
        if ([mgr isKeyView:self]) {
            [mgr triggerGlowInView:self atPoint:point];
        }
    } @catch (NSException *e) {}
}

%end
