//
//  PBPhotoBar.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 16/11/2012.
//  Changed by Viacheslav Savchenko on 17/5/13
//
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBPhotoBar.h"
#import "PBAssetPreviewCollectionCell.h"
#import "PBAssetManager.h"

static NSString * const cellIdentifier = @"AssetPreviewCell";
NSString * const PBPhotoBarDidSelectAssetUrlNotification = @"PBPhotoBarDidSelectAssetUrlNotification";

@interface PBPhotoBar () {
    PSTCollectionView *_collectionView;
    NSMutableOrderedSet *_assetUrls;
    NSMutableArray *_exportAssetsUrls;
    
    UIImageView *_normalShadowImageView;
    UIImageView *_boldShadowImageView;
    UILabel *_noAssetsLabel;
}

@end

@implementation PBPhotoBar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.clipsToBounds = NO;
        
        _assetUrls = [NSMutableOrderedSet new];
        _exportAssetsUrls = [[NSMutableArray arrayWithCapacity:0] retain];

        _collectionView = [[self class] collectionViewWithFrame:self.bounds];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;

        UIView *backgroundView = [[self class] backgroundViewWithFrame:self.frame];
        [_collectionView setBackgroundView:backgroundView];
        
        UINib *cellNib = [[self class] collectionViewCellNib];
        [_collectionView registerNib:cellNib forCellWithReuseIdentifier:cellIdentifier];

        [self addSubview:_collectionView];

        
        _noAssetsLabel = [[self class] noAssetsLabelWithFrame:self.bounds];
        [self addSubview:_noAssetsLabel];

        _normalShadowImageView = [[self class] normalShadowImageInRect:self.bounds];
        [self addSubview:_normalShadowImageView];

        _boldShadowImageView = [[self class] boldShadowImageInRect:self.bounds];
        [self addSubview:_boldShadowImageView];
        
        [self registerOnNotifications];
    }

    return self;
}


#pragma mark - Appearance

+ (UIImageView *)normalShadowImageInRect:(CGRect)rect {
    UIImage *normalShadowImage = [UIImage imageNamed:@"picked_assets_bar_shadow"];

    CGRect shadowFrame = CGRectMake(0,
                                    rect.size.height,
                                    rect.size.width,
                                    normalShadowImage.size.height);
    
    UIImageView *normalShadowImageView = [[[UIImageView alloc] initWithFrame:shadowFrame] autorelease];
    normalShadowImageView.image = normalShadowImage;
    normalShadowImageView.alpha = 0;

    normalShadowImageView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                              UIViewAutoresizingFlexibleWidth);


    return normalShadowImageView;
}

+ (UIImageView *)boldShadowImageInRect:(CGRect)rect {
    UIImage *normalShadowImage = [UIImage imageNamed:@"picked_assets_bar_bold_shadow"];

    CGRect shadowFrame = CGRectMake(0,
                                    rect.size.height,
                                    rect.size.width,
                                    normalShadowImage.size.height);

    UIImageView *normalShadowImageView = [[[UIImageView alloc] initWithFrame:shadowFrame] autorelease];
    normalShadowImageView.image = normalShadowImage;
    normalShadowImageView.alpha = 0;

    normalShadowImageView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                              UIViewAutoresizingFlexibleWidth);


    return normalShadowImageView;
}

+ (UILabel *)noAssetsLabelWithFrame:(CGRect)frame {
    UILabel *noAssetsLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    [noAssetsLabel setupAppearance];
    noAssetsLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight);

    noAssetsLabel.textAlignment = NSTextAlignmentCenter;
    noAssetsLabel.adjustsFontSizeToFitWidth = YES;
    noAssetsLabel.text = NSLocalizedString(@"Choose photos to send", @"");

    CGFloat choosePhotosFontSize = 20.0;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        choosePhotosFontSize = 30.0;
    }
    
    noAssetsLabel.font = [UIFont systemFontOfSize:choosePhotosFontSize];
    [noAssetsLabel setMinimumScaleFactor:9.0/choosePhotosFontSize];
    
    return noAssetsLabel;
}


