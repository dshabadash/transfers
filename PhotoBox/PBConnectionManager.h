//
//  PBConnectionManager.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 26/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PBConnectionManagerPermanentUrlDidChangeNotification;

@interface PBConnectionManager : NSObject

+ (void)start;
+ (id)sharedManager;

- (BOOL)isRetrievePermanentUrlInProgress;
- (NSString *)permanentUrlString; //returns http://pb.com/permanentId or nil
- (NSString *)localUrlString; //returns http://pb.com/permanentId or http://192.168.0.101:8989 or nil
- (NSString *)deviceIndentifier;

@end
