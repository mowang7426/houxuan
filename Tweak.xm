#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <CoreGraphics/CoreGraphics.h>

static BOOL GC_IsKeyboardCandidateLabel(UILabel *label) {
    if (!label || !label.window) return NO;

    UIView *v = label;
    BOOL keyboardAncestor = NO;
    for (NSInteger i = 0; i < 8 && v; i++, v = v.superview) {
        NSString *cls = NSStringFromClass([v class]);
        if ([cls rangeOfString:@"Keyboard" options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [cls rangeOfString:@"InputSet" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            keyboardAncestor = YES;
            break;
        }
    }
    if (!keyboardAncestor) return NO;

    NSString *text = label.text ?: @"";
    if (text.length == 0 || text.length > 12) return NO;

    // Candidate labels are normally short text labels near the top of the
    // keyboard/input view. This intentionally avoids the full keyboard area.
    CGRect r = [label convertRect:label.bounds toView:label.window];
    CGFloat h = label.window.bounds.size.height;
    if (r.origin.y > h * 0.65) return NO;
    if (r.size.height < 8 || r.size.height > 80) return NO;

    return YES;
}

static void GC_DrawGradientText(UILabel *label, CGRect rect) {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGContextSaveGState(ctx);

    // Clip to the label's text rendering region.
    [label.textColor set];
    [label.superview layoutIfNeeded];

    // Let UILabel calculate its normal text mask.
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef maskCtx = UIGraphicsGetCurrentContext();
    if (!maskCtx) {
        UIGraphicsEndImageContext();
        CGContextRestoreGState(ctx);
        return;
    }

    UIColor *opaque = [UIColor whiteColor];
    label.textColor = opaque;
    [label drawTextInRect:rect];

    UIImage *mask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (!mask.CGImage) {
        CGContextRestoreGState(ctx);
        return;
    }

    // Use the rendered alpha as a mask.
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, rect, mask.CGImage);

    CGFloat scale = UIScreen.mainScreen.scale;
    CGFloat colors[] = {
        0.20, 0.55, 1.00, 1.0,
        0.70, 0.25, 1.00, 1.0
    };
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(
        space, colors, NULL, 2
    );

    CGContextDrawLinearGradient(
        ctx, gradient,
        CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect)),
        CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect)),
        0
    );

    CGGradientRelease(gradient);
    CGColorSpaceRelease(space);
    CGContextRestoreGState(ctx);
    CGContextRestoreGState(ctx);

    (void)scale;
}

%hook UILabel

- (void)drawTextInRect:(CGRect)rect {
    if (GC_IsKeyboardCandidateLabel(self)) {
        // Avoid recursive calls by temporarily disabling the hook through
        // a thread-local guard.
        static __thread BOOL drawingGradient = NO;
        if (!drawingGradient) {
            drawingGradient = YES;

            CGContextRef ctx = UIGraphicsGetCurrentContext();
            if (ctx) {
                // Draw the original text into an alpha mask, then fill it
                // with the gradient.
                UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
                UILabel *copy = [self copy];
                copy.textColor = UIColor.whiteColor;
                [copy drawTextInRect:rect];
                UIImage *mask = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();

                if (mask.CGImage) {
                    CGContextSaveGState(ctx);
                    CGContextClipToMask(ctx, rect, mask.CGImage);

                    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
                    CGFloat comps[] = {
                        0.20, 0.55, 1.00, 1.0,
                        0.70, 0.25, 1.00, 1.0
                    };
                    CGGradientRef g = CGGradientCreateWithColorComponents(
                        space, comps, NULL, 2
                    );
                    CGContextDrawLinearGradient(
                        ctx, g,
                        CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect)),
                        CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect)),
                        0
                    );
                    CGGradientRelease(g);
                    CGColorSpaceRelease(space);
                    CGContextRestoreGState(ctx);
                    drawingGradient = NO;
                    return;
                }
            }

            drawingGradient = NO;
        }
    }

    %orig;
}

%end
