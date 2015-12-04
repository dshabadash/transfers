//
//  PBStatusServlet.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 29/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBStatusServlet.h"
#import "PBAssetManager.h"
#import "PBMongooseServer.h"

@implementation PBStatusServlet

- (PBServletResponse *)doGet:(PBServletRequest *)request {
    PBServletResponse *response = [[PBServletResponse new] autorelease];
    [response addHeader:@"Content-Type" withValue:@"text/html"];
    [response addHeader:@"Access-Control-Allow-Origin" withValue:@"*"];
    
    response.statusCode = @"200 OK";
    
    PBAssetManager *assetManager = [PBAssetManager sharedManager];
    
    NSInteger assetCount = 0;
    if (assetManager.isReadyToSend) {
        assetCount = assetManager.assetCount;
    }
    
    NSString *assetZipName = [assetManager.assetsZipFilePath lastPathComponent];
    if (assetZipName == nil) {
        assetZipName = @"";
    }
    
    NSString *transferState = @"";
    
    PBMongooseServer *mongooseServer = [PBAppDelegate sharedDelegate].httpServer;
    if (mongooseServer.isDownloadInProgress) {
        transferState = @"download_in_progress";
    } else if (mongooseServer.isUploadInProgress || assetManager.isImportAssetInProgress) {
        transferState = @"upload_in_progress";
    }
    
    static NSString *deviceType = nil;
    static NSString *deviceName = nil;
    if (deviceType == nil) {
        deviceType = [[[UIDevice currentDevice] model] copy];
        deviceName = [[PBAppDelegate serviceName] copy];
    }
    
    BOOL assetsAreBeingPrepared = assetManager.isBusy;
    
    NSDictionary *statusDictionary = @{
        @"app_version" : PBGetAppVersion(),
        @"asset_count" : @(assetCount),
        @"asset_zip_name" : assetZipName,
        @"upload_allowed" : @"true",
        @"transfer_state" : transferState,
        @"assets_are_being_prepared" : @(assetsAreBeingPrepared),
        @"device_type" : deviceType,
        @"device_name" : deviceName
    };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:statusDictionary
                                                       options:0
                                                         error:nil];
    

    NSString *jsonCallback = [request.parameters objectForKey:@"jsonp_callback"];
    if (jsonCallback) {
        //JSONP fallback for IE
        NSString *jsonDataString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
        response.bodyString = [NSString stringWithFormat:@"%@(%@);",
                               jsonCallback,
                               jsonDataString];
    } else {
        //normal JSON response
        response.body = jsonData;
    }
    
    
    
    return response;
}

@end
