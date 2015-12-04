//
//  PBHomeScreenCoverView.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/8/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBHomeScreenCoverView.h"

@interface PBHomeScreenCoverView () {
    CGPoint _initialTapPoint;
    BOOL _shadowCreated;
}

@end

@implementation PBHomeScreenCoverView

- (void)awakeFromNib {
    [super awakeFromNib];

    UILongPressGestureRecognizer *longPressGestureRecognizer =
        [[[UILongPressGestureRecognizer alloc]
            initWithTarget:self
            action:@selector(handleLongPress:)]
        autorelease];

    longPressGestureRecognizer.minimumPressDuration = 0;
    longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:longPressGestureRecognizer];

    [self registerOnNotifications];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    [self removeShadow];
}


#pragma mark - Delegate methods

- (void)dismiss {
    [self removeShadow];
    
    SEL selector = @selector(dismissStartCoverViewsAnimated);
    if ([_delegate respondsToSelector:selector]) {
        [_delegate performSelector:selector];
    }
}

- (void)viewSelected {

}

- (void)willBeginDrugging {
    SEL action = @selector(coverViewWillBeginDragging:);
    if ([self.delegate respondsToSelector:action]) {
        [self.delegate performSelector:action withObject:self];
    }
}


#pragma mark - Gesture

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    UIGestureRecognizerState state = longPressGestureRecognizer.state;

    if (state == UIGestureRecognizerStateBegan) {
        [self willBeginDrugging];
        [self viewSelected];
        _initialTapPoint = [longPressGestureRecognizer locationInView:self];
    }
    else if (state == UIGestureRecognizerStateChanged) {
        CGPoint point = [longPressGestureRecognizer locationInView:self];
        CGFloat delta = point.y - _initialTapPoint.y;

        NSDictionary *userInfo = @{kPBDelta : @(delta)};
        [[NSNotificationCenter defaultCenter]
            postNotificationName:kPBHomeScreenViewMovedByDeltaNotification
            object:self
            userInfo:userInfo];
    }
    else if (state == UIGestureRecognizerStateEnded ||
             state == UIGestureRecognizerStateCancelled) {

        [self dismiss];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return NO;
}


#pragma mark - Notifications

- (void)registerOnNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(movedByDelta:)
        name:kPBHomeScreenViewMovedByDeltaNotification
        object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(restored:)
        name:kPBHomeScreenViewRestoredNotification
        object:nil];
}

- (void)movedByDelta:(NSNotification *)notification {
    [self createShadow];
}

- (void)restored:(NSNotification *)notification {
    [self removeShadow];
}

- (void)createShadow {
    if (!_shadowCreated) {
        CALayer *layer = [self layer];
        layer.shadowOffset = CGSizeMake(0, 1);
        layer.shadowColor = [[UIColor darkGrayColor] CGColor];
        layer.shadowRadius = 3.0;
        layer.shadowOpacity = 0.8;
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.bounds];
        layer.shadowPath = [shadowPath CGPath];

        _shadowCreated = YES;
    }
}

- (void)removeShadow {
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowPath = nil;
    self.layer.shadowColor = [[UIColor clearColor] CGColor];
    self.layer.shadowRadius = 0.0;
    self.layer.shadowOpacity = 0.0;

    _shadowCreated = NO;
}

@end
