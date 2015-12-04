//
//  PBRootViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 11/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBRootViewController : PBViewController
@property (retain, nonatomic) UIViewController *topViewController;
@property (retain, nonatomic) UIViewController *bottomViewController;
@property (retain, nonatomic) UIView *topView;
@property (retain, nonatomic) UIView *bottomView;

+ (id)sharedController;
- (void)toggleViewController;
- (void)setTopViewControllerActive:(BOOL)active animated:(BOOL)animated;
- (void)presentStartCoverViewsAnimated:(BOOL)animated completion:(dispatch_block_t)completion;
- (void)presentStartCoverViewsAnimated:(BOOL)animated;
- (void)dismissStartCoverViewsAnimated;
- (void)presentMultiselectionTipView;
- (void)presentHelpViewController;
- (void)presentHelpViewController:(UIViewController *)helpViewController animated:(BOOL)animated;
- (void)presentImportFailedViewController;
- (void)dismissImportFailedViewController;
- (void)topViewSelected;
- (void)bottomViewSelected;
- (void)coverViewWillBeginDragging:(UIView *)coverView;

@end
