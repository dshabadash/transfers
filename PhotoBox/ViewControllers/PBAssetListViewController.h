//
//  PBAssetListViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 16/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PBAssetListViewController : PBViewController {
    ALAssetsGroup *_assetsGroup;
    PSTCollectionView *_collectionView;
}

@property (copy, nonatomic) NSURL *assetsGroupUrl;
@property (assign, nonatomic) CGSize itemSize;
@property (assign, nonatomic) CGFloat minimumLineSpacing;
@property (assign, nonatomic) CGFloat minimumInterItemSpacing;
@property (assign, nonatomic) UIEdgeInsets sectionInset;
@property (copy, nonatomic) NSString *cellNibName;
@property (assign, nonatomic) BOOL aspectThumbnail;

- (id)initWithAssetsGroup:(ALAssetsGroup *)group;
- (ALAssetsGroup *)assetsGroup;
- (void)scrollToBottom;
- (void)scrollToAsset:(ALAsset *)asset;

//for subclassing only
+ (UIBarButtonItem *)sendBarButtonItemTarget:(id)target action:(SEL)action;
+ (UIColor *)collectionViewBackgroundColor;
+ (UIView *)noAssetsViewWithRect:(CGRect)rect;
- (PSTCollectionView *)collectionViewWithFrame:(CGRect)frame layout:(PSTCollectionViewLayout *)layout;
- (PSTCollectionViewFlowLayout *)collectionViewLayout;
- (UINib *)collectionViewCellNib;
- (void)cancel;
- (void)reloadAssets;
- (void)registerOnNotifications;

@end
