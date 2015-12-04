//
//  UIImage+CB.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 16/01/2013.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "UIImage+CB.h"

@implementation UIImage (CB)

+ (UIImage *)imgNamed:(NSString *)imageName {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        NSString *ipadImageName = [[imageName stringByDeletingPathExtension] stringByAppendingString:@"-ipad"];
        UIImage *resultImage = [UIImage imageNamed:ipadImageName];
        if (resultImage) {
            return resultImage;
        }
    }
    
    return [UIImage imageNamed:imageName];
}

@end
