//
//  PBAlbumListViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 15/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBViewController.h"

extern NSString * const PBAssetsGroupListViewControllerDidSelectAlbumNotification;

@class ALAssetsGroup;

@interface PBAssetsGroupListViewController : PBViewController<UITableViewDataSource, UITableViewDelegate>
@property (assign, nonatomic) UIPopoverController *presentingPopoverController;
@property (assign, nonatomic) BOOL presentedInPopover;

@property (retain, nonatomic, readonly) NSMutableArray *albums;
@property (retain, nonatomic, readonly) UITableView *tableView;
@property (nonatomic) BOOL albumsAreBeingUpdated;

- (BOOL)updateInProgress;
- (void)adjustPopoverSize;
- (void)reloadAlbums;
- (void)presentAssetListViewControllerAssetGroup:(ALAssetsGroup *)assetsGroup;
+ (UITableView *)albumsTableViewWithFrame:(CGRect)frame;
+ (UIBarButtonItem *)sendBarButtonItemTarget:(id)target action:(SEL)action;
//+ (UIBarButtonItem *)cancelBarButtonItemTarget:(id)target action:(SEL)action;
- (void)registerOnNotifications;

@end
