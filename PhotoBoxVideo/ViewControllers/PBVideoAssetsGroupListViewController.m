//
//  PBVideoAssetsGroupListViewController.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/16/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBVideoAssetsGroupListViewController.h"
#import "PBAssetManager.h"
#import "PBVideoAssetGroupTableViewCell.h"
#import "PBVideoAssetListViewController.h"

static NSString *kAlbumCellIdentifier = @"AlbumCellIdentifier";
static NSString *kAllVideosGroupIconFileName = @"Icon";

@interface PBVideoAssetsGroupListViewController () {
  //  ALAssetsGroup *_allVideosAssetGroup;

}

@property (nonatomic, strong) UIImage *allVideoGroupIcon;
@property (nonatomic, strong) ALAssetsGroup *allVideosAssetGroup;
@end

@implementation PBVideoAssetsGroupListViewController
@synthesize allVideosAssetGroup = _allVideosAssetGroup;
- (void)dealloc {
    [_allVideoGroupIcon release];
    _allVideoGroupIcon = nil;

    [super dealloc];
}


#pragma mark - Appearence

+ (UITableView *)albumsTableViewWithFrame:(CGRect)frame {
    UITableView *tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
    tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    tableView.rowHeight = 55;
    tableView.backgroundColor = [UIColor whiteColor];
    tableView.separatorColor = [UIColor colorWithRGB:0xe0e0e0];

    UINib *cellNib = [UINib nibWithNibName:@"PBVideoAssetGroupTableViewCell"
                                    bundle:nil];

    [tableView registerNib:cellNib forCellReuseIdentifier:kAlbumCellIdentifier];
    
    return tableView;
}

+ (UIBarButtonItem *)cancelBarButtonItemTarget:(id)target action:(SEL)action {
    UIImage *image = [UIImage imageNamed:@"navbar_cancel_icon"];
    UIBarButtonItem *cancelButton =
        [[[UIBarButtonItem alloc] initWithImage:image
            style:UIBarButtonItemStyleBordered
            target:target
            action:action]
        autorelease];
    
    return cancelButton;
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    self.allVideoGroupIcon = [UIImage imageNamed:kAllVideosGroupIconFileName];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self hideToolbarShadow];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self restoreToolbarShadow];
}

- (void)presentAssetListViewControllerAssetGroup:(ALAssetsGroup *)assetsGroup {
    //for test
    if (assetsGroup == _allVideosAssetGroup) {
        [assetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
    }
    else {
        [assetsGroup setAssetsFilter:[ALAssetsFilter allAssets]];
    }
    
    PBVideoAssetListViewController *vc =
        [[[PBVideoAssetListViewController alloc] initWithAssetsGroup:assetsGroup] autorelease];

    if (assetsGroup == _allVideosAssetGroup) {
        vc.title = [PBAssetManager allVideosGroupLocalizedName];
    }

    [self.navigationController pushViewController:vc animated:YES];
}

- (void)hideToolbarShadow {
    self.navigationController.toolbar.layer.masksToBounds = YES;
}

- (void)restoreToolbarShadow {
    self.navigationController.toolbar.layer.masksToBounds = NO;
}


#pragma mark - Assets

- (void)sendDidSelectAssetsAlbumNotificationAssetGroup:(ALAssetsGroup *)assetsGroup {
    //for test
    if (assetsGroup == _allVideosAssetGroup) {
        [assetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
    }
    else {
        [assetsGroup setAssetsFilter:[ALAssetsFilter allAssets]];
    }
    
    NSDictionary *userInfo = @{
                               kPBAssetsGroupUrl : [assetsGroup valueForProperty:ALAssetsGroupPropertyURL],
                               @"group" : assetsGroup,
                               @"groupName" : (assetsGroup == _allVideosAssetGroup) ? [PBAssetManager allVideosGroupLocalizedName] : [assetsGroup valueForProperty:ALAssetsGroupPropertyName]
                               };
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:PBAssetsGroupListViewControllerDidSelectAlbumNotification
     object:self
     userInfo:userInfo];
}

- (void)reloadAlbums {
    @synchronized(self.albums) {
        if (self.albumsAreBeingUpdated) {
            return;
        }
        
        self.albumsAreBeingUpdated = YES;
    }
    
    [[PBAssetManager sharedManager] allVideosAssetsGroup:^(ALAssetsGroup *assetGroup) {
        _allVideosAssetGroup = [assetGroup retain];

        [[PBAssetManager sharedManager] allAssetsGroups:^(NSArray *groups) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableArray *groupsSet = [NSMutableArray arrayWithCapacity:0];

                // Place camera roll group at top of the list
                /*  for (ALAssetsGroup *group in groups) {
                    if (([[group valueForProperty:ALAssetsGroupPropertyType] unsignedIntegerValue] == ALAssetsGroupSavedPhotos) && (group != _allVideosAssetGroup)) {
                        [groupsSet addObject:group];
                        break;
                    }
                }*/

                // Place all videos group next to CameraRoll group
            //    if (nil != _allVideosAssetGroup) {
           //         [groupsSet addObject:assetGroup];
            //    }


                [groupsSet addObject:_allVideosAssetGroup];
                
                for (id group in groups) {
                    if (![groupsSet containsObject:group]) {
                        [groupsSet addObject:group];
                    }
                }

                [self.albums removeAllObjects];
                [self.albums addObjectsFromArray:groupsSet];
                


                
                @synchronized(self.albums) {
                    self.albumsAreBeingUpdated = NO;
                }
                [self.tableView reloadData];
                [self adjustPopoverSize];
            });
        }];
    }];
                  
}


#pragma mark - UITableViewDataSource protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PBVideoAssetGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAlbumCellIdentifier];

    ALAssetsGroup *assetsGroup = self.albums[indexPath.row];//[[self.albums[indexPath.row] retain] autorelease];
    
    NSString *title = (assetsGroup == _allVideosAssetGroup)
        ? [PBAssetManager allVideosGroupLocalizedName]
        : [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    
    //for test
    if (assetsGroup == _allVideosAssetGroup) {
        [assetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
    }

    NSInteger numberOfAssets = assetsGroup.numberOfAssets;
    NSString *groupLabel = [NSString stringWithFormat:@"%@ (%d)", title, numberOfAssets];
    [cell setGroupLabelText:groupLabel];

    UIImage *image = (assetsGroup == _allVideosAssetGroup)
        ? _allVideoGroupIcon
        : [UIImage imageWithCGImage:[assetsGroup posterImage]];

    [cell setThumbnailImage:image];

    
    return cell;
}

@end
