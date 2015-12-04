//
//  UIColor+LSAdditions.m
//  MyApp
//
//  Created by Artem Meleshko on 2/24/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "UIColor+LSAdditions.h"

@implementation UIColor (LSAdditions)

+ (instancetype)randomColor{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

+ (instancetype)colorWithHexString:(NSString *)hexString {
    
    if ([hexString length] != 6) {
        return nil;
    }
    
    // Brutal and not-very elegant test for non hex-numeric characters
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-fA-F|0-9]" options:0 error:NULL];
    NSUInteger match = [regex numberOfMatchesInString:hexString options:NSMatchingReportCompletion range:NSMakeRange(0, [hexString length])];
    
    if (match != 0) {
        return nil;
    }
    
    NSRange rRange = NSMakeRange(0, 2);
    NSString *rComponent = [hexString substringWithRange:rRange];
    unsigned int rVal = 0;
    NSScanner *rScanner = [NSScanner scannerWithString:rComponent];
    [rScanner scanHexInt:&rVal];
    float rRetVal = (float)rVal / 254;
    
    
    NSRange gRange = NSMakeRange(2, 2);
    NSString *gComponent = [hexString substringWithRange:gRange];
    unsigned int gVal = 0;
    NSScanner *gScanner = [NSScanner scannerWithString:gComponent];
    [gScanner scanHexInt:&gVal];
    float gRetVal = (float)gVal / 254;
    
    NSRange bRange = NSMakeRange(4, 2);
    NSString *bComponent = [hexString substringWithRange:bRange];
    unsigned int bVal = 0;
    NSScanner *bScanner = [NSScanner scannerWithString:bComponent];
    [bScanner scanHexInt:&bVal];
    float bRetVal = (float)bVal / 254;
    
    return [UIColor colorWithRed:rRetVal green:gRetVal blue:bRetVal alpha:1.0f];
    
}

+ (NSString *)hexValuesFromUIColor:(UIColor *)color {
    
    if (!color) {
        return nil;
    }
    
    if (color == [UIColor whiteColor]) {
        // Special case, as white doesn't fall into the RGB color space
        return @"ffffff";
    }
    
    CGFloat red;
    CGFloat blue;
    CGFloat green;
    CGFloat alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int redDec = (int)(red * 255);
    int greenDec = (int)(green * 255);
    int blueDec = (int)(blue * 255);
    
    NSString *returnString = [NSString stringWithFormat:@"%02x%02x%02x", (unsigned int)redDec, (unsigned int)greenDec, (unsigned int)blueDec];
    
    return returnString;
    
}

+ (UIColor*)colorWithRGBA:(int)data {
	unsigned char r = data >> 24;
	unsigned char g = data >> 16;
	unsigned char b = data >> 8;
	unsigned char a = data;
	
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0];
}

+ (UIColor*)colorWithRGB:(int)data {
	unsigned char r = data >> 16;
	unsigned char g = data >> 8;
	unsigned char b = data;
	

	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}


+ (instancetype)ios7BlackColor{
    return [UIColor colorWithRGB:0x1f1f21];
}

+ (instancetype)ios7DarkGrayColor{
    return [UIColor colorWithRGB:0x8e8e93];
}

+ (instancetype)ios7LightGrayColor{
    return [UIColor colorWithRGB:0xeeeeee];
}

+ (instancetype)ios7GrayColor{
     return [UIColor colorWithRGB:0xc7c7c7];
}

+ (instancetype)ios7WhiteColor{
     return [UIColor colorWithRGB:0xf7f7f7];
}

+ (instancetype)ios7GroupedTableColor{
    return [UIColor colorWithRGB:0xefeff4];
}

+ (instancetype)ios7RedColor{
    return [UIColor colorWithRGB:0xff3b30];
}

+ (instancetype)ios7DarkRedColor{
    return [UIColor colorWithRGB:0xff1300];
}

+ (instancetype)ios7GreenColor{
    return [UIColor colorWithRGB:0x4cda64];
}

+ (instancetype)ios7BlueColor{
    return [UIColor colorWithRGB:0x59c9fb];
}

+ (instancetype)ios7LightBlueColor{
    return [UIColor colorWithRGB:0xd1eefc];
}

+ (instancetype)ios7DarkBlueColor{
    return [UIColor colorWithRGB:0x007bff];
}

+ (instancetype)ios7YellowColor{
    return [UIColor colorWithRGB:0xffcc00];
}

+ (instancetype)ios7MagentaColor{
    return [UIColor colorWithRGB:0xff4981];
}

+ (instancetype)ios7OrangeColor{
     return [UIColor colorWithRGB:0xff9500];
}

+ (instancetype)ios7PurpleColor{
    return [UIColor colorWithRGB:0xc644fc];
}

+ (instancetype)iOS7PinkColor{
    return [UIColor colorWithRed:1.0f green:0.17f blue:0.34f alpha:1.0f];
}

+ (instancetype)ios7BrownColor{
    return [UIColor colorWithRGB:0xd6cec3];
}



@end
