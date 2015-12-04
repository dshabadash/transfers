//
//  LSItunesRssFeedItem.m
//  iTunesAppVersion
//
//  Created by ameleshko on 12/24/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "LSItunesRssFeedItem.h"
#import "LSItunesRssFeedImage.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"

@implementation LSItunesRssFeedItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"images" : @"im:image",
             @"name" : @"im:name.label",
             @"title" : @"title.label",
             @"itemID" : @"id.attributes.im:id",
             @"artist" : @"im:artist.label",
             @"releaseDate" : @"im:releaseDate.label",
             };
}


+ (NSValueTransformer *)imagesJSONTransformer{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[LSItunesRssFeedImage class]];
}

@end
