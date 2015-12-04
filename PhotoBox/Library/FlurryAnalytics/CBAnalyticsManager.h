//
//  CBAnalyticsManager.h
//  Browser
//
//  Created by Andrew Kosovich on 7/20/12.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBAnalyticsManager : NSObject

+ (id)sharedManager;

- (void)appStart;
- (void)appEnterForeground;
- (void)logHostname:(NSString *)hostname;
- (void)rateThisAppWasOpened;
- (void)rateThisAppAnswer:(NSNumber *)result;

- (void)logEvent:(NSString *)eventName;
- (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;
- (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception;

@end
