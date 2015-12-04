//
//  PBVideoHomeScreenTopView.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/8/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBVideoHomeScreenTopView.h"
#import "PBAssetPreviewCollectionViewDataSource.h"

@interface PBVideoHomeScreenTopView ()
@property (retain, nonatomic) IBOutlet PSTCollectionView *collectionView;
@property (retain, nonatomic) IBOutlet UIView *collectionViewContainer;
@property (retain, nonatomic) PBAssetPreviewCollectionViewDataSource *dataSource;
@end

@implementation PBVideoHomeScreenTopView

+ (PSTCollectionViewFlowLayout *)collectionViewLayout {
    PSTCollectionViewFlowLayout *collectionViewLayout = [[PSTCollectionViewFlowLayout new] autorelease];
    collectionViewLayout.scrollDirection = PSTCollectionViewScrollDirectionHorizontal;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        collectionViewLayout.itemSize = CGSizeMake(108, 78);
        collectionViewLayout.minimumLineSpacing = 12.0;
        collectionViewLayout.minimumInteritemSpacing = 12.0;
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, -17.0, 0, 0);
    } else {
        collectionViewLayout.itemSize = CGSizeMake(99, 94);
        collectionViewLayout.minimumLineSpacing = 3;
        collectionViewLayout.minimumInteritemSpacing = 3;
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 8, 0, 6);
    }

    
    return collectionViewLayout;
}

+ (id<PSTCollectionViewDataSource>)collectionViewDataSource {
    NSRange assetsRange = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        ? NSMakeRange(0, 9)
        : NSMakeRange(0, 3);

    id<PSTCollectionViewDataSource> dataSource =
        [[[PBAssetPreviewCollectionViewDataSource alloc] initWithAssetGroup:nil
            range:assetsRange]
        autorelease];

    return dataSource;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [_collectionView setUserInteractionEnabled:NO];

    UINib *nib = [UINib nibWithNibName:@"PBAssetVideoLargePreviewCollectionCell" bundle:nil];
    [_collectionView registerNib:nib forCellWithReuseIdentifier:kPBAssetPreviewCollectionCellIdentifier];

    self.dataSource = [[self class] collectionViewDataSource];
    _collectionView.dataSource = self.dataSource;

    PSTCollectionViewFlowLayout *collectionViewLayout = [[self class] collectionViewLayout];
    [_collectionView setCollectionViewLayout:collectionViewLayout];
    
    [self registerOnCollectionViewNotifications];
}

- (void)layoutSubviews {
    [super layoutSubviews];


    // On iPad changing distance between collection view and bottom edge
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIDeviceOrientation orientation = [[[[UIApplication sharedApplication] delegate].window rootViewController] interfaceOrientation];

        CGRect containerFrame = self.collectionViewContainer.frame;
        containerFrame.origin.y = self.bounds.size.height - containerFrame.size.height;

        if (UIDeviceOrientationIsPortrait(orientation)) {
            containerFrame.origin.y -= 254.0;
        }
        else {
            containerFrame.origin.y -= 164.0;
        }

        [self.collectionViewContainer setFrame:containerFrame];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_collectionView release];
    _collectionView = nil;

    [_dataSource release];
    _dataSource = nil;

    [super dealloc];
}

- (void)reloadAssets {
    if ([[PBAssetManager sharedManager] isImportAssetInProgress]) {
        return;
    }

    [[PBAssetManager sharedManager] savedPhotosAssetsGroupCompletionBlock:
        ^(ALAssetsGroup *assetGroup) {
            self.dataSource.assetsGroup = assetGroup;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_collectionView reloadData];
            });
        }];
}


#pragma mark - Delegate methods

- (void)viewSelected {
    SEL selector = @selector(topViewSelected);
    if ([self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector];
    }
}


#pragma mark - Notifications

- (void)registerOnCollectionViewNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(reloadAssets)
                               name:ALAssetsLibraryChangedNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(reloadAssets)
                               name:PBAssetManagerDidGetAccessToAssetsLibraryNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(reloadAssets)
                               name:kPBImportAssetsFinishedNotification
                             object:nil];
}

- (void)movedByDelta:(NSNotification *)notification {
    [super movedByDelta:notification];

    CGFloat delta = -[notification.userInfo[kPBDelta] floatValue];

    if (notification.object == self) {
        delta *= -1;
    }


    CGRect frame = self.frame;
    frame.origin.y += delta;

    if (frame.origin.y > 0) {
        frame.origin.y = 0;
    }

    self.frame = frame;
}

- (void)restored:(NSNotification *)notification {
    [super restored:notification];

    if (notification.object == self) {
        return;
    }

    CGRect frame = self.frame;
    frame.origin.y = 0;

    [UIView animateWithDuration:0.2
                     animations:^{
                         self.frame = frame;
                     }];
}

@end
