//
//  PBRootServlet.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBRootServlet.h"
#import "PBHtmlBuilder.h"

@interface PBRootServlet () {
    NSFileManager *_fileManager;
}

@end

@implementation PBRootServlet

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
    
    BOOL setFixedLocalIp = NO;
    
    NSString *filename = request.path;
    if (filename.length == 0 || [filename isEqualToString:@"/"]) {
        filename = @"client.php";
        setFixedLocalIp = YES;
    }
    
    NSString *filePath = [PBApplicationLibraryDirectoryAdd(PB_WEBPART_MOBILE_NAME) stringByAppendingPathComponent:filename];
    NSLog(@"filePath is %@", filePath);
    if ([_fileManager fileExistsAtPath:filePath]) {
        
        if (setFixedLocalIp) {
            NSString *localIpString = PBGetLocalIP();
            NSString *fixedLocalIpJavaScriptString = [NSString stringWithFormat:@"var static_local_ip = \"%@\";", localIpString];
            
            NSInteger port = PBGetServerPort();
            
            NSString *fixedPortJavaScriptString = [NSString stringWithFormat:@"var static_port = \"%ld\";", (long)port];
            
            NSString *htmlString = [NSString stringWithContentsOfFile:filePath
                                                         usedEncoding:nil
                                                                error:nil];
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"var static_local_ip = undefined;"
                                                               withString:fixedLocalIpJavaScriptString];
            
            htmlString = [htmlString stringByReplacingOccurrencesOfString:@"var static_port = undefined;"
                                                               withString:fixedPortJavaScriptString];
            
            response.bodyString = htmlString;
        } else {
            response.bodyFilePath = filePath;
            
        }
        
        NSString *ext = filename.pathExtension.lowercaseString;
        if ([@"php,htm,html,js,css" hasString:ext]) {
            [response addHeader:@"Content-Type" withValue:@"text/html"];
        } else if ([@"png,jpg,jpeg,gif" hasString:ext]) {
            [response addHeader:@"Content-Type" withValue:[NSString stringWithFormat:@"image/%@", ext]];
        } else {
            [response addHeader:@"Content-Type" withValue:@"application/octet-stream"];
        }
        
        response.statusCode = @"200 OK";
    } else {
        [response addHeader:@"Content-Type" withValue:@"text/html"];
        return [self sendNotFound];
    }
    
    return response;

}

@end
