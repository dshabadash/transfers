//
//  PBAssetListViewControllerIpad.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 10/01/2013.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBAssetListViewController.h"

@class PBAssetsGroupListViewController;

@interface PBAssetListViewControllerIpad : PBAssetListViewController
@property (retain, nonatomic) UIPopoverController *currentPopoverController;
+ (PBAssetsGroupListViewController *)groupsListViewController;
+ (Class)popoverBackgroundViewClass;
+ (UIBarButtonItem *)cancelBarButtonItemTarget:(id)target action:(SEL)action;
- (UIView *)navigationBarTitleView;
- (UILabel *)navigationBarTitleLabel;
- (UIButton *)albumsButton;
@end