+ (PSTCollectionView *)collectionViewWithFrame:(CGRect)frame {
    PSTCollectionViewFlowLayout *collectionViewLayout = [[[PSTCollectionViewFlowLayout alloc] init] autorelease];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        //ipad
        collectionViewLayout.itemSize = CGSizeMake(75, 75);
        collectionViewLayout.minimumLineSpacing = 23;
        collectionViewLayout.minimumInteritemSpacing = 23;
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(14, 14, 14, 14);
    } else {
        //iphone
        collectionViewLayout.itemSize = CGSizeMake(44, 44);
        collectionViewLayout.minimumLineSpacing = 4;
        collectionViewLayout.minimumInteritemSpacing = 4;
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(5, 4, 4, 4);
    }

    collectionViewLayout.scrollDirection = PSTCollectionViewScrollDirectionHorizontal;

    PSTCollectionView *collectionView = [[[PSTCollectionView alloc] initWithFrame:frame
        collectionViewLayout:collectionViewLayout] autorelease];

    
    collectionView.backgroundColor = [UIColor defaultBackgroundColor];
    collectionView.alwaysBounceHorizontal = YES;
    collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight);

    return collectionView;
}

+ (UINib *)collectionViewCellNib {
    UINib *nib = [UINib nibWithNibName:@"PBAssetPreviewCollectionCell" bundle:nil];

    return nib;
}

+ (UIView *)backgroundViewWithFrame:(CGRect)frame {
    return nil;
}


#pragma mark - Notifications

- (void)registerOnNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(assetManagerDidAddAsset:)
                               name:PBAssetManagerDidAddAssetNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(assetManagerDidRemoveAsset:)
                               name:PBAssetManagerDidRemoveAssetNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(assetManagerDidRemoveAllAssets:)
                               name:PBAssetManagerDidRemoveAllAssetsNotification
                             object:nil];
}


#pragma mark - Adding and removing assets

- (void)assetManagerDidAddAsset:(NSNotification *)notification {
    NSURL *assetUrl = notification.userInfo[kPBAssetUrl];

    [_exportAssetsUrls removeAllObjects];
    [_exportAssetsUrls addObjectsFromArray:[[PBAssetManager sharedManager] assetExportList]];

    [_assetUrls insertObject:assetUrl atIndex:0];
    
    NSIndexPath *newItemIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [_collectionView insertItemsAtIndexPaths:@[newItemIndexPath]];
    [_collectionView scrollToItemAtIndexPath:newItemIndexPath
                            atScrollPosition:PSTCollectionViewScrollPositionLeft
                                    animated:YES];
    
    [self updateNoAssetLabelVisibility];
}

- (void)assetManagerDidRemoveAsset:(NSNotification *)notification {
    NSURL *assetUrl = notification.userInfo[kPBAssetUrl];

    NSUInteger indexOfObjectToRemove =
        [_exportAssetsUrls indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            *stop = [obj isEqual:assetUrl];
            return *stop;
        }];

    if (NSNotFound != indexOfObjectToRemove) {
        [_exportAssetsUrls removeObjectAtIndex:indexOfObjectToRemove];
    }

    NSInteger index = [_assetUrls indexOfObject:assetUrl];
    if (index != NSNotFound) {
        [_assetUrls removeObjectAtIndex:index];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        [_collectionView deleteItemsAtIndexPaths:@[indexPath]];

        if ([_assetUrls count] > 0) {
            [_collectionView scrollToItemAtIndexPath:indexPath
                                    atScrollPosition:PSTCollectionViewScrollPositionRight
                                            animated:YES];
        }
    }
    
    [self updateNoAssetLabelVisibility];
}

