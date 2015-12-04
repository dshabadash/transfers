//
//  PBAssetListViewControllerIpad.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 10/01/2013.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBAssetListViewControllerIpad.h"
#import "PBAssetsGroupListViewController.h"
#import "PBPopoverBackgroundView.h"
#import "PBAssetManager.h"
#import "PBPhotoBar.h"

#import "PBAssetUploader.h"
#import "PBServlets.h"

@interface PBAssetListViewControllerIpad () <UIPopoverControllerDelegate> {
    UIButton *_albumsButton;
    UILabel *_albumsTitleLabel;
    UIView *_titleView;
}

@end

@implementation PBAssetListViewControllerIpad

+ (PBAssetsGroupListViewController *)groupsListViewController {
    return [[PBAssetsGroupListViewController new] autorelease];
}

+ (Class)popoverBackgroundViewClass {
    return [PBPopoverBackgroundView class];
}

+ (UIBarButtonItem *)cancelBarButtonItemTarget:(id)target action:(SEL)action {
    UIBarButtonItem *cancelButton =
        [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
            target:target
            action:action]
        autorelease];

    return cancelButton;
}

- (PSTCollectionViewFlowLayout *)collectionViewLayout {
    PSTCollectionViewFlowLayout *collectionViewLayout = [[[PSTCollectionViewFlowLayout alloc] init] autorelease];
    collectionViewLayout.itemSize = CGSizeMake(130, 130);
    collectionViewLayout.minimumLineSpacing = 8;
    collectionViewLayout.minimumInteritemSpacing = 5;
    collectionViewLayout.sectionInset = UIEdgeInsetsMake(6, 12, 6, 12);


    return collectionViewLayout;
}

- (UINib *)collectionViewCellNib {
    UINib *nib = [UINib nibWithNibName:@"PBAssetPreviewCollectionCell-ipad" bundle:[NSBundle mainBundle]];

    return nib;
}

- (UIView *)navigationBarTitleView {
    UIView *titleView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 100.0, 44.0)] autorelease];
    
    return titleView;
}

- (UILabel *)navigationBarTitleLabel {
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 44.0)] autorelease];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.font = [UIFont boldSystemFontOfSize:20 ];
    titleLabel.shadowOffset = CGSizeMake(0, -1);
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.shadowColor = [UIColor colorWithRGB:0xab4823];
    titleLabel.textAlignment = NSTextAlignmentCenter;

    return titleLabel;
}

- (UIButton *)albumsButton {
    UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(21.0, 0, 79.0, 44.0)] autorelease];
    
    UIImage *normalButtonImage = [UIImage imageNamed:@"albums-title-button-ipad"];
    [button setImage:normalButtonImage forState:UIControlStateNormal];

    UIImage *pressedButtonImage = [UIImage imageNamed:@"albums-title-button-pressed-ipad"];
    [button setImage:pressedButtonImage forState:UIControlStateHighlighted];

    [button addTarget:self
        action:@selector(albumsButtonTapped:)
        forControlEvents:UIControlEventTouchDown];

    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;


    return button;
}

- (id)initWithAssetsGroup:(ALAssetsGroup *)group {
    self = [super initWithAssetsGroup:group];
    if (self) {
        self.aspectThumbnail = YES;
    }
    return self;
}

- (void)dealloc {
    _albumsButton = nil;
    _albumsTitleLabel = nil;
    _titleView = nil;

    [super dealloc];
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem =
        [[self class] cancelBarButtonItemTarget:self
                                         action:@selector(cancel)];

    _titleView = [self navigationBarTitleView];
    
    _albumsTitleLabel = [self navigationBarTitleLabel];
    [_titleView addSubview:_albumsTitleLabel];

    _albumsButton = [self albumsButton];
    [_titleView addSubview:_albumsButton];

    [self updateTitle];

    self.navigationItem.titleView = _titleView;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    
    if (self.isViewLoaded) {
        [self updateTitle];
    }
}

- (void)updateTitle {
    _albumsTitleLabel.text = self.title;
    CGSize titleSize = [_albumsTitleLabel textSize];
    _titleView.bounds = CGRectMake(0, 0, titleSize.width + 140, 44);
}


#pragma mark - Actions

- (void)cancel {
    [PBActionSheet cancelAllActionSheets];
    [[PBRootViewController sharedController] presentStartCoverViewsAnimated:YES completion:^{
        PBAssetManager *assetManager = [PBAssetManager sharedManager];
        [assetManager cancelPreparingAssets];
        [assetManager removeAllAssets];
        [self setAssetsGroupUrl:nil];
    }];
}

- (void)albumsButtonTapped:(id)sender {
    [PBActionSheet cancelAllActionSheets];
    
    if (_currentPopoverController) {
        [_currentPopoverController dismissPopoverAnimated:YES];
        _currentPopoverController = nil;
        return;
    }

    PBAssetsGroupListViewController *vc = [[self class] groupsListViewController];
    vc.presentedInPopover = YES;

    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    [nc.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    
    UIPopoverController *ppc = [[[UIPopoverController alloc] initWithContentViewController:nc] autorelease];
    ppc.popoverBackgroundViewClass = [[self class] popoverBackgroundViewClass];
    ppc.passthroughViews = [NSArray array];
    ppc.delegate = self;

    self.currentPopoverController = ppc;
    vc.presentingPopoverController = ppc;
    [vc view];

    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        UIBarButtonItem *fakeBarButton = [[[UIBarButtonItem alloc] initWithCustomView:sender] autorelease];
        [ppc presentPopoverFromBarButtonItem:fakeBarButton
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:YES];
    });
}


#pragma mark - Notifications

- (void)registerOnNotifications {
    [super registerOnNotifications];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(albumSelected:)
                               name:PBAssetsGroupListViewControllerDidSelectAlbumNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(photobarDidSelectAssetUrl:)
                               name:PBPhotoBarDidSelectAssetUrlNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(finishedPhotosDelivery:)
                               name:PBGetFileServletDidDeliverServletResponse
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(finishedPhotosDelivery:)
                               name:PBAssetUploaderUploadDidFinishNotification
                             object:nil];
}

- (void)albumSelected:(NSNotification *)notification {
   // self.title = [notification.userInfo objectForKey:@"groupName"];
    
    NSURL *albumUrl = notification.userInfo[kPBAssetsGroupUrl];
    [self setAssetsGroupUrl:albumUrl];

    if (_currentPopoverController) {
        [_currentPopoverController dismissPopoverAnimated:YES];
        self.currentPopoverController = nil;
    }
}

- (void)photobarDidSelectAssetUrl:(NSNotification *)notification {
    PBAssetManager *assetManager = [PBAssetManager sharedManager];
    
    NSURL *assetUrl = notification.object;
    NSURL *groupUrl = [assetManager getGroupUrlForAssetUrl:assetUrl];

    if ([groupUrl isEqual:self.assetsGroupUrl] == NO) {
        [self setAssetsGroupUrl:groupUrl];
    }
    
    [self scrollToAsset:[assetManager assetForUrl:assetUrl]];
}

- (void)finishedPhotosDelivery:(NSNotification *)notification {
    [self setAssetsGroupUrl:nil      ];
}


#pragma mark - Popover

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.currentPopoverController = nil;
}

@end
