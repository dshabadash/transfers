//
//  PBTransferSession.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 4/9/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBTransferSession.h"
#import "PBServiceBrowser.h"
#import "RDHTTP.h"

NSString * const PBTransferWasCanceledNotification = @"TransferWasCanceled";
NSString * const kBeginTransferPath = @"beginTransfer";
NSString * const kFinishTransferPath = @"finishTransfer";
NSString * const kCancelTransferPath = @"cancelTransfer";
NSString * const kConnectionAccepted = @"Accepted";
NSString * const kConnectionRejected = @"Rejected";

@interface PBTransferSession () {
    BOOL _active;
}

@end

@implementation PBTransferSession

- (PBTransferSession *)initWithDeviceName:(NSString *)deviceName URLString:(NSString *)URLString {
    self = [super init];

    if (nil != self) {
        _active = YES;
        _isCanceled = NO;

        _deviceName = [deviceName copy];
        _URLString = [URLString copy];
    }

    return self;
}

- (void)cancel {
    if (_isCanceled) {
        return;
    }

    _isCanceled = YES;

    [self sendTransferWasCanceledNotification];
    [self cancelSessionOnTargetDevice];
}

- (void)cancelSessionOnTargetDevice {
    if (!_active) {
        return;
    }
    
    _active = NO;


    if (nil == _URLString) {
        return;
    }

    NSString *requestURL = [_URLString stringByAppendingPathComponent:kCancelTransferPath];
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURLString:requestURL];
    [request setValue:@"text/html" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[PBAppDelegate serviceName] forHTTPHeaderField:@"X-Device-Name"];
    [request setValue:[[UIDevice currentDevice] model] forHTTPHeaderField:@"X-Device-Type"];
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {

        // Do nothing
        NSLog(@"Cancel response: %@", response);
    }];
}

- (void)beginSessionCompletion:(void (^)(BOOL started))completion {
    NSString *requestURL = [_URLString stringByAppendingString:kBeginTransferPath];
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURLString:requestURL];
    [request setValue:@"text/html" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[PBAppDelegate serviceName] forHTTPHeaderField:@"X-Device-Name"];
    [request setValue:[[UIDevice currentDevice] model] forHTTPHeaderField:@"X-Device-Type"];
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        _active = ([[response responseString] isEqualToString:kConnectionAccepted]);
        completion(_active);
    }];
}

- (void)finishSessionCompletion:(void (^)(void))completion {
    if (!_active) {
        completion();
        return;
    }

    _active = NO;

    NSString *requestURL = [_URLString stringByAppendingString:kFinishTransferPath];
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURLString:requestURL];
    [request setValue:@"text/html" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[PBAppDelegate serviceName] forHTTPHeaderField:@"X-Device-Name"];
    [request setValue:[[UIDevice currentDevice] model] forHTTPHeaderField:@"X-Device-Type"];
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        completion();
    }];
}


#pragma mark - Notifications

- (void)sendTransferWasCanceledNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBTransferWasCanceledNotification
            object:nil
            userInfo:nil];
    });
}


#pragma mark - Memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_URLString release];
    _URLString = nil;

    [_deviceName release];
    _deviceName = nil;

    [super dealloc];
}

@end
