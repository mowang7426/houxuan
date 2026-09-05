#import "KBGlowView.h"
#import <QuartzCore/QuartzCore.h>
@implementation KBGlowView { CAGradientLayer *_glow; BOOL _tracking; }
- (instancetype)initWithFrame:(CGRect)f { if((self=[super initWithFrame:f])){ self.userInteractionEnabled=NO; self.backgroundColor=UIColor.clearColor; _glowSize=55; _glowDuration=.45; _glowOpacity=.75; _animationType=KBGlowAnimationTypeRipple; } return self; }
- (void)startTrackingAtPoint:(CGPoint)p {
    [_glow removeFromSuperlayer]; CGFloat s=MAX(12,_glowSize*2); _glow=[CAGradientLayer layer]; _glow.frame=CGRectMake(0,0,s,s); _glow.position=p; _glow.type=kCAGradientLayerRadial; _glow.startPoint=CGPointMake(.5,.5); _glow.endPoint=CGPointMake(1,1); _glow.cornerRadius=s/2;
    UIColor *c=self.glowColor?:UIColor.systemBlueColor; CGFloat a=MIN(1,MAX(.05,self.glowOpacity)); _glow.colors=@[(id)[c colorWithAlphaComponent:a].CGColor,(id)[c colorWithAlphaComponent:a*.32].CGColor,(id)UIColor.clearColor.CGColor]; _glow.locations=@[@0,@.42,@1]; [self.layer addSublayer:_glow]; _tracking=YES;
    if(self.animationType==KBGlowAnimationTypeGlow){ CABasicAnimation *pulse=[CABasicAnimation animationWithKeyPath:@"opacity"]; pulse.fromValue=@(a*.55); pulse.toValue=@a; pulse.autoreverses=YES; pulse.duration=MAX(.12,self.glowDuration*.5); [_glow addAnimation:pulse forKey:@"pulse"]; }
    else { _glow.opacity=a; CABasicAnimation *in=[CABasicAnimation animationWithKeyPath:@"transform.scale"]; in.fromValue=@.55; in.toValue=@1; in.duration=.08; in.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]; [_glow addAnimation:in forKey:@"pressIn"]; }
}
- (void)updateTrackingPoint:(CGPoint)p { if(!_tracking||!_glow)return; [CATransaction begin]; [CATransaction setDisableActions:YES]; _glow.position=p; [CATransaction commit]; }
- (void)finishTrackingAtPoint:(CGPoint)p cancelled:(BOOL)cancelled {
    if(!_glow){ [self removeFromSuperview]; return; } _tracking=NO; if(!cancelled) [self updateTrackingPoint:p];
    CGFloat a=MIN(1,MAX(.05,self.glowOpacity)); NSTimeInterval d=MAX(.08,self.glowDuration);
    CABasicAnimation *fade=[CABasicAnimation animationWithKeyPath:@"opacity"]; fade.fromValue=@(_glow.presentationLayer?[(CALayer*)_glow.presentationLayer opacity]:a); fade.toValue=@0; fade.duration=d; fade.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    CABasicAnimation *scale=[CABasicAnimation animationWithKeyPath:@"transform.scale"]; scale.fromValue=@1; scale.toValue=(self.animationType==KBGlowAnimationTypeParticle?@1.12:@1.42); scale.duration=d; scale.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    CAAnimationGroup *grp=[CAAnimationGroup animation]; grp.animations=@[fade,scale]; grp.duration=d; grp.delegate=self; [_glow addAnimation:grp forKey:@"finish"];
}
- (void)animationDidStop:(CAAnimation*)anim finished:(BOOL)flag { dispatch_async(dispatch_get_main_queue(),^{ [self removeFromSuperview]; }); }
- (void)stopAnimation { _tracking=NO; [_glow removeAllAnimations]; [self removeFromSuperview]; }
@end
