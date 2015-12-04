//
//  PBPopoverBackgroundView.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 15/01/2013.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBPopoverBackgroundView.h"
#import "PBStretchableImageView.h"

@interface PBPopoverBackgroundView () {
    PBStretchableImageView *_borderImageView;
    UIImageView *_arrowImageView;
    
    CGFloat _arrowOffset;
    UIPopoverArrowDirection _arrowDirection;
}

@end

@implementation PBPopoverBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *borderImage = [UIImage imageNamed:@"popover_bg-ipad"];
        UIImage *arrowImage = [UIImage imageNamed:@"popover_arrow-ipad"];
        
        _borderImageView = [[[PBStretchableImageView alloc] initWithFrame:CGRectZero] autorelease];
        _borderImageView.image = borderImage;
        [self addSubview:_borderImageView];
        
        _arrowImageView = [[[UIImageView alloc] initWithImage:arrowImage] autorelease];
        [self addSubview:_arrowImageView];
        
    }
    return self;
}

+ (BOOL)wantsDefaultContentAppearance {
    return YES;
}

+ (UIEdgeInsets)contentViewInsets {
    return UIEdgeInsetsMake(3, 8, 8, 8);
}

+ (CGFloat)arrowHeight {
    return 20;
}

+ (CGFloat)arrowBase {
    return 34;
}

- (void)setArrowOffset:(CGFloat)arrowOffset {
    _arrowOffset = arrowOffset;
    
    [self setNeedsLayout];
}

- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection {
    _arrowDirection = arrowDirection;
    
    [self setNeedsLayout];
}

- (UIPopoverArrowDirection)arrowDirection {
    return UIPopoverArrowDirectionUp;
}

- (void)layoutSubviews {
//    BOOL horizontal = (_arrowDirection == UIPopoverArrowDirectionUp || _arrowDirection == UIPopoverArrowDirectionDown);
    
    CGRect bounds = self.bounds;
    CGSize size = bounds.size;
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    CGFloat arrowOverlap = 3;

    CGFloat arrowBase = [[self class] arrowBase];
    CGFloat arrowHeight = [[self class] arrowHeight];
    CGFloat arrowY = 0;
    CGFloat arrowX = (width/2) + _arrowOffset - (arrowBase/2);

    CGFloat borderX = 0;
    CGFloat borderY = arrowHeight - arrowOverlap;
    CGFloat borderWidth = width;
    CGFloat borderHeight = height - arrowHeight + arrowOverlap;
    
    CGRect arrowFrame = CGRectMake(arrowX, arrowY, arrowBase, arrowHeight);
    _arrowImageView.frame = arrowFrame;
    
    CGRect borderFrame = CGRectMake(borderX, borderY, borderWidth, borderHeight);
    _borderImageView.frame = borderFrame;
}

@end
