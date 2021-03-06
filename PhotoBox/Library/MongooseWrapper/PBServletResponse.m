//
//  ServletResponse.m
//  MongooseWrapper
//
//  Created by Fabio Rodella on 6/10/11.
//  Copyright 2011 Crocodella Software. All rights reserved.
//

#import "PBServletResponse.h"


@implementation PBServletResponse

@synthesize statusCode;
@synthesize headers;
@synthesize body;
@synthesize bodyFilePath;
@synthesize customResponse;

- (id)init {
    if ((self = [super init])) {
        headers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [statusCode release];
    [headers release];
    [body release];
    [customResponse release];
    [super dealloc];
}

- (void)addHeader:(NSString *)name withValue:(NSString *)val {
    [headers setValue:val forKey:name];
}

- (NSString *)bodyString {
    NSString *ret = [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease];
    return ret;
}

- (void)setBodyString:(NSString *)bodyStr {
    self.body = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)toBinary {
    
    if (customResponse) {
        return customResponse;
    }
    
    if (body) {
        [self addHeader:@"Content-Length" withValue:[NSString stringWithFormat:@"%d", (int)[body length]]];
    } else if (bodyFilePath) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:bodyFilePath error:nil];
        [self addHeader:@"Content-Length" withValue:[NSString stringWithFormat:@"%lld", [fileAttributes fileSize]]];
    }
    
    NSMutableString *response = [NSMutableString stringWithFormat:@"HTTP/1.1 %@\r\n", statusCode];
    
    for (NSString *headerName in headers) {
        [response appendFormat:@"%@: %@\r\n", headerName, [headers objectForKey:headerName]];
    }
    [response appendFormat:@"\r\n"];
    
    NSMutableData *ret = [NSMutableData data];
    [ret appendData:[response dataUsingEncoding:NSUTF8StringEncoding]];
    [ret appendData:body];
    
    return ret;
}

@end
