//
//  PBPhotoBar.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 16/11/2012.
//  Changed by Viacheslav Savchenko on 17/5/13
//
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const PBPhotoBarDidSelectAssetUrlNotification;

@interface PBPhotoBar : UIView<PSTCollectionViewDataSource, PSTCollectionViewDelegate>
@property (assign, nonatomic) NSInteger shadowStrength;
@property (assign, nonatomic) BOOL showFreeToSendPhotosOnly;

+ (UIImageView *)normalShadowImageInRect:(CGRect)rect;
+ (UIImageView *)boldShadowImageInRect:(CGRect)rect;
+ (UILabel *)noAssetsLabelWithFrame:(CGRect)frame;
+ (PSTCollectionView *)collectionViewWithFrame:(CGRect)frame;
+ (UINib *)collectionViewCellNib;
+ (UIView *)backgroundViewWithFrame:(CGRect)frame;

- (void)registerOnNotifications;
- (void)setShadowStrength:(NSInteger)shadowStrength animated:(BOOL)animated;

@end
