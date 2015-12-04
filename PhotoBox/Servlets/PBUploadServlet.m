//
//  UploadServlet.m
//  MongooseWrapper
//
//  Created by Fabio Rodella on 6/13/11.
//  Copyright 2011 Crocodella Software. All rights reserved.
//

#import "PBUploadServlet.h"
#import "PBAssetManager.h"

@implementation PBUploadServlet

- (PBServletResponse *)doOptions:(PBServletRequest *)request {
    PBServletResponse *resp = [[[PBServletResponse alloc] init] autorelease];
    resp.statusCode = @"200 OK";
    [resp addHeader:@"Content-Type" withValue:@"text/plain"];
    [resp addHeader:@"Access-Control-Allow-Origin" withValue:@"*"];
    [resp addHeader:@"Access-Control-Allow-Headers" withValue:@"X-Mime-Type, X-Requested-With, X-File-Name, Content-Type, Cache-Control"];
    
    return resp;
}

- (PBServletResponse *)doGet:(PBServletRequest *)request {
    NSLog(@"ss");
    
    return nil;
}

- (PBServletResponse *)doPost:(PBServletRequest *)request {
    
    NSString *contentType = [request.headers valueForKey:@"Content-Type"];

    BOOL multipartContentType = [contentType rangeOfString:@"multipart/form-data"].location != NSNotFound;
    BOOL octetContentType = [contentType rangeOfString:@"application/octet-stream"].location != NSNotFound;
    
    if (!multipartContentType && !octetContentType) {
        return [self sendInternalError];
    }
    
    // Make some random name in case, real filename is cant be found
    // but there is correct file header
    NSString *filename = [NSString stringWithFormat:@"%@.jpg", PBUUIDString()];

    if (multipartContentType) {
        // WARNING: This is not a particularly robust implementation of the multipart
        // form data standard. It should work only for cases where there is a single
        // file element in the request.
        //
        // Changed on 04/15/2013 by: Viacheslav Savchenko vs.savchenko@readdle.com
        // It's probably fixed now. But in simplified way.
        // Just skip all Content-Disposition headers until found file header.
        // Get filename from filename field, and skip Content-type header.
        // TODO: Parse Content-type header to be able call proper method for import.
        //

        NSArray *comps = [contentType componentsSeparatedByString:@";"];
        NSArray *bounds = [[comps objectAtIndex:1] componentsSeparatedByString:@"="];
        NSString *boundary = [bounds objectAtIndex:1];
        
        char byte = 'a';
        
        // Starts after boundary
        int pos = (int)([boundary length] + 4);

        char file_name[1024];
        file_name[0] = '\0';


        // Find file header
        // Assume here that all headers are within 1024 bytes range

        while (pos < 1024) {
            int headers_number = sscanf(([request.body bytes] + pos), "Content-Disposition: %*s %*s filename=\"%1023[^\"]", file_name);

            if (headers_number > 0) {
                filename = [NSString stringWithCString:file_name encoding:NSUTF8StringEncoding];
                break;
            }

            pos++;
        }

        // Return error if file header wasn't found
        if (pos >= 1024) {
            return [self sendInternalError];
        }


        // Skip headers
        // There must be only Content-type header
        // TODO: parse Content-type

        BOOL readingHeaders = YES;
        while (readingHeaders) {
            char *header = malloc(1024);
            int i = 0;
            byte = *(char *)([request.body bytes] + pos);


            // Read

            while (byte != '\r') {
                header[i] = byte;
                pos++;
                i++;
                
                byte = *(char *)([request.body bytes] + pos);
            }
            
            header[i] = '\0';
            
            // Skips the carriage return and line feed
            pos += 2;
            
            if (strcmp(header, "") == 0) {
                readingHeaders = NO;
            }
            
            free(header);
        }

        
        // Reads the actual data

        NSRange dataRange = NSMakeRange(pos, [request.body length] - pos - [boundary length] - 8);
        NSData *fileData = [request.body subdataWithRange:dataRange];
        NSString *filePath = [PBTemporaryDirectory() stringByAppendingPathComponent:filename];
        [fileData writeToFile:filePath atomically:YES];
        
        [[PBAssetManager sharedManager] importAssetFromFileAtPath:filePath];
    }

    
    if (octetContentType) {
        NSString *filename = [request.headers objectForKey:@"X-File-Name"];
        
        if ([filename isEqualToString:@"image.jpg"]) {
            static int index = 0;
            filename = [NSString stringWithFormat:@"%@-%d.jpg", [NSDate date], index++];
        }
        
        NSString *filePath = [PBTemporaryDirectory() stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager] createFileAtPath:filePath
                                                contents:request.body
                                              attributes:nil];
        
        [[PBAssetManager sharedManager] importAssetFromFileAtPath:filePath];
    }
    
    PBServletResponse *resp = [[[PBServletResponse alloc] init] autorelease];
    resp.statusCode = @"200 OK";
    resp.bodyString = @"{\"success\":true}";
    [resp addHeader:@"Content-Type" withValue:@"text/plain"];
    [resp addHeader:@"Access-Control-Allow-Origin" withValue:@"*"];
    
    return resp;
}

@end
