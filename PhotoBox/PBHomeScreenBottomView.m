//
//  PBHomeScreenBottomView.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 10/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBHomeScreenBottomView.h"

@implementation PBHomeScreenBottomView


#pragma mark - Delegate methods

- (void)viewSelected {
    SEL selector = @selector(bottomViewSelected);
    if ([self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector];
    }
}


#pragma mark - Notifications

- (void)movedByDelta:(NSNotification *)notification {
    [super movedByDelta:notification];

    CGFloat delta = -[[notification.userInfo objectForKey:kPBDelta] floatValue];
    if (notification.object == self) {
        delta *= -1;
    }

    CGFloat minimumY = self.superview.bounds.size.height - self.bounds.size.height;
    if (self.frame.origin.y + delta < minimumY) {
        delta = minimumY - self.frame.origin.y;
    }

    CGRect frame = self.frame;
    frame.origin.y += delta;
    self.frame = frame;
}

- (void)restored:(NSNotification *)notification {
    [super restored:notification];

    if (notification.object == self) {
        return;
    }

    CGRect frame = self.frame;
    CGSize size = frame.size;
    CGFloat height = size.height;

    frame.origin.y = height;
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.frame = frame;
                     }];
}

@end
