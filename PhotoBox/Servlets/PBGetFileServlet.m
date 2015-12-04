//
//  PBGetFileServlet.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 13/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBGetFileServlet.h"
#import "PBHtmlBuilder.h"

NSString * const PBGetFileServletDidDeliverServletResponse = @"PBGetFileServletDidDeliverServletResponse";

@interface PBGetFileServlet () {
    NSFileManager *_fileManager;
}

@end

@implementation PBGetFileServlet

- (id)init
{
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (PBServletResponse *)doGet:(PBServletRequest *)request {
    PBServletResponse *response = [[PBServletResponse new] autorelease];
    [response addHeader:@"Content-Type" withValue:@"text/html"];

    NSString *filename = [request.path lastPathComponent];
    NSString *filePath = [PBTemporaryDirectory() stringByAppendingPathComponent:filename];

    if ([_fileManager fileExistsAtPath:filePath]) {
        response.bodyFilePath = filePath;
        response.statusCode = @"200 OK";
        
        if ([filePath.pathExtension isEqualToString:@"zip"]) {
            self.notifyGetBodyProgressUpdates = YES;
            [response addHeader:@"Content-Type" withValue:@"application/zip"];
            [PBGetFileServlet startDesktopTransferSession];
        } else {
            self.notifyGetBodyProgressUpdates = NO;
            [response addHeader:@"Content-Type" withValue:@"image/png"];
        }
    } else {
        [response addHeader:@"Content-Type" withValue:@"text/html"];
        response.statusCode = @"404 Not Found";
    }

    return response;
}

- (void)finishedSendingServletResponse:(PBServletResponse *)response {
    if ([response.bodyFilePath hasSuffix:@"zip"]) {
        [PBGetFileServlet dropDesktopTransferSession];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
                postNotificationName:PBGetFileServletDidDeliverServletResponse
                object:nil
                userInfo:nil];
        });
    }
    
    self.notifyGetBodyProgressUpdates = NO;
}

+ (void)startDesktopTransferSession {
    PBTransferSession *session = [[[PBTransferSession alloc] init] autorelease];
    [[PBAppDelegate sharedDelegate] setTransferSession:session];
}

+ (void)dropDesktopTransferSession {
    [[PBAppDelegate sharedDelegate] setTransferSession:nil];
}

@end
