//
//  PBFlickrUploadingEngine.h
//  PhotoBox
//
//  Created by Dara on 06.04.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import "PBCommonUploadingEngine.h"
#import "ObjectiveFlickr.h"



@interface PBFlickrUploadingEngine : PBCommonUploadingEngine <OFFlickrAPIRequestDelegate> {
    OFFlickrAPIContext *flickrContext;
    OFFlickrAPIRequest *flickrRequest;
    NSString *flickrUserName;
}

//-(void)completeAuthorizationWithFrob:(NSString *)frobString;
-(void)startAuthentification;
-(void)checkIfTokenValid;

- (void)setAndStoreFlickrAuthToken:(NSString *)inAuthToken secret:(NSString *)inSecret;

-(BOOL)runAuthStepWithURL:(NSURL *)url;

@property (nonatomic, readonly) OFFlickrAPIContext *flickrContext;
@property (nonatomic, retain) NSString *flickrUserName;

@end

//extern NSString *SRCallbackURLBaseString;
