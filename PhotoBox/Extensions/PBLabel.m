//
//  PBLabel.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 26/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBLabel.h"

@implementation PBLabel

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
    
    int64_t delayInSeconds = 0.01;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self setupAppearance];
    });
}

- (void)setupAppearance {
    self.textColor = [UIColor colorWithRed:1.00f green:0.51f blue:0.27f alpha:1.00f];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
