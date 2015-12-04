//
//  PBStretchableImageView.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 10/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBStretchableImageView.h"

@implementation PBStretchableImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setImage:self.image];
}

- (void)setImage:(UIImage *)image {
    
    CGSize size = image.size;
    
    CGFloat horzCap = ceilf(size.width / 2.0) - 1.0;
    CGFloat vertCap = ceilf(size.height / 2.0) - 1.0;
    
    
    if (_horizontalCap) horzCap = [_horizontalCap floatValue];
    if (_verticalCap) vertCap = [_verticalCap floatValue];
    
    UIImage *resizableImage = [image stretchableImageWithLeftCapWidth:horzCap topCapHeight:vertCap];
    [super setImage:resizableImage];
}

@end
