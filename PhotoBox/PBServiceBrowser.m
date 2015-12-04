//
//  PBServiceBrowser.m
//  viewDiggerClient
//
//  Created by Andrew Kosovich on 19/04/2012.
//  Copyright (c) 2012 none. All rights reserved.
//

#import "PBServiceBrowser.h"

NSString * const PBServiceBrowserServicesDidUpdateNotification = @"PBServiceBrowserServicesDidUpdateNotification";
NSString * const PBServiceBrowserServicesDidRemoveServiceNotification = @"PBServiceBrowserServicesDidRemoveServiceNotification";

@interface PBServiceBrowser () <NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
    NSNetServiceBrowser *serviceBrowser;
    NSMutableSet *services;
    NSMutableArray *_servicesToResolve;
}

- (void)postUpdateNotification;

@end

@implementation PBServiceBrowser

- (id)init {
    if ((self = [super init])) {
        services = [NSMutableSet new];
        serviceBrowser = [NSNetServiceBrowser new];
        serviceBrowser.delegate = self;
        _servicesToResolve = [[NSMutableArray arrayWithCapacity:0] retain];
    }
    
    return self;
}

- (void)dealloc {
    [self stop];
    [serviceBrowser release];
    serviceBrowser = nil;

    [services release];
    services = nil;

    [_servicesToResolve release];
    _servicesToResolve = nil;

    [super dealloc];
}


#pragma mark -

- (void)start {
    [self postUpdateNotification];
    [self removeAllServices];
    [serviceBrowser searchForServicesOfType:PB_BONJOUR_SERVICE_TYPE inDomain:@""];
}

- (void)stop {
    [serviceBrowser stop];
    [self removeAllServices];
}

- (NSArray *)availableServiceNames {
    @synchronized(self) {
        NSMutableArray *serviceNames = [NSMutableArray arrayWithCapacity:[services count]];
        for (NSNetService *service in [[services copy] autorelease]) {
            [serviceNames addObject:[service name]];
        }
        
        return serviceNames;
    }
}

- (NSString *)serviceURLStringWithName:(NSString *)serviceName {
    @synchronized(self) {
        for (NSNetService *service in services) {
            if ([[service name] isEqualToString:serviceName]) {
                NSString *hostname = [service hostName];
                NSInteger port = [service port];
                
                if (hostname && port) {
                    NSString *urlString = [NSString stringWithFormat:@"http://%@:%ld/", hostname, (long)port];
                    return urlString;
                }
            }
        }
    }

    return nil;
}

- (NSString *)serviceDeviceNameWithName:(NSString *)serviceName {
    @synchronized(self) {
        for (NSNetService *service in services) {
            if ([[service name] isEqualToString:serviceName]) {
                NSDictionary *txtRecordDataDictionary = [NSNetService dictionaryFromTXTRecordData:service.TXTRecordData];
                NSData *deviceTypeData = txtRecordDataDictionary[kPBDeviceType];
                NSString *deviceType = [[[NSString alloc] initWithData:deviceTypeData encoding:NSUTF8StringEncoding] autorelease];
                return deviceType;
            }
        }
    }
    return nil;
}

- (void)removeService:(NSNetService *)service {
    @synchronized(self) {
        NSMutableSet *servicesToRemove = [NSMutableSet setWithCapacity:0];
        for (NSNetService *obj in services) {
            if ([[obj name] isEqualToString:[service name]]) {
                [servicesToRemove addObject:obj];
            }
        }

        [services minusSet:servicesToRemove];


        NSMutableArray *arrayToRemove = [NSMutableArray arrayWithCapacity:0];
        for (NSNetService *obj in services) {
            if ([[obj name] isEqualToString:[service name]]) {
                [servicesToRemove addObject:obj];
            }
        }

        [_servicesToResolve removeObjectsInArray:arrayToRemove];
    }
}

- (void)removeServices:(NSSet *)servicesToRemove {
    @synchronized(self) {
        for (NSNetService *service in servicesToRemove) {
            service.delegate = nil;
            [service stop];
        }

        [services minusSet:servicesToRemove];
        [_servicesToResolve removeObjectsInArray:[servicesToRemove allObjects]];
    }
}

- (void)removeAllServices {
    [self removeServices:services];
    [self removeServices:[NSSet setWithArray:_servicesToResolve]];
}

- (void)resolveAllServices {
    NSArray *listToResolve = [[_servicesToResolve copy] autorelease];
    for (NSNetService *service in listToResolve) {
        [service resolveWithTimeout:0.0];
    }
}


#pragma mark - Notificatins

- (void)postUpdateNotification {
    NSLog(@"ServiceBrowser did update");

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBServiceBrowserServicesDidUpdateNotification
            object:nil
            userInfo:nil];
    });
}

- (void)postDidRemoveServiceNotification:(NSString *)serviceName {
    NSDictionary *userInfo = @{@"serviceName": serviceName};

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBServiceBrowserServicesDidRemoveServiceNotification
            object:nil
            userInfo:userInfo];
    });
}


#pragma mark - NSNetServiceBrowserDelegate protocol

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {

    NSString *serviceName = [aNetService name];
    [self postDidRemoveServiceNotification:serviceName];
    [self removeService:aNetService];
    [self postUpdateNotification];
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing {
    if (![service.name isEqualToString:[PBAppDelegate serviceName]]) {
        [service retain];
        service.delegate = self;

        @synchronized(self) {
            [_servicesToResolve addObject:service];
        }
    }

    if (!moreComing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resolveAllServices];
        });
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
    [self postUpdateNotification];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
    [self postUpdateNotification];
}


#pragma mark - NSNetServiceDelegate protocol

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    [self removeService:sender];

    if ([_servicesToResolve count] == 0) {
        [self postUpdateNotification];
    }

    [sender release];
}

- (void)netServiceDidResolveAddress:(NSNetService *)service {
    [service retain];
    
    @synchronized(self) {
        NSLog(@"service resolved: %@ %ld", [service hostName], (long)[service port]);
        
        [services addObject:service];
        [_servicesToResolve removeObject:service];
    }

    if ([_servicesToResolve count] == 0) {
        [self postUpdateNotification];
    }

    [service release];
}

- (void)netServiceDidStop:(NSNetService *)sender {
    [self removeService:sender];

    NSLog(@"NetserviceDidStop: %@", sender);
    [self postUpdateNotification];
}

@end
