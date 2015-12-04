//
//  PBBeginTransferServlet.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 4/8/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBBeginTransferServlet.h"
#import "PBTransferProgressViewController.h"
#import "PBMongooseServer.h"
#import "PBTransferSession.h"
#import "pbmongoose.h"
#include <arpa/inet.h>

@implementation PBBeginTransferServlet

+ (NSString *)stringWithInAddr:(struct in_addr)ipAddress {
    NSString *reversAddress = [NSString stringWithCString:inet_ntoa(ipAddress)
                                                 encoding:NSUTF8StringEncoding];

    NSArray *addressComponents = [reversAddress componentsSeparatedByString:@"."];
    NSMutableArray *orderedComponents = [NSMutableArray arrayWithCapacity:0];
    NSEnumerator *reversEnumerator = [addressComponents reverseObjectEnumerator];
    NSString *component;
    while (nil != (component = [reversEnumerator nextObject])) {
        [orderedComponents addObject:component];
    }

    NSString *address = [orderedComponents componentsJoinedByString:@"."];

    return address;
}

- (PBServletResponse *)doGet:(PBServletRequest *)request {
    PBServletResponse *response = [[PBServletResponse new] autorelease];
    [response addHeader:@"Content-Type" withValue:@"text/html"];

    // Check application state.
    // In case "Wait for connection"
    //  Send "Accepted" in responce.
    //  Start transfer session and send notification to present
    //  PBTransferProgressViewController with state PBTransferProgressViewControllerStateUploading
    //
    // Or
    //  Send "Rejected" in responce.
    //  Do nothing.


    PBTransferSession *session = [PBAppDelegate sharedDelegate].transferSession;
    BOOL canStartNewTransfer = (nil == session || session.isCanceled);


    if (canStartNewTransfer) {
        
        // TODO: get rid of it
        struct in_addr remote_ip = {(int)request.requestInfo->remote_ip};
        NSString *address = [PBBeginTransferServlet stringWithInAddr:remote_ip];
        NSString *URLString = [NSString stringWithFormat:@"http://%@:%ld/", address, (long)PBGetServerPort()];

        NSString *deviceName = [request.headers objectForKey:@"X-Device-Name"];

        [self beginTransferSessionRemoteDeviceName:deviceName
                                         URLString:URLString];

        
        NSString *deviceType = [request.headers objectForKey:@"X-Device-Type"];

        [self sendTransferWasBeganNotificationRemoteDeviceName:deviceName
                                                          type:deviceType];
    }

    
    // Set responce body

    response.bodyString = (canStartNewTransfer) ? kConnectionAccepted : kConnectionRejected;
    response.statusCode = @"200 OK";

    return response;
}

- (void)beginTransferSessionRemoteDeviceName:(NSString *)deviceName URLString:(NSString *)URLString {
    PBTransferSession *newSession = [[[PBTransferSession alloc] initWithDeviceName:deviceName URLString:URLString] autorelease];
    [[PBAppDelegate sharedDelegate] setTransferSession:newSession];
}

- (void)sendTransferWasBeganNotificationRemoteDeviceName:(NSString *)deviceName
                                                    type:(NSString *)deviceType {

    NSDictionary *userInfo = @{kPBDeviceName : deviceName,
                               kPBDeviceType : deviceType};

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBMongooseServerPostBodyProgressDidUpdateNotification
            object:nil
            userInfo:userInfo];
    });
}

@end
