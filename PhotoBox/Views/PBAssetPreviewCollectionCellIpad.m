//
//  PBAssetPreviewCollectionCellIpad.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 14/01/2013.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBAssetPreviewCollectionCellIpad.h"

@implementation PBAssetPreviewCollectionCellIpad

- (void)awakeFromNib {
    [super awakeFromNib];
    
    //TODO: replace with actual frame image
    self.frameImageView.image = [[UIImage imageNamed:@"asset_list_asset_frame-ipad"] stretchableImageWithLeftCapWidth:8
                                                                                                         topCapHeight:8];
//    self.frameImageView.backgroundColor = [UIColor whiteColor];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIImage *image = self.imageView.image;
    
    if (image) {
        CGRect bounds = self.bounds;
        CGSize size = bounds.size;
        CGFloat width = size.width;
        CGFloat height = size.height;

        CGPoint center = CGPointMake((int)(width / 2), (int)(height / 2));
        
        CGSize imageSize = image.size;
        CGFloat scaleFactor = (width-20) / MAX(imageSize.width, imageSize.height);
        imageSize.width *= scaleFactor;
        imageSize.height *= scaleFactor;
        
        CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
        
        self.imageView.bounds = imageRect;
        self.imageView.center = PBCenter(center);

        CGRect durationViewFrame = self.imageView.frame;
        durationViewFrame.size.height = self.bottomBarBackgroundImage.bounds.size.height;
        durationViewFrame.origin.y = CGRectGetMaxY(self.imageView.frame) - durationViewFrame.size.height;

        [self.bottomBarBackgroundImage setFrame:durationViewFrame];

        CGRect frameRect = CGRectInset(self.imageView.frame, -10, -10);
        frameRect.origin.x += 1;
        frameRect.origin.y += 1;
        self.frameImageView.frame = frameRect;
        
        CGRect videoIndicatorFrame = self.videoIndicatorView.bounds;
        videoIndicatorFrame.origin.x = CGRectGetMinX(self.imageView.frame) + 4.0;
        videoIndicatorFrame.origin.y = CGRectGetMaxY(self.imageView.frame) - videoIndicatorFrame.size.height - 4.0;
        [self.videoIndicatorView setFrame:videoIndicatorFrame];

        self.durationLabel.center = self.videoIndicatorView.center;
        CGRect durationLabelFrame = self.durationLabel.frame;
        durationLabelFrame.size.width = CGRectGetMaxX(self.imageView.frame) - CGRectGetMaxX(self.videoIndicatorView.frame) - 8.0;
        durationLabelFrame.origin.x = CGRectGetMaxX(self.videoIndicatorView.frame) + 4.0;
        [self.durationLabel setFrame:durationLabelFrame];

        CGPoint selectedIndicatorCenter = center;
        selectedIndicatorCenter.x += (imageSize.width / 2) - 14;
        selectedIndicatorCenter.y += (imageSize.height / 2) - 13;
        self.selectedImageView.center = PBCenter(selectedIndicatorCenter);
    }
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = nil;
    [super setImage:image];
    
    [self setNeedsLayout];
}

@end
