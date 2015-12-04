//
//  PBAssetGroupTableViewCell.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 08/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBAssetGroupTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface PBAssetGroupTableViewCell () {
    UIImageView *_assetFrameImageView;
    UIImageView *_accessoryImageView;
    
    UILabel *_assetCountLabel;
}

@end

@implementation PBAssetGroupTableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        UILabel *textLabel = self.textLabel;
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.textColor = [UIColor defaultTextColor];
        textLabel.shadowColor = [UIColor whiteColor];
        textLabel.shadowOffset = CGSizeMake(0, 1);
        
        _assetCountLabel = [[UILabel new] autorelease];
        _assetCountLabel.backgroundColor = [UIColor clearColor];
        _assetCountLabel.textColor = [UIColor colorWithRed:0.53f green:0.49f blue:0.44f alpha:1.00f];
        _assetCountLabel.shadowColor = [UIColor whiteColor];
        _assetCountLabel.shadowOffset = CGSizeMake(0, 1);
        [self.contentView addSubview:_assetCountLabel];
     
        
        self.accessoryView.backgroundColor = [UIColor clearColor];
        
        self.contentView.backgroundColor = [UIColor defaultBackgroundColor];
        
        
        UIImage *frameImage = [UIImage imageNamed:@"asset_frame"];
        frameImage = [frameImage stretchableImageWithLeftCapWidth:5 topCapHeight:5];
        _assetFrameImageView = [[[UIImageView alloc] initWithImage:frameImage] autorelease];
        [self addSubview:_assetFrameImageView];
        
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    CGSize size = bounds.size;
    CGFloat width = size.width;
//    CGFloat height = size.height;

    
    UIImageView *imageView = self.imageView;
    imageView.bounds = CGRectMake(0, 0, 43, 43);
    imageView.center = CGPointMake(36, 28);
   // imageView.layer.cornerRadius = 6.0;
  //  imageView.clipsToBounds = YES;

    
    CGPoint textLabelOrigin = self.textLabel.frame.origin;
    CGFloat textLabelX = textLabelOrigin.x;
    CGFloat assetCountLabelX = textLabelX + self.textLabel.textSize.width + 8;
    CGSize assetCountTextSize = _assetCountLabel.textSize;
    _assetCountLabel.frame = CGRectMake(assetCountLabelX, textLabelOrigin.y, assetCountTextSize.width, assetCountTextSize.height);

    _assetFrameImageView.frame = imageView.frame;
    [self bringSubviewToFront:_assetFrameImageView];
    
    _accessoryImageView.center = CGPointMake(width - 15, 30);
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType {
//    [super setAccessoryType:accessoryType];

    if (accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
        UIImage *accessoryImage = [UIImage imageNamed:@"album_list_detail_disclosure_indicator"];
        [_accessoryImageView removeFromSuperview];
        _accessoryImageView = [[[UIImageView alloc] initWithImage:accessoryImage] autorelease];
        [self.contentView addSubview:_accessoryImageView];
    } else {
        [super setAccessoryType:accessoryType];
    }
}

- (void)setAssetCount:(NSInteger)assetCount {
    _assetCount = assetCount;
    _assetCountLabel.text = [NSString stringWithFormat:@"(%ld)", (long)assetCount];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    
}

@end
