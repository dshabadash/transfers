//
//  UIImage+LSAdditions.h
//  MyApp
//
//  Created by Artem Meleshko on 2/11/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (LSAdditions)

+ (UIImage *)imageWithColor:(UIColor *)bgColor size:(CGSize)imageSize;

+ (UIImage *)imageWithStartColor:(UIColor *)startColor
                        endColor:(UIColor *)endColor
                      isVertical:(BOOL)isVertical
                            size:(CGSize)imageSize;

+ (UIImage *)templateImageNamed:(NSString *)name;

- (UIImage*)stretchableImage;

- (UIImage *)maskWithColor:(UIColor *)color;

@end