- (void)assetManagerDidRemoveAllAssets:(NSNotification *)notification {
    [_assetUrls removeAllObjects];
    [_exportAssetsUrls removeAllObjects];
    
    [_collectionView reloadData];
    [self updateNoAssetLabelVisibility];
}

- (void)updateNoAssetLabelVisibility {
    BOOL hasAssets = _assetUrls.count != 0;
    [UIView animateWithDuration:0.2
                     animations:^{
                         _noAssetsLabel.alpha = hasAssets ? 0 : 1;
                     }];
}


#pragma mark - CollectionView

- (NSInteger)collectionView:(PSTCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _assetUrls.count;
}

- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PBAssetPreviewCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.layer.cornerRadius = 4.0;
    cell.layer.masksToBounds = YES;
    
    NSAssert(cell, @"No cell");
    
    NSInteger assetIndex = indexPath.item;
    NSURL *assetUrl = [_assetUrls objectAtIndex:assetIndex];

    if (_showFreeToSendPhotosOnly && ![_exportAssetsUrls containsObject:assetUrl]) {
        cell.faded = YES;
    } else {
        cell.faded = NO;
    }


    ALAssetsLibrary *assetsLibrary = PBAssetsLibrary;
    [assetsLibrary assetForURL:assetUrl
        resultBlock:^(ALAsset *asset) {
            if (asset) {
                UIImage *thumbnail = [UIImage imageWithCGImage:asset.thumbnail];
                cell.imageView.image = thumbnail;
                cell.isVideo = [asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo;
                cell.imageName = asset.defaultRepresentation.filename;
                

            }
        }
        failureBlock:^(NSError *error) {
            //TODO: hamdle error
            cell.imageView.image = nil;
            cell.imageView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
        }];


    return cell;
}

- (BOOL)collectionView:(PSTCollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *assetUrl = [_assetUrls objectAtIndex:indexPath.item];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:PBPhotoBarDidSelectAssetUrlNotification
        object:assetUrl];

    return NO;
}


#pragma mark - Properties

- (void)setShadowStrength:(NSInteger)shadowStrength {
    [self setShadowStrength:shadowStrength animated:NO];
}

- (void)setShadowStrength:(NSInteger)shadowStrength animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? 0.3 : 0
                     animations:^{
                         if (shadowStrength == 0) {
                             _normalShadowImageView.alpha = 0;
                             _boldShadowImageView.alpha = 0;
                         } else if (shadowStrength == 1) {
                             _normalShadowImageView.alpha = 1;
                             _boldShadowImageView.alpha = 0;
                         } else {
                             _normalShadowImageView.alpha = 0;
                             _boldShadowImageView.alpha = 1;
                         }
                     }];
}

- (void)setShowFreeToSendPhotosOnly:(BOOL)showFreeToSendPhotosOnly {
#if PB_LITE
    if ([[PBAppDelegate sharedDelegate] isFullVersion]) {
        showFreeToSendPhotosOnly = NO;
    }
    
    if (_showFreeToSendPhotosOnly != showFreeToSendPhotosOnly) {
        _showFreeToSendPhotosOnly = showFreeToSendPhotosOnly;
        
        for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems) {
            NSInteger assetIndex = indexPath.item;
            NSURL *assetUrl = [_assetUrls objectAtIndex:assetIndex];
            
            PBAssetPreviewCollectionCell *cell = (PBAssetPreviewCollectionCell *)[_collectionView cellForItemAtIndexPath:indexPath];
            if (_showFreeToSendPhotosOnly && ![_exportAssetsUrls containsObject:assetUrl]) {
                [cell setFaded:YES animated:YES];
            } else {
                [cell setFaded:NO animated:YES];
            }
        }
    }
#endif
}


#pragma mark - Memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_assetUrls removeAllObjects];
    [_assetUrls release];
    _assetUrls = nil;

    [_exportAssetsUrls removeAllObjects];
    [_exportAssetsUrls release];
    _exportAssetsUrls = nil;

    [super dealloc];
}

@end
