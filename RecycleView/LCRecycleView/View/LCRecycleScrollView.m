//
//  LCRecycleScrollView.m
//  RecycleView
//
//  Created by lax on 2022/4/18.
//

#import "LCRecycleScrollView.h"

@implementation LCRecycleScrollView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect bounds = self.bounds;
    CGFloat extendX = self.hitTestInsets.left + self.hitTestInsets.right;
    CGFloat extendY = self.hitTestInsets.top + self.hitTestInsets.bottom;
    bounds = CGRectOffset(bounds, self.hitTestInsets.top, self.hitTestInsets.left);
    bounds = CGRectInset(bounds, extendX, extendY);
    return CGRectContainsPoint(bounds, point);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[self nextResponder] touchesBegan:touches withEvent:event];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[self nextResponder] touchesMoved:touches withEvent:event];
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[self nextResponder] touchesEnded:touches withEvent:event];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[self nextResponder] touchesCancelled:touches withEvent:event];
    [super touchesCancelled:touches withEvent:event];
}

@end
