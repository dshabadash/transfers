//
//  Servlet.m
//  MongooseWrapper
//
//  Created by Fabio Rodella on 6/10/11.
//  Copyright 2011 Crocodella Software. All rights reserved.
//

#import "PBServlet.h"


@implementation PBServlet

+ (id)servlet {
    return [[self new] autorelease];
}

- (PBServletResponse *)doGet:(PBServletRequest *)request {
//    NSLog(@"%@", @"Override me if you want to support GET!");
    return [self sendNotImplemented];
}

- (PBServletResponse *)doPost:(PBServletRequest *)request {
//    NSLog(@"%@", @"Override me if you want to support POST!");
    return [self sendNotImplemented];
}

- (PBServletResponse *)doOptions:(PBServletRequest *)request {
//    NSLog(@"%@", @"Override me if you want to support OPTIONS!");
    return [self sendNotImplemented];
}

- (PBServletResponse *)doPut:(PBServletRequest *)request {
//    NSLog(@"%@", @"Override me if you want to support PUT!");
    return [self sendNotImplemented];
}

- (PBServletResponse *)doDelete:(PBServletRequest *)request {
//    NSLog(@"%@", @"Override me if you want to support DELETE!");
    return [self sendNotImplemented];
}

- (void)finishedSendingServletResponse:(PBServletResponse *)response {
//    NSLog(@"%@", @"Override me if you want to handle responce delivery");
}

- (PBServletResponse *)sendInternalError {
    PBServletResponse *response = [[[PBServletResponse alloc] init] autorelease];
    response.statusCode = @"500 Internal Server Error";
    response.bodyString = @"<html><head><title>500 - Internal Server Error</title></head><body><h1>500 - Internal Server Error</h1></body></html>";
    [response addHeader:@"Content-Type" withValue:@"text/html"];
    
    return response;
}

- (PBServletResponse *)sendNotFound {
    PBServletResponse *response = [[[PBServletResponse alloc] init] autorelease];
    response.statusCode = @"404 Not Found";
    response.bodyString = @"<html><head><title>404 - Not Found</title></head><body><h1>404 - Not Found</h1></body></html>";
    [response addHeader:@"Content-Type" withValue:@"text/html"];
    
    return response;
}

- (PBServletResponse *)sendNotImplemented {
    PBServletResponse *response = [[[PBServletResponse alloc] init] autorelease];
    response.statusCode = @"501 Not Implemented";
    response.bodyString = @"<html><head><title>501 - Not Implemented</title></head><body><h1>501 - Not Implemented</h1></body></html>";
    [response addHeader:@"Content-Type" withValue:@"text/html"];
    
    return response;
}

-(NSDictionary *)extractParametersFromPath:(NSString *)path {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    NSArray *components = [path componentsSeparatedByString:@"&"];
    if ([components count] > 1) {
        for (NSString *component in components) {
            NSArray *parts = [component componentsSeparatedByString:@"="];
            if ([parts count] == 2) {
                [parameters setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
            }
        }
    }
    
    return parameters;
}

@end
