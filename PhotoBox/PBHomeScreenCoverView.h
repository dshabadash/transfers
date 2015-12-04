//
//  PBHomeScreenCoverView.h
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/8/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBHomeScreenCoverView : UIView<UIGestureRecognizerDelegate>
@property (assign, nonatomic) id delegate;

- (void)dismiss;
- (void)viewSelected;
- (void)willBeginDrugging;
- (void)movedByDelta:(NSNotification *)notification;
- (void)restored:(NSNotification *)notification;

@end
