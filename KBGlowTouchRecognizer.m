#import "KBGlowTouchRecognizer.h"

@implementation KBGlowTouchRecognizer

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return NO; }
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return NO; }

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (touches.count == 0) return;
    self.state = UIGestureRecognizerStateBegan;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateChanged;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.state != UIGestureRecognizerStatePossible && self.state != UIGestureRecognizerStateCancelled) {
        self.state = UIGestureRecognizerStateEnded;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)reset { [super reset]; }
@end
