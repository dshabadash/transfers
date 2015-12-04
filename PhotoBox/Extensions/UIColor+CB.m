//
//  UIColor+CB.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 04/01/2013.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "UIColor+CB.h"

@implementation UIColor (CB)

+ (UIColor *)colorWithRGBA:(int)data {
	unsigned char r = data >> 24;
	unsigned char g = data >> 16;
	unsigned char b = data >> 8;
	unsigned char a = data;
	
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0];
}


+ (UIColor *)colorWithRGB:(int)data {
	unsigned char r = data >> 16;
	unsigned char g = data >> 8;
	unsigned char b = data;
	
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

#pragma mark - Predefined Colors

+ (UIColor *)defaultBackgroundColor {
    return [UIColor colorWithRGB:0xfaf4ec];
}

+ (UIColor *)defaultTextColor {
    return [UIColor colorWithRGB:0x505050];
}

+ (UIColor *)defaultTableViewCellBackgroundColor {
    return [UIColor colorWithRGB:0xeee9e3];
}

+ (UIColor *)defaultTableViewSeparatorColor {
    return [UIColor colorWithRGB:0xababab];
}

@end
