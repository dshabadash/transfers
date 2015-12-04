//
//  PBStretchableBackgroundButton.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 18/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBStretchableBackgroundButton.h"

@implementation PBStretchableBackgroundButton

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
    
    
    //reset images with overriden setBackgroundImage state
    NSArray *controlStates = @[
        @(UIControlStateNormal),
        @(UIControlStateHighlighted),
        @(UIControlStateDisabled),
        @(UIControlStateSelected)
    ];

    for (NSNumber *controlStateNum in controlStates) {
        UIControlState controlState = [controlStateNum integerValue];
        UIImage *bgImage = [self backgroundImageForState:controlState];
        [self setBackgroundImage:bgImage forState:controlState];
    }
}

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state {
    CGSize size = image.size;
    
    CGFloat horzCap = ceilf(size.width / 2.0) - 1.0;
    CGFloat vertCap = ceilf(size.height / 2.0) - 1.0;
    
    UIImage *resizableImage = [image stretchableImageWithLeftCapWidth:horzCap topCapHeight:vertCap];
    [super setBackgroundImage:resizableImage forState:state];
}

@end
