//
//  UIView+LSAdditions.m
//  MyApp
//
//  Created by Artem Meleshko on 2/24/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "UIView+LSAdditions.h"
#import "UIColor+LSAdditions.h"
#import "NSObject+LSAdditions.h"
#import <objc/runtime.h>


@interface UIView ()

@property (nonatomic,strong)CALayer *transitionLayer;
@property (nonatomic,assign,getter=isTransitionAnimationActive)BOOL transitionAnimationActive;
@property (nonatomic,copy)UIViewLayerTransitionAnimationCompletionBlock transitionAnimationCompletionBlock;

@end


@implementation UIView (LSAdditions)


#pragma mark - Debugging


- (void)showSubViewsBounds{
    [self showBoundsForView:self];  
}

- (void)showBoundsForView:(UIView *)v{
    @autoreleasepool {
        v.backgroundColor = [UIColor randomColor];
        for(UIView *subView in v.subviews){
            [self showBoundsForView:subView];
        }
    }
}


- (UIView *)superViewOfClass:(Class)superViewClass{
    UIView *s = [self superview];
    if([s isKindOfClass:superViewClass]){
        return s;
    }
    else{
        return [s superViewOfClass:superViewClass];
    }
}

- (UIView *)subViewOfClassString:(NSString*)subViewClassString{
    __block UIView *result = nil;
    
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([NSStringFromClass([obj class]) rangeOfString:subViewClassString].location!=NSNotFound){
            result = obj;
            *stop = YES;
        }
    }];
    
    if(result==nil){
        [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIView *v = [(UIView *)obj subViewOfClassString:subViewClassString];
            if(v!=nil){
                result = v;
                *stop = YES;
            }
        }];
    }
    
    return result;
}

- (UIView *)subViewOfClass:(Class)subViewClass{
    
    __block UIView *result = nil;
    
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([obj isKindOfClass:subViewClass]){
            result = obj;
            *stop = YES;
        }
    }];

    if(result==nil){
        [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIView *v = [(UIView *)obj subViewOfClass:subViewClass];
            if(v!=nil){
                result = v;
                *stop = YES;
            }
        }];
    }
    
    return result;
}

#pragma mark - Shadow

- (void)applyShadowWithOffset:(CGSize)offset radius:(CGFloat)radius{
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = offset;
    self.layer.shadowRadius = radius;
    self.layer.shadowOpacity = 0.3f;
}

- (void)removeShadow{
    self.layer.shadowColor = nil;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowRadius = 0.f;
    self.layer.shadowOpacity = 0.f;
}

#pragma mark - Animation

- (void)setTransitionAnimationActive:(BOOL)transitionAnimationActive{
     objc_setAssociatedObject(self, "kTransitionAnimationActive", @(transitionAnimationActive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isTransitionAnimationActive{
    return [objc_getAssociatedObject(self,"kTransitionAnimationActive") boolValue];
}

- (void)setTransitionLayer:(CALayer *)transitionLayer{
    objc_setAssociatedObject(self, "kTransitionLayer", transitionLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CALayer *)transitionLayer{
    return objc_getAssociatedObject(self,"kTransitionLayer");
}

- (void)setTransitionAnimationCompletionBlock:(UIViewLayerTransitionAnimationCompletionBlock)transitionAnimationCompletionBlock{
    objc_setAssociatedObject(self, "kTransitionCompletion", transitionAnimationCompletionBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIViewLayerTransitionAnimationCompletionBlock)transitionAnimationCompletionBlock{
    return objc_getAssociatedObject(self,"kTransitionCompletion");
}

- (BOOL)isLayerTransitionAnimationActive{
    return self.isTransitionAnimationActive;
}

- (CALayer *)addLayerTransitionAnimationWithQuadCurveToPoint:(CGPoint)point
                                               inView:(UIView *)view
                                         withCompletion:(UIViewLayerTransitionAnimationCompletionBlock)completion{
    
    NSAssert(self.isTransitionAnimationActive==NO, @"Transition animation is active");
    
    static const NSTimeInterval kAnimationDuration = 0.7;
    
    CALayer *transitionLayer = [[CALayer alloc] init];
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    transitionLayer.opacity = 1.0;
    transitionLayer.contents = (id)self.layer.contents;
    transitionLayer.frame = [view convertRect:self.bounds fromView:self];
    [view.layer addSublayer:transitionLayer];
    [CATransaction commit];
    
    UIBezierPath *movePath = [UIBezierPath bezierPath];
    [movePath moveToPoint:transitionLayer.position];
    CGPoint toPoint = CGPointMake(point.x, point.y);
    [movePath addQuadCurveToPoint:toPoint
                     controlPoint:CGPointMake(point.x,transitionLayer.position.y-120.0)];
    
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    positionAnimation.path = movePath.CGPath;
    positionAnimation.removedOnCompletion = YES;
    
    const CGFloat scaledWidth = 20.0f;
    const CGFloat scaleSx = scaledWidth/((self.bounds.size.width>0)?self.bounds.size.width:60.0f);
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    CATransform3D tr = CATransform3DIdentity;
    tr = CATransform3DScale(tr, scaleSx, scaleSx, 1);
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:tr];
    
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.beginTime = CACurrentMediaTime();
    group.duration = kAnimationDuration;
    group.animations = [NSArray arrayWithObjects:positionAnimation,scaleAnimation,nil];
    group.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    group.delegate = self;
    group.fillMode = kCAFillModeForwards;
    group.removedOnCompletion = YES;
    group.autoreverses= NO;
    
    [transitionLayer addAnimation:group forKey:@"opacity"];
    
    self.transitionLayer = transitionLayer;
    self.transitionAnimationCompletionBlock = completion;
    
    self.transitionAnimationActive = YES;
    
    return transitionLayer;
}

- (void)removeLayerTransitionAnimation{
    [self completeLayerTransitionAnimation];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if(flag){
        [self completeLayerTransitionAnimation];
    }
}

- (void)completeLayerTransitionAnimation{
    [self performBlockOnMainThreadSync:^{
        if(self.transitionAnimationCompletionBlock){
            self.transitionAnimationCompletionBlock(self.transitionLayer);
        }
        [self.transitionLayer removeAllAnimations];
        [self.transitionLayer removeFromSuperlayer];
        self.transitionLayer = nil;
        self.transitionAnimationCompletionBlock = nil;
        self.transitionAnimationActive = NO;
    }];
}

- (void)addBounceAnimationWithStyle:(UIViewBounceStyle)bounceStyle{
    
    NSString *keyPath;
    
    switch (bounceStyle) {
        case UIViewBounceStyleJump:
            keyPath = @"transform.translation.y";
            break;
        case UIViewBounceStyleVibrate:
            keyPath = @"transform.translation.x";
            break;
        default:
            return;
    }
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:keyPath];
    animation.duration = 0.3;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.values = [NSArray arrayWithObjects: [NSNumber numberWithInt:5],
                        [NSNumber numberWithInt:-5],
                        [NSNumber numberWithInt:4],
                        [NSNumber numberWithInt:-4],
                        [NSNumber numberWithInt:2],
                        [NSNumber numberWithInt:-2],
                        nil];
    
    [self.layer addAnimation:animation forKey:@"bounceAnimation"];
}

@end
