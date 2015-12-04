//
//  PSTCollectionViewDataSource.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/10/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBAssetPreviewCollectionViewDataSource.h"

NSString * const kPBAssetPreviewCollectionCellIdentifier = @"AssetPreviewCell";

@interface PBAssetPreviewCollectionViewDataSource () {
    NSRange _realRange;
}

@end

@implementation PBAssetPreviewCollectionViewDataSource

- (id)initWithAssetGroup:(ALAssetsGroup *)assetGroup range:(NSRange)range {
    self = [super init];

    if (nil != self) {
        _assetsGroup = [assetGroup retain];
        _assetRange = range;
    }

    return self;
}

- (void)dealloc {
    [_assetsGroup release];
    _assetsGroup = nil;

    [super dealloc];
}

- (NSRange)realRange {
    NSRange realRange = NSMakeRange(0, 0);
    NSInteger numberOfAssets = _assetsGroup.numberOfAssets;

    realRange.location = (_assetRange.location > numberOfAssets)
        ? numberOfAssets
        : _assetRange.location;

    realRange.length = ((_realRange.location + _assetRange.length) > numberOfAssets)
        ? numberOfAssets - _realRange.location
        : _assetRange.length;

    return realRange;
}


#pragma mark - CollectionViewDataSource protocol

- (NSInteger)collectionView:(PSTCollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section {

    NSRange range = (nil == self.assetsGroup) ? _assetRange : [self realRange];

    return range.length;
}

- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView
    cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    PBAssetPreviewCollectionCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:kPBAssetPreviewCollectionCellIdentifier
                                                  forIndexPath:indexPath];

    NSAssert(cell, @"No cell");

    cell.orange = YES;

    if (nil == _assetsGroup) {
        cell.isVideo = NO;
        cell.imageView.alpha = 1.0;
        
        return cell;
    }

    //do not update with old AssetsGroup object in iOS5 after AssetsLibraryChanged
    ALAssetsGroup *assetsGroup = _assetsGroup;
    NSInteger numberOfAssets = assetsGroup.numberOfAssets;
    NSRange range = [self realRange];
    NSInteger assetIndex = numberOfAssets - range.location - range.length + indexPath.item;

    if ((assetIndex < 0) || (assetIndex >= numberOfAssets)) {
        cell.isVideo = NO;
        cell.imageView.alpha = 1.0;

        return cell;
    }

    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:assetIndex];

    [assetsGroup enumerateAssetsAtIndexes:indexSet
        options:0
        usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
           if (result) {
               UIImage *thumbnail = [UIImage imageWithCGImage:result.thumbnail
                                                        scale:[[UIScreen mainScreen] scale]
                                                  orientation:UIImageOrientationUp];

               BOOL isVideo = [result valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo;
               NSTimeInterval duration = isVideo ? [[result valueForProperty:ALAssetPropertyDuration] doubleValue] : 0.0;

               dispatch_async(dispatch_get_main_queue(), ^{
                   PBAssetPreviewCollectionCell *cellToUpdate =
                   (PBAssetPreviewCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];

                   cellToUpdate.imageView.alpha = 0;
                   cellToUpdate.imageView.image = thumbnail;
                   cellToUpdate.isVideo = isVideo;
                   
                   if (isVideo) {
                       [cellToUpdate setDuration:duration];
                   }
                   
                   [UIView animateWithDuration:0.2
                                    animations:^{
                                        cell.imageView.alpha = 1;
                                    }];

                   cellToUpdate.imageName = result.defaultRepresentation.filename;
               });
           }
        }];

    
    return cell;
}

@end
