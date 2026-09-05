#import "KBGlowView.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@implementation KBGlowView
- (instancetype)initWithFrame:(CGRect)frame { if ((self=[super initWithFrame:frame])) { self.userInteractionEnabled=NO; self.backgroundColor=UIColor.clearColor; _glowSize=55; _glowDuration=.45; _glowOpacity=.75; _animationType=KBGlowAnimationTypeRipple; } return self; }
- (void)startAnimationAtPoint:(CGPoint)p {
    self.layer.sublayers=nil;
    CGFloat s=MAX(12,self.glowSize*2);
    CAGradientLayer *g=[CAGradientLayer layer]; g.frame=CGRectMake(0,0,s,s); g.position=p; g.type=kCAGradientLayerRadial; g.startPoint=CGPointMake(.5,.5); g.endPoint=CGPointMake(1,1); g.cornerRadius=s/2;
    UIColor *c=self.glowColor ?: UIColor.systemBlueColor; CGFloat a=MIN(1,MAX(.05,self.glowOpacity));
    g.colors=@[(id)[c colorWithAlphaComponent:a].CGColor,(id)[c colorWithAlphaComponent:a*.35].CGColor,(id)UIColor.clearColor.CGColor]; g.locations=@[@0,@.45,@1];
    [self.layer addSublayer:g];
    if (self.animationType==KBGlowAnimationTypeGlow) {
        g.opacity=1; CABasicAnimation *pulse=[CABasicAnimation animationWithKeyPath:@"opacity"]; pulse.fromValue=@(a*.25); pulse.toValue=@(a); pulse.autoreverses=YES; pulse.repeatCount=1; pulse.duration=MAX(.12,self.glowDuration*.5); [g addAnimation:pulse forKey:@"pulse"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(MAX(.25,self.glowDuration)*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ [self removeFromSuperview]; });
    } else {
        CABasicAnimation *scale=[CABasicAnimation animationWithKeyPath:@"transform.scale"]; scale.fromValue=@.25; scale.toValue=(self.animationType==KBGlowAnimationTypeParticle)?@1.15:@1.65;
        CABasicAnimation *fade=[CABasicAnimation animationWithKeyPath:@"opacity"]; fade.fromValue=@(a); fade.toValue=@0;
        CAAnimationGroup *grp=[CAAnimationGroup animation]; grp.animations=@[scale,fade]; grp.duration=MAX(.12,self.glowDuration); grp.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]; grp.delegate=self; [g addAnimation:grp forKey:@"glow"];
    }
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag { dispatch_async(dispatch_get_main_queue(),^{ [self removeFromSuperview]; }); }
- (void)stopAnimation { [self removeFromSuperview]; }
@end
