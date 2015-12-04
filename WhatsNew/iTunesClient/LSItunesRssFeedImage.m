//
//  LSItunesRssFeedImage.m
//  iTunesAppVersion
//
//  Created by ameleshko on 12/24/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "LSItunesRssFeedImage.h"

@implementation LSItunesRssFeedImage

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"url" : @"label",
             @"height" : @"attributes.height",
             };
    
}

@end
