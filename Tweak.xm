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
            // === 调试：检测到按键时显示红色边框，0.5秒后消失 ===
            UIView *keyView = [mgr findKeyViewFromView:self];
            keyView.layer.borderWidth = 3.0;
            keyView.layer.borderColor = [UIColor redColor].CGColor;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                keyView.layer.borderWidth = 0;
            });
            // === 调试结束 ===

            KBGlowAnimationType type = mgr.animationType;
            if (type == KBGlowAnimationTypeGlow) {
                UIView *container = self.superview ?: self;
                CGPoint convertedPoint = [self convertPoint:point toView:container];
                if (!mgr.followFinger) {
                    convertedPoint = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
                }
                KBGlowView *glowView = [[KBGlowView alloc] initWithFrame:container.bounds];
                glowView.glowColor = mgr.glowColor;
                glowView.glowSize = mgr.glowSize;
                glowView.glowDuration = mgr.glowDuration;
                glowView.glowOpacity = mgr.glowOpacity;
                glowView.animationType = type;
                glowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [container addSubview:glowView];
                [glowView startAnimationAtPoint:convertedPoint];
                self.kb_glowView = glowView;
            } else {
                [mgr triggerGlowInView:self atPoint:point];
            }
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
        if (mgr.animationType == KBGlowAnimationTypeGlow) return;
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        if ([mgr isKeyView:self]) {
            // === 调试：UIControl 按键也显示红框 ===
            UIView *keyView = [mgr findKeyViewFromView:self];
            keyView.layer.borderWidth = 3.0;
            keyView.layer.borderColor = [UIColor redColor].CGColor;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                keyView.layer.borderWidth = 0;
            });
            // === 调试结束 ===
            [mgr triggerGlowInView:self atPoint:point];
        }
    } @catch (NSException *e) {}
}

%end
