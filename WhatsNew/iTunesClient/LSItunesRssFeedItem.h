//
//  LSItunesRssFeedItem.h
//  iTunesAppVersion
//
//  Created by ameleshko on 12/24/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@interface LSItunesRssFeedItem : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSString *itemID;
@property (nonatomic, strong, readonly) NSString *title;//name - artist
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *artist;
@property (nonatomic, strong, readonly) NSString *releaseDate;
@property (nonatomic, strong, readonly) NSArray *images;

@end
