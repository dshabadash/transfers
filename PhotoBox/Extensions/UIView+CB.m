//
//  UIView+CB.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 27/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "UIView+CB.h"

@implementation UIView (CB)

+ (id)view {
    NSString *className = NSStringFromClass(self);
    
    return  [[[NSBundle mainBundle] loadNibNamed:className] lastObject];
}

@end
