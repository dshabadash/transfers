//
//  PBServiceBrowser.h
//  viewDiggerClient
//
//  Created by Andrew Kosovich on 19/04/2012.
//  Copyright (c) 2012 none. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PBServiceBrowserServicesDidUpdateNotification;
extern NSString * const PBServiceBrowserServicesDidRemoveServiceNotification;

@interface PBServiceBrowser : NSObject

- (void)start;
- (void)stop;

- (NSArray *)availableServiceNames;

- (NSString *)serviceURLStringWithName:(NSString *)serviceName;
- (NSString *)serviceDeviceNameWithName:(NSString *)serviceName;

@end
