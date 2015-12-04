//
//  PBAssetPreviewCollectionCell.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 16/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBAssetPreviewCollectionCell : PSTCollectionViewCell
@property (readonly, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) BOOL isVideo;
@property (assign, nonatomic) BOOL orange;
@property (assign, nonatomic) BOOL faded;

//subclassing
@property (retain, nonatomic) IBOutlet UILabel *durationLabel;
@property (retain, nonatomic) IBOutlet UIImageView *frameImageView;
@property (retain, nonatomic) IBOutlet UIImageView *selectedImageView;
@property (retain, nonatomic) IBOutlet UIImageView *videoIndicatorView;
@property (retain, nonatomic) IBOutlet UIImageView *bottomBarBackgroundImage;
@property (copy, nonatomic) NSString *imageName;

- (void)setFaded:(BOOL)faded animated:(BOOL)animated;
- (void)setImage:(UIImage *)image;
- (void)setDuration:(NSTimeInterval)duration;

@end
