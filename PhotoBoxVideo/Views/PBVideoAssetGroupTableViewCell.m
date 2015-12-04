//
//  PBVideoAssetGroupTableViewCell.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/17/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBVideoAssetGroupTableViewCell.h"

@interface PBVideoAssetGroupTableViewCell ()
@property (nonatomic, retain) IBOutlet UIView *imageViewContainer;
@property (nonatomic, retain) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, retain) IBOutlet UILabel *groupTextLabel;
@end

@implementation PBVideoAssetGroupTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.accessoryType = UITableViewCellAccessoryNone;
    self.selectedBackgroundView = [[self class] selectedBackgroundViewWithFrame:self.bounds];
}

- (void)setGroupLabelText:(NSString *)text {
    _groupTextLabel.text = text;
}

- (void)setThumbnailImage:(UIImage *)image {
    _thumbnailImageView.image = image;
}

+ (UIView *)selectedBackgroundViewWithFrame:(CGRect)frame {
    UIView *view = [[[UIView alloc] initWithFrame:frame] autorelease];
    view.backgroundColor = [UIColor colorWithRGB:0xf5f5f5];

    return view;
}

@end
