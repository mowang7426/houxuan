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
            KBGlowAnimationType type = mgr.animationType;

            if (type == KBGlowAnimationTypeGlow) {
                // 常驻光晕：创建并保存，touchesEnded 时停止
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
                // 涟漪和粒子：一次性触发
                [mgr triggerGlowInView:self atPoint:point];
            }
        }
    } @catch (NSException *e) {
        // 静默失败，不影响键盘正常使用
    }
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

// 补充：hook UIControl 的触摸事件，覆盖某些用 UIControl 实现按键的键盘
%hook UIControl

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;

    @try {
        KBGlowManager *mgr = [KBGlowManager sharedManager];
        if (![mgr isCurrentKeyboardEnabled]) return;
        if (mgr.animationType == KBGlowAnimationTypeGlow) return; // glow 模式已在 UIView hook 处理

        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];

        if ([mgr isKeyView:self]) {
            [mgr triggerGlowInView:self atPoint:point];
        }
    } @catch (NSException *e) {}
}

%end
