//
//  PBFinishTransferServlet.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 4/16/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBFinishTransferServlet.h"
#import "PBMongooseServer.h"

@interface PBFinishTransferServlet () {
    NSDictionary *_headers;
}
@end

@implementation PBFinishTransferServlet

- (PBServletResponse *)doGet:(PBServletRequest *)request {
    _headers = [request.headers retain];
    [self finishTransferSession];


    // Set responce body

    PBServletResponse *response = [[PBServletResponse new] autorelease];
    [response addHeader:@"Content-Type" withValue:@"text/html"];
    response.bodyString = @"";
    response.statusCode = @"200 OK";

    return response;
}

- (void)finishTransferSession {
    PBTransferSession *session = [PBAppDelegate sharedDelegate].transferSession;
    if (nil == session || session.isCanceled) {
        return;
    }

    NSString *deviceName = [_headers objectForKey:@"X-Device-Name"];
    if ([deviceName isEqualToString:session.deviceName]) {
        [[PBAppDelegate sharedDelegate] setTransferSession:nil];
    }

    [self sendTransferWasFinishedNotification];
}

- (void)sendTransferWasFinishedNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBMongooseServerPostBodyProgressDidFinishNotification
            object:nil
            userInfo:nil];
    });
}

- (void)dealloc {
    [_headers release];
    _headers = nil;
    
    [super dealloc];
}

@end
