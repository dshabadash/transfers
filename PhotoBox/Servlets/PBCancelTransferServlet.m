//
//  PBCancelTransferServlet.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 4/8/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBCancelTransferServlet.h"
#import "PBMongooseServer.h"
#import "PBTransferSession.h"

@interface PBCancelTransferServlet () {
    NSDictionary *_headers;
}

@end

@implementation PBCancelTransferServlet

- (PBServletResponse *)doGet:(PBServletRequest *)request {
    _headers = [request.headers retain];

    [self cancelTransferSession];

    PBServletResponse *response = [[PBServletResponse new] autorelease];
    [response addHeader:@"Content-Type" withValue:@"text/html"];
    response.statusCode = @"200 OK";

    return response;
}

- (void)cancelTransferSession {
    PBTransferSession *session = [PBAppDelegate sharedDelegate].transferSession;

    // Check if device initiated cancel is device for active session
    NSString *deviceName = [_headers objectForKey:@"X-Device-Name"];
    BOOL deviceMatches = [deviceName isEqualToString:session.deviceName];

    if (nil != session && !session.isCanceled && deviceMatches) {
        [self sendTransferWasCanceledNotification];
        [[PBAppDelegate sharedDelegate] setTransferSession:nil];
    }
}

- (void)sendTransferWasCanceledNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *deviceName = [_headers objectForKey:@"X-Device-Name"];
        NSString *deviceType = [_headers objectForKey:@"X-Device-Type"];

        NSDictionary *userInfo = @{kPBDeviceName : deviceName,
                                   kPBDeviceType : deviceType};

        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBTransferWasCanceledNotification
            object:nil
            userInfo:userInfo];
    });
}

- (void)dealloc {
    [_headers release];
    _headers = nil;

    [super dealloc];
}

@end
