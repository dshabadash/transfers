//
//  PBGoogleDriveUploadingEngine.h
//  PhotoBox
//
//  Created by Dara on 03.04.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBCommonUploadingEngine.h"
#import "GTMOAuth2ViewControllerTouch.h"

@interface PBGoogleDriveUploadingEngine : PBCommonUploadingEngine

-(void)setAuthorizer:(id <GTMFetcherAuthorizationProtocol>)authorizer;

@end
