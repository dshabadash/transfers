//
//  UIImage+LSAdditions.m
//  MyApp
//
//  Created by Artem Meleshko on 2/11/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "UIImage+LSAdditions.h"
#import <QuartzCore/QuartzCore.h>


@implementation UIImage (LSAdditions)

+ (UIImage *)imageWithColor:(UIColor *)bgColor size:(CGSize)imageSize{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, imageSize.width,imageSize.height)];
    view.backgroundColor = bgColor;
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[UIScreen mainScreen] scale]);
    [view.layer renderInContext: UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageWithStartColor:(UIColor *)startColor endColor:(UIColor *)endColor isVertical:(BOOL)isVertical size:(CGSize)imageSize{

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, imageSize.width,imageSize.height)];

    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[UIScreen mainScreen] scale]);

    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();

    size_t gradientNumberOfLocations = 2;
    CGFloat gradientLocations[2] = { 0.0, 1.0 };
    
    CGFloat r0;
    CGFloat b0;
    CGFloat g0;
    CGFloat a0;
    
    CGFloat r1;
    CGFloat b1;
    CGFloat g1;
    CGFloat a1;
    
    [startColor getRed:&r0 green:&g0 blue:&b0 alpha:&a0];
    [endColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];

    CGFloat gradientComponents[8] = { r0, g0, b0, a0,     // Start color
        r1, g1, b1, a1, };  // End color
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents (colorspace, gradientComponents, gradientLocations, gradientNumberOfLocations);
    
    if(isVertical){
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, imageSize.height), 0);
    }
    else{
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(imageSize.width, 0), 0);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)templateImageNamed:(NSString *)name{
    return [[UIImage imageNamed:name] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (UIImage*)stretchableImage{
    return [self resizableImageWithCapInsets:UIEdgeInsetsMake(self.size.height/2, self.size.width/2, self.size.height/2, self.size.width/2)
                                resizingMode:UIImageResizingModeStretch];
}

- (UIImage *)maskWithColor:(UIColor *)color{
    
    CGImageRef maskImage = self.CGImage;

    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat width = self.size.width * scale;
    CGFloat height = self.size.height * scale;
    
    CGRect bounds = CGRectMake(0,0,width,height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    CGContextClipToMask(bitmapContext, bounds, maskImage);
    CGContextSetFillColorWithColor(bitmapContext, color.CGColor);
    CGContextFillRect(bitmapContext, bounds);
    
    CGImageRef cImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage *coloredImage = [UIImage imageWithCGImage:cImage scale:scale orientation:self.imageOrientation];
    
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(cImage);
    
    return coloredImage;
}

@end
