#import <UIKit/UIKit.h>

static BOOL GC_IsKeyboardCandidateLabel(UILabel *label) {
    if (!label || !label.window) return NO;

    UIView *v = label;
    BOOL keyboardAncestor = NO;
    for (NSInteger i = 0; i < 10 && v; i++, v = v.superview) {
        NSString *cls = NSStringFromClass([v class]);
        if ([cls rangeOfString:@"Keyboard" options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [cls rangeOfString:@"InputSet" options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [cls rangeOfString:@"Candidate" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            keyboardAncestor = YES;
            break;
        }
    }
    if (!keyboardAncestor) return NO;

    NSString *text = label.text ?: @"";
    if (text.length == 0 || text.length > 12) return NO;

    CGRect r = [label convertRect:label.bounds toView:label.window];
    CGFloat h = label.window.bounds.size.height;
    if (r.origin.y > h * 0.65) return NO;
    if (r.size.height < 8 || r.size.height > 80) return NO;

    return YES;
}

%hook UILabel

- (void)drawTextInRect:(CGRect)rect {
    static __thread BOOL drawingGradient = NO;

    if (drawingGradient || !GC_IsKeyboardCandidateLabel(self)) {
        %orig;
        return;
    }

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        %orig;
        return;
    }

    drawingGradient = YES;

    // Render the label's normal text into an alpha mask.
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef maskCtx = UIGraphicsGetCurrentContext();

    UIImage *mask = nil;
    if (maskCtx) {
        UIColor *oldColor = self.textColor;
        self.textColor = UIColor.whiteColor;
        [self drawTextInRect:rect];
        self.textColor = oldColor;
        mask = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();

    if (!mask.CGImage) {
        drawingGradient = NO;
        %orig;
        return;
    }

    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, rect, mask.CGImage);

    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();

    // Blue -> purple. Change these two RGBA colors to customize the gradient.
    CGFloat components[] = {
        0.20, 0.55, 1.00, 1.00,
        0.70, 0.25, 1.00, 1.00
    };

    CGGradientRef gradient =
        CGGradientCreateWithColorComponents(space, components, NULL, 2);

    CGContextDrawLinearGradient(
        ctx,
        gradient,
        CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect)),
        CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect)),
        0
    );

    CGGradientRelease(gradient);
    CGColorSpaceRelease(space);
    CGContextRestoreGState(ctx);

    drawingGradient = NO;
}

%end
