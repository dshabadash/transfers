//
//  PBStretchableImageView.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 10/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBStretchableImageView : UIImageView


//set any of these to override default half-1 cap size
@property (retain, nonatomic) NSNumber *horizontalCap;
@property (retain, nonatomic) NSNumber *verticalCap;

@end
