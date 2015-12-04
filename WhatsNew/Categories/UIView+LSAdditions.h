//
//  UIView+LSAdditions.h
//  MyApp
//
//  Created by Artem Meleshko on 2/24/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CALayer;

typedef enum {
    UIViewBounceStyleJump = 0,
    UIViewBounceStyleVibrate,
} UIViewBounceStyle;

typedef void (^UIViewAnimationsBlock)(void);

typedef void (^UIViewAnimationCompletionBlock)(BOOL finished);

typedef void (^UIViewLayerTransitionAnimationCompletionBlock)(CALayer *layer);



@interface UIView (LSAdditions)

- (void)showSubViewsBounds;

- (UIView *)superViewOfClass:(Class)superViewClass;
- (UIView *)subViewOfClassString:(NSString*)subViewClassString;
- (UIView *)subViewOfClass:(Class)subViewClass;

- (CALayer *)addLayerTransitionAnimationWithQuadCurveToPoint:(CGPoint)point
                                                      inView:(UIView *)view
                                              withCompletion:(UIViewLayerTransitionAnimationCompletionBlock)completion;
- (void)removeLayerTransitionAnimation;
- (BOOL)isLayerTransitionAnimationActive;



- (void)addBounceAnimationWithStyle:(UIViewBounceStyle)bounceStyle;
- (void)applyShadowWithOffset:(CGSize)offset radius:(CGFloat)radius;
- (void)removeShadow;

@end
