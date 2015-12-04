//
//  LSItunesRssFeedImage.h
//  iTunesAppVersion
//
//  Created by ameleshko on 12/24/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@interface LSItunesRssFeedImage : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSString *url;
@property (nonatomic, strong, readonly) NSString *height;

@end
