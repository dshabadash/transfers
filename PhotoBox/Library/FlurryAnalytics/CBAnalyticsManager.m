//
//  CBAnalyticsManager.m
//  Browser
//
//  Created by Andrew Kosovich on 7/20/12.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "CBAnalyticsManager.h"
#import "FlurryAnalytics.h"
#import "RDUsageTracker.h"

@interface CBAnalyticsManager () {
    NSMutableDictionary *_hostnameCache;
}

@end

@implementation CBAnalyticsManager

+ (id)sharedManager {
    static id sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
    });
    return sharedManager;
}

- (id)init {
    if ((self = [super init])) {
        _hostnameCache = [NSMutableDictionary new];
    }
    return self;
}

- (void)appStart {
    [Flurry startSession:PB_FLURRY_ID];
    
#ifdef DEBUG
    [RDUsageTracker sharedTracker].debugMode = YES;
#endif
    
    [[RDUsageTracker sharedTracker] appStart];
}

- (void)appEnterForeground {
    [self logEvent:@"WillEnterForeground"];
    [[RDUsageTracker sharedTracker] appEnterForeground];
}

- (void)rateThisAppWasOpened {
    [self logEvent:@"RateThisAppWasOpened"];
}

- (void)rateThisAppAnswer:(NSNumber *)result {
    NSDictionary *parameters = @{@"RateResult" : result};
    NSString *eventName = @"RateResult";

    [self logEvent:eventName withParameters:parameters];
}

- (void)logEvent:(NSString *)eventName {
    [Flurry logEvent:eventName];
}

- (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters {
    [Flurry logEvent:eventName withParameters:parameters];
}

- (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception {
    [Flurry logError:errorID message:message exception:exception];
}

- (void)logHostname:(NSString *)hostname {
    if ([hostname hasContent] == NO) {
        return;
    }
    
    BOOL skipEvent = NO;
    NSDate *lastEventDate = [_hostnameCache objectForKey:hostname];
    if (lastEventDate) {
        if ([NSDate timeIntervalSinceReferenceDate] - [lastEventDate timeIntervalSinceReferenceDate] < 30)
            skipEvent = YES;
    }
    else {
        if ([_hostnameCache count] > 100)
            [_hostnameCache removeAllObjects];
    }
    [_hostnameCache setObject:[NSDate date] forKey:hostname];
    
    if (skipEvent == NO) {
        [Flurry logEvent:@"visit" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: hostname, @"domain", nil]];
    }

    
}

@end
