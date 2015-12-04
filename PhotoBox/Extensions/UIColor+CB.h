//
//  UIColor+CB.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 04/01/2013.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (CB)

+ (UIColor *)colorWithRGBA:(int)data;
+ (UIColor *)colorWithRGB:(int)data;

+ (UIColor *)defaultBackgroundColor;
+ (UIColor *)defaultTextColor;

+ (UIColor *)defaultTableViewCellBackgroundColor;
+ (UIColor *)defaultTableViewSeparatorColor;

@end
