//
//  MoongoseServer.m
//  MongooseWrapper
//
//  Created by Fabio Rodella on 6/10/11.
//  Copyright 2011 Crocodella Software. All rights reserved.
//

#import "PBMongooseServer.h"

NSString * const PBMongooseServerPostBodyProgressDidUpdateNotification = @"PBMongooseServerPostBodyProgressDidUpdateNotification";
NSString * const PBMongooseServerGetBodyProgressDidUpdateNotification = @"PBMongooseServerGetBodyProgressDidUpdateNotification";

NSString * const PBMongooseServerPostBodyProgressDidFinishNotification = @"PBMongooseServerPostBodyProgressDidFinishNotification";
NSString * const PBMongooseServerGetBodyProgressDidFinishNotification = @"PBMongooseServerGetBodyProgressDidFinishNotification";

BOOL _uploadInProgress;
BOOL _downloadInProgress;

@interface PBMongooseServer () <NSNetServiceDelegate> {
//    int _port;
    BOOL _allowDirectoryListing;
}

@property (retain, nonatomic) NSNetService *netService;
@end

@implementation PBMongooseServer

@synthesize startedOnPort = _port;

@synthesize servlets;
@synthesize ctx;

void *handleRequest(enum pbmg_event event,
                    struct pbmg_connection *conn,
                    const struct pbmg_request_info *request_info) {

    // Exit if server was not started
    if (request_info->uri == NULL) {
        return "handled";
    }

    const char *cl;
    char *buf;
    int len;

    PBMongooseServer *server = (PBMongooseServer *)request_info->user_data;


    // Reads the body of the request
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];


    NSString *path = [NSString stringWithUTF8String:request_info->uri];

    // Search for a servlet to respond to the exact path
    PBServlet *servlet = [server.servlets valueForKey:path];
    
    // If an exact match is not found, tries to match wildcard servlets
    if (!servlet) {
        for (NSString *servletPath in server.servlets) {
            
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", servletPath];
            if ([pred evaluateWithObject:path]) {
                servlet = [server.servlets valueForKey:servletPath];
            }
        }
    }
    
    //get the root servlet if no suitable servlet found
    if (!servlet) {
        servlet = server.servlets[@"/"];
    }
    
    BOOL notifyPostBodyProgressUpdates = servlet.notifyPostBodyProgressUpdates;
    if (notifyPostBodyProgressUpdates) {
        @synchronized([UIApplication sharedApplication]) {
            _uploadInProgress = YES;
        }
    }


    //read request body
    NSData *body = nil;
    if ((cl = pbmg_get_header(conn, "Content-Length")) != NULL) {
        if (notifyPostBodyProgressUpdates) {
            NSString *deviceName = NSLocalizedString(@"computer", @"");
            const char *deviceNameCStr = NULL;
            if ((deviceNameCStr = pbmg_get_header(conn, "X-Device-Name")) != NULL) {
                deviceName = [NSString stringWithCString:deviceNameCStr encoding:NSUTF8StringEncoding];
            }
            
            NSString *deviceType = NSLocalizedString(@"Computer", @"");
            const char *deviceTypeCStr = NULL;
            if ((deviceTypeCStr = pbmg_get_header(conn, "X-Device-Type")) != NULL) {
                deviceType = [NSString stringWithCString:deviceTypeCStr encoding:NSUTF8StringEncoding];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userInfo = @{kPBProgress : @0,
                                           kPBDeviceName : deviceName,
                                           kPBDeviceType : deviceType};

                [[NSNotificationCenter defaultCenter]
                    postNotificationName:PBMongooseServerPostBodyProgressDidUpdateNotification
                    object:nil
                    userInfo:userInfo];
            });
        }
        
        len = atoi(cl);

        if (len > 5 * 1024 * 1024) {
            NSString *tmpFileName = [PBTemporaryDirectory() stringByAppendingPathComponent:PBUUIDString()];
            
            [[NSFileManager defaultManager] createFileAtPath:tmpFileName
                                                    contents:nil
                                                  attributes:nil];
            
            NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:tmpFileName];
            
            
            NSUInteger bufferSize = 1024*1024;
            NSMutableData *bufferData = [NSMutableData dataWithLength:bufferSize];
            uint8_t *buffer = [bufferData mutableBytes];
            int bytesRead;
            NSInteger totalBytesRead = 0;

            do {

                // Transfer was interrupted, exit right now
                if ((nil != [PBAppDelegate sharedDelegate].transferSession) &&
                    [PBAppDelegate sharedDelegate].transferSession.isCanceled) {
                    
                    @synchronized([UIApplication sharedApplication]) {
                        _uploadInProgress = NO;
                    }

                    [[PBAppDelegate sharedDelegate] setTransferSession:nil];

                    return @"handled";
                }

                bytesRead = pbmg_read(conn, buffer, bufferSize);
                [bufferData setLength:bytesRead];
                [handle writeData:bufferData];
                
                if (notifyPostBodyProgressUpdates) {
                    totalBytesRead += bytesRead;
                    float progress = (float)totalBytesRead / (float)len;
                    dispatch_async(dispatch_get_main_queue(), ^{

                        // Send update notification only if session is valid
                        if ((nil != [PBAppDelegate sharedDelegate].transferSession) &&
                            ![PBAppDelegate sharedDelegate].transferSession.isCanceled) {
                            
                            NSDictionary *userInfo = @{kPBProgress : @(progress)};
                            [[NSNotificationCenter defaultCenter]
                                postNotificationName:PBMongooseServerPostBodyProgressDidUpdateNotification
                                object:nil
                                userInfo:userInfo];
                        }
                    });
                }
            } while (bytesRead);

            [handle closeFile];

            body = [NSData dataWithContentsOfFile:tmpFileName
                                          options:NSDataReadingMappedIfSafe
                                            error:nil];
            
            [[NSFileManager defaultManager] removeItemAtPath:tmpFileName error:nil];
        }
        else {
            if ((buf = malloc(len)) != NULL) {
                pbmg_read(conn, buf, len);
                body = [NSData dataWithBytesNoCopy:buf length:len freeWhenDone:YES];
            }
            
            if (notifyPostBodyProgressUpdates) {
                CGFloat progress = 0.3;
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary *userInfo = @{kPBProgress : @(progress)};
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:PBMongooseServerPostBodyProgressDidUpdateNotification
                        object:nil
                        userInfo:userInfo];
                });
            }
        }
    }

    if (notifyPostBodyProgressUpdates) {
        @synchronized([UIApplication sharedApplication]) {
            _uploadInProgress = NO;
        }
    }
    //end of read request body

    
    PBServletResponse *response = nil;
    
    if (servlet) {
        PBServletRequest *request = [[[PBServletRequest alloc] initWithRequestInfo:request_info body:body] autorelease];
        
        if (strcmp(request_info->request_method, "GET") == 0) {
            response = [servlet doGet:request];
        }
        else if (strcmp(request_info->request_method, "POST") == 0) {
            response = [servlet doPost:request];
        }
        else if (strcmp(request_info->request_method, "OPTIONS") == 0) {
            response = [servlet doOptions:request];
        }
    }
    else {
        
        // If directory listing is enabled and no servlet was found, let
        // Mongoose handle it
        
        if (strcmp(pbmg_get_option(server.ctx, "enable_directory_listing"), "yes") == 0) {
            
            return NULL;
            
        } else {
            
            // If no servlets were found to respond, sends a 404 error
            
            servlet = [[[PBServlet alloc] init] autorelease];
            response = [servlet sendNotFound];
        }
    }
    
    if (notifyPostBodyProgressUpdates) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
                postNotificationName:PBMongooseServerPostBodyProgressDidFinishNotification
                object:nil
                userInfo:nil];
        });
    }

    BOOL notifyGetBodyProgressUpdates = servlet.notifyGetBodyProgressUpdates;
    if (notifyGetBodyProgressUpdates) {
        @synchronized([UIApplication sharedApplication]) {
            _downloadInProgress = YES;
        }
    }
    
    NSData *resp = [response toBinary];
    pbmg_write(conn, [resp bytes], [resp length]);
    
    if (response.bodyFilePath) {
        NSData *fileData = [NSData dataWithContentsOfFile:response.bodyFilePath
                                                  options:NSDataReadingMapped
                                                    error:0];

        NSUInteger length = fileData.length;
        NSUInteger bufferSize = 1024*1024;
        NSMutableData *bufferData = [NSMutableData dataWithLength:bufferSize];
        uint8_t *buffer = [bufferData mutableBytes];
        NSUInteger pos = 0;
        NSRange range;

        while (pos < length) {

            // Transfer was interrupted, exit right now
            if ((nil != [PBAppDelegate sharedDelegate].transferSession) &&
                [PBAppDelegate sharedDelegate].transferSession.isCanceled) {
                
                @synchronized([UIApplication sharedApplication]) {
                    _downloadInProgress = NO;
                }

                [[PBAppDelegate sharedDelegate] setTransferSession:nil];

                return @"handled";
            }

            range.location = pos;
            range.length = length-pos < bufferSize ? length-pos : bufferSize;
            
            [fileData getBytes:buffer range:range];
            pbmg_write(conn, buffer, range.length);
            pos += range.length;
            
            if (notifyGetBodyProgressUpdates) {
                float progress = (float)pos / (float)length;
                dispatch_async(dispatch_get_main_queue(), ^{

                    // Send update notification only if session is valid
                    if ((nil != [PBAppDelegate sharedDelegate].transferSession) &&
                        ![PBAppDelegate sharedDelegate].transferSession.isCanceled) {
                        
                        NSDictionary *userInfo = @{kPBProgress : @(progress)};
                        [[NSNotificationCenter defaultCenter]
                            postNotificationName:PBMongooseServerGetBodyProgressDidUpdateNotification
                            object:nil
                            userInfo:userInfo];
                    }
                });
            }
        }
    }

    [servlet finishedSendingServletResponse:response];
    
    if (notifyGetBodyProgressUpdates) {
        @synchronized([UIApplication sharedApplication]) {
            _downloadInProgress = NO;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
                postNotificationName:PBMongooseServerGetBodyProgressDidFinishNotification
                object:nil
                userInfo:nil];
        });
    }

    [pool release];


    return "handled";
}

