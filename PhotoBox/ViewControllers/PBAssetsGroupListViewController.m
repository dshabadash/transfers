//
//  PBAlbumListViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 15/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBAssetsGroupListViewController.h"

#import "PBAssetManager.h"

#import "PBAssetListViewController.h"
#import "PBAssetGroupTableViewCell.h"
#import "PBRootViewController.h"

NSString * const PBAssetsGroupListViewControllerDidSelectAlbumNotification = @"PBAssetsGroupListViewControllerDidSelectAlbumNotification";

@interface PBAssetsGroupListViewController () {
  //  BOOL _albumsAreBeingUpdated;
}

@end

@implementation PBAssetsGroupListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Albums", @"Albums");

        _albums = [NSMutableArray new];
        
        self.showTopToolbar = NO;
        self.topBarShadowType = PBViewControllerTopBarShadowTypeNormal;

        _albumsAreBeingUpdated = NO;

        self.automaticallyAdjustsScrollViewInsets = NO;
       // self.contentSizeForViewInPopover = CGSizeMake(320, 100);
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_albums removeAllObjects];
    [_albums release];

    _tableView = nil;
    _presentingPopoverController = nil;
    
    [super dealloc];
}


#pragma mark - Appearence

+ (UITableView *)albumsTableViewWithFrame:(CGRect)frame {

    UITableView *tableView = [[[UITableView alloc] initWithFrame:frame
                                                           style:UITableViewStylePlain] autorelease];

    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    tableView.rowHeight = 56;
    tableView.backgroundColor = [UIColor defaultBackgroundColor];
    tableView.separatorColor = [UIColor defaultTableViewSeparatorColor];

    return tableView;
}

+ (UIBarButtonItem *)sendBarButtonItemTarget:(id)target action:(SEL)action {
    UIBarButtonItem *sendButton =
        [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"")
            style:UIBarButtonItemStyleDone
            target:target
            action:action]
        autorelease];

    return sendButton;
}

+ (UIBarButtonItem *)cancelBarButtonItemTarget:(id)target action:(SEL)action {
    UIBarButtonItem *cancelButton =
        [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"")
            style:UIBarButtonSystemItemCancel//initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
            target:target
            action:action]
        autorelease];

    return cancelButton;
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!_presentedInPopover) {

        self.navigationItem.rightBarButtonItem =
            [[self class] sendBarButtonItemTarget:self
                                           action:@selector(sendButtonTapped:)];

        self.navigationItem.leftBarButtonItem =
            [[self class] cancelBarButtonItemTarget:self
                                             action:@selector(cancel)];
    }
    
    _tableView = [[self class] albumsTableViewWithFrame:self.view.frame];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self.view addSubview:_tableView];
    self.view.backgroundColor = _tableView.backgroundColor;
    
    [self reloadAlbums];
    [self registerOnNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!_presentedInPopover) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }

    [self updateSendButtonState];
}

- (void)updateSendButtonState {
    self.navigationItem.rightBarButtonItem.enabled = [[PBAssetManager sharedManager] assetCount] != 0;
}

- (void)adjustPopoverSize {
    if (_presentedInPopover) {
        @synchronized(_albums) {
            CGFloat popoverHeight = _tableView.rowHeight * _albums.count + 44;
            if (popoverHeight > 400) popoverHeight = 400;
            [_presentingPopoverController setPopoverContentSize:CGSizeMake(320, popoverHeight)
                                                       animated:NO];
        }
    }
}

- (void)presentAssetListViewControllerAssetGroup:(ALAssetsGroup *)assetsGroup {
    PBAssetListViewController *vc = [[[PBAssetListViewController alloc] initWithAssetsGroup:assetsGroup] autorelease];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - Actions

- (void)sendButtonTapped:(id)sender {
    [[PBAppDelegate sharedDelegate] presentConnectViewControllerInNavigationController:self.navigationController];
}

- (void)cancel {
    [[PBRootViewController sharedController] presentStartCoverViewsAnimated:YES];

    PBAssetManager *assetManager = [PBAssetManager sharedManager];
    [assetManager cancelPreparingAssets];
    [assetManager removeAllAssets];
}


#pragma mark - Assets

- (void)reloadAlbums {
    @synchronized(_albums) {
        if (_albumsAreBeingUpdated) {
            return;
        }

        _albumsAreBeingUpdated = YES;
    }

    [[PBAssetManager sharedManager] allAssetsGroups:^(NSArray *groups) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_albums removeAllObjects];
            [_albums addObjectsFromArray:groups];

            @synchronized(_albums) {
                _albumsAreBeingUpdated = NO;
            }

            [_tableView reloadData];
            [self adjustPopoverSize];
        });
    }];
}

- (BOOL)updateInProgress {
    return _albumsAreBeingUpdated;
}


#pragma mark - Notifications

- (void)registerOnNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(reloadAlbums)
                               name:ALAssetsLibraryChangedNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(reloadAlbums)
                               name:PBAssetManagerDidGetAccessToAssetsLibraryNotification
                             object:nil];


    [notificationCenter addObserver:self
                           selector:@selector(updateSendButtonState)
                               name:PBAssetManagerDidAddAssetNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(updateSendButtonState)
                               name:PBAssetManagerDidRemoveAssetNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(updateSendButtonState)
                               name:PBAssetManagerDidRemoveAllAssetsNotification
                             object:nil];
}

- (void)sendDidSelectAssetsAlbumNotificationAssetGroup:(ALAssetsGroup *)assetsGroup {
    NSDictionary *userInfo = @{
        kPBAssetsGroupUrl : [assetsGroup valueForProperty:ALAssetsGroupPropertyURL],
        @"group" : assetsGroup
    };

    [[NSNotificationCenter defaultCenter]
        postNotificationName:PBAssetsGroupListViewControllerDidSelectAlbumNotification
        object:self
        userInfo:userInfo];
}


#pragma mark - UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    @synchronized(_albums) {
        if (_albumsAreBeingUpdated) {
            return 0;
        }

        return _albums.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"AlbumCellIdentifier";
    PBAssetGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[PBAssetGroupTableViewCell alloc] initWithReuseIdentifier:cellIdentifier] autorelease];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
        if (!_presentedInPopover) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

    @synchronized(_albums) {
        if (_albumsAreBeingUpdated) {
            cell.textLabel.text = nil;
            cell.imageView.image = nil;
            cell.assetCount = 0;
            return cell;
        }
    }

    ALAssetsGroup *assetsGroup = [[_albums[indexPath.row] retain] autorelease];
    NSString *title = [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    NSInteger numberOfAssets = assetsGroup.numberOfAssets;

    //info
    cell.textLabel.text = title;

    UIImage *imageForCell = [UIImage imageWithCGImage:[assetsGroup posterImage]];
    if (imageForCell) {
        cell.imageView.image = imageForCell;
    }
    else {
       cell.imageView.image = [UIImage imageNamed:@"asset-stub.png"];
    }
    cell.assetCount = numberOfAssets;

    return cell;
}


#pragma mark - UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    @synchronized(_albums) {
        if (_albumsAreBeingUpdated) {
            return;
        }

        ALAssetsGroup *assetsGroup = [_albums objectAtIndex:indexPath.row];

        
        
        if (_presentedInPopover) {
            [self sendDidSelectAssetsAlbumNotificationAssetGroup:assetsGroup];
        }
        else {
            [self presentAssetListViewControllerAssetGroup:assetsGroup];
        }
    }
}

@end
