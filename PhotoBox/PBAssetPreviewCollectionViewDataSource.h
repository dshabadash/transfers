//
//  PSTCollectionViewDataSource.h
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/10/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBAssetManager.h"
#import "PBAssetPreviewCollectionCell.h"

extern NSString * const kPBAssetPreviewCollectionCellIdentifier;

@interface PBAssetPreviewCollectionViewDataSource : NSObject<PSTCollectionViewDataSource>
@property (retain, nonatomic) ALAssetsGroup *assetsGroup;
@property (assign, readonly, nonatomic) NSRange assetRange;

// Range location is number of assets from the end of assets list in given assetGroup
- (id)initWithAssetGroup:(ALAssetsGroup *)assetGroup range:(NSRange)range;

@end
