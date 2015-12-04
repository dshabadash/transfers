//
//  UIColor+LSAdditions.h
//  MyApp
//
//  Created by Artem Meleshko on 2/24/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (LSAdditions)

+ (instancetype)randomColor;

+ (instancetype)colorWithHexString:(NSString *)hexString;

+ (NSString *)hexValuesFromUIColor:(UIColor *)color;

+ (UIColor*)colorWithRGBA:(int)data;

+ (UIColor*)colorWithRGB:(int)data;


+ (instancetype)ios7BlackColor;

+ (instancetype)ios7DarkGrayColor;

+ (instancetype)ios7LightGrayColor;

+ (instancetype)ios7GrayColor;

+ (instancetype)ios7WhiteColor;

+ (instancetype)ios7GroupedTableColor;

+ (instancetype)ios7RedColor;

+ (instancetype)ios7DarkRedColor;

+ (instancetype)ios7GreenColor;

+ (instancetype)ios7BlueColor;

+ (instancetype)ios7LightBlueColor;

+ (instancetype)ios7DarkBlueColor;

+ (instancetype)ios7YellowColor;

+ (instancetype)ios7MagentaColor;

+ (instancetype)ios7OrangeColor;

+ (instancetype)ios7PurpleColor;

+ (instancetype)iOS7PinkColor;

+ (instancetype)ios7BrownColor;

@end
