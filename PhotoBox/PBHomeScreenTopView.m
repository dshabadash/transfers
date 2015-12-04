//
//  PBHomeScreenTopView.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 10/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBHomeScreenTopView.h"
#import "PSTCollectionView.h"
#import "PBAssetPreviewCollectionViewDataSource.h"

@interface PBHomeScreenTopView ()
@property (retain, nonatomic) IBOutlet UILabel *sendLabel;
@property (retain, nonatomic) IBOutlet PSTCollectionView *collectionView;
@property (retain, nonatomic) PBAssetPreviewCollectionViewDataSource *dataSource;
@end

@implementation PBHomeScreenTopView

- (void)awakeFromNib {
    [super awakeFromNib];

    // TODO: get rid of it
    // This is done because of appearence proxy for UILabel
    double delayInSeconds = 0.016;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.sendLabel.textColor = [UIColor whiteColor];
        self.sendLabel.shadowColor = [UIColor colorWithRed:0.84f green:0.43f blue:0.25f alpha:1.00f];
    });

    [_collectionView setUserInteractionEnabled:NO];

    
    UINib *nib = [UINib nibWithNibName:@"PBAssetPreviewCollectionCell" bundle:nil];
    [_collectionView registerNib:nib forCellWithReuseIdentifier:kPBAssetPreviewCollectionCellIdentifier];
    

    _collectionView.frame = CGRectMake(_collectionView.frame.origin.x,
                                        20.0,
                                        _collectionView.frame.size.width,
                                        _collectionView.frame.size.height);
    
    _collectionView.contentMode = UIViewContentModeTop | UIViewContentModeBottom;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
  
    //make sure we always show last row filled with pictures

    NSRange assetsRange = NSMakeRange(0, 0);
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        assetsRange.length = 28;
    }
    else {
        assetsRange.length = 8;
    }

    self.dataSource =
        [[[PBAssetPreviewCollectionViewDataSource alloc] initWithAssetGroup:nil
            range:assetsRange]
        autorelease];

    _collectionView.dataSource = self.dataSource;
    
    PSTCollectionViewFlowLayout *collectionViewLayout = [[PSTCollectionViewFlowLayout new] autorelease];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        collectionViewLayout.itemSize = CGSizeMake(75, 75);
        collectionViewLayout.minimumLineSpacing = 20;
        collectionViewLayout.minimumInteritemSpacing = 15;
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(4, 12, 4, 12);
    } else {
        collectionViewLayout.itemSize = CGSizeMake(70, 70);
        collectionViewLayout.minimumLineSpacing = 8;
        collectionViewLayout.minimumInteritemSpacing = 5;
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(4, 12, 4, 12);
    }

    [_collectionView setCollectionViewLayout:collectionViewLayout];
    
    [self registerOnCollectionViewNotifications];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self reloadAssets];
    });
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