- (id)initWithPort:(int)port allowDirectoryListing:(BOOL)listing {
    if ((self = [super init])) {
        
        _port = port;
        _allowDirectoryListing = listing;
        
        BOOL startResult = NO;
        
        for (int i = 0; i < 100; i++) {
            startResult = [self start];
            
            if (!startResult) {
                NSLog(@"HTTP server failed to start on port %d", _port);
                _port = _port + 10;
            }
            else {
                NSLog(@"HTTP sucessfully started on port %d", _port);
                break;
            }
        }
        
        servlets = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithOptions:(const char *[])options {
    
    if ((self = [super init])) {
        
        ctx = pbmg_start(handleRequest, self, options);
        
        servlets = [[NSMutableDictionary alloc] init];
        
    }
    return self;

}

- (void)dealloc {
    [self stop];
    
    [servlets release];
    [super dealloc];
}

- (BOOL)start {
    if (ctx) {
        // Republish netService, because after application goes background
        // netService is not valid, if app is not in background mode
        [self publishNetworkServiceOnPort:_port];

        NSLog(@"HTTP Server not started because it is already running.");
        return NO;
    }
    
    NSString *portStr = [NSString stringWithFormat:@"%d", _port];
    
    const char *options[] = {
        "document_root", [NSHomeDirectory() UTF8String],
        "listening_ports", [portStr UTF8String],
        "enable_directory_listing", _allowDirectoryListing ? "yes" : "no",
        NULL
    };
    
    ctx = pbmg_start(handleRequest, self, options);
    
    BOOL started = ctx != NULL;
    if (started) {
        [self publishNetworkServiceOnPort:_port];
        NSLog(@"HTTP Server started");
    }
    
    return started;
}

- (void)stop {
    if (NULL != ctx) {
        pbmg_stop(ctx);
        ctx = NULL;
    }

    [_netService stop];
    self.netService = nil;
}

- (void)forceStop {
    if (NULL != ctx) {
        pbmg_force_stop(ctx);
        ctx = NULL;
    }

    [_netService stop];
    self.netService = nil;
}

- (void)addServlet:(PBServlet *)servlet forPath:(NSString *)path {
    [servlets setValue:servlet forKey:path];
}

- (void)removeServletForPath:(NSString *)path {
    [servlets removeObjectForKey:path];
}


#pragma mark - Bonjour

- (void)publishNetworkServiceOnPort:(NSInteger)port {
    if (nil != _netService) {
        [_netService release];
        _netService = nil;
    }

    NSString *deviceType = [[UIDevice currentDevice] model];
    NSData *modelData = [NSData dataWithBytes:[deviceType UTF8String] length:deviceType.length];
    NSDictionary *txtRecordDictionary = @{kPBDeviceType : modelData};

    NSString *domain = @"local.";

    NSString *serviceName = [PBAppDelegate serviceName];
	self.netService = [[[NSNetService alloc] initWithDomain:domain
                                                       type:PB_BONJOUR_SERVICE_TYPE
                                                       name:serviceName
                                                       port:(int)port] autorelease];

    [_netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:txtRecordDictionary]];
    [_netService setDelegate:self];
	[_netService publish];
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"Published server: %@, %d", sender.hostName, (int)sender.port);
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"Failed to publish server: %@", errorDict);
}

- (BOOL)isDownloadInProgress {
    @synchronized([UIApplication sharedApplication]) {
        return _downloadInProgress;
    }
}

- (BOOL)isUploadInProgress {
    @synchronized([UIApplication sharedApplication]) {
        return _uploadInProgress;
    }
}

@end
