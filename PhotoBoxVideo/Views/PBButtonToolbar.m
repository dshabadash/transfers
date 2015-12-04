//
//  PBButtonToolbar.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/3/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBButtonToolbar.h"

@implementation PBButtonToolbar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (nil != self) {
        _button = [[[UIButton alloc] initWithFrame:self.bounds] autorelease];
        [self addSubview:_button];

        UIImage *shadowImage = [UIImage imageNamed:@"receive_bottom_shadow"];

        // TODO: Fix it!!!
        CGFloat width = 1024.0;
        CGRect shadowFrame = CGRectMake(0,
                                        -shadowImage.size.height,
                                        width,
                                        shadowImage.size.height);
        
        PBStretchableImageView *shadowImageView = [[[PBStretchableImageView alloc] initWithFrame:shadowFrame] autorelease];
        [shadowImageView setImage:shadowImage];
        //[self addSubview:shadowImageView];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [_button setFrame:self.bounds];
}

@end
