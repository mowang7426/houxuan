#import "KBGlowTouchRecognizer.h"

@implementation KBGlowTouchRecognizer
- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return NO; }
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return NO; }
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.state = UIGestureRecognizerStateBegan;
    self.state = UIGestureRecognizerStateEnded;
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { if (self.state != UIGestureRecognizerStateEnded) self.state = UIGestureRecognizerStateEnded; }
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { self.state = UIGestureRecognizerStateCancelled; }
- (void)reset { [super reset]; }
@end
