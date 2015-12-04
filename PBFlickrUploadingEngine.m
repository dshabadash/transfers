//
//  PBFlickrUploadingEngine.m
//  PhotoBox
//
//  Created by Dara on 06.04.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import "PBFlickrUploadingEngine.h"
#import "ObjectiveFlickr.h"





NSString *kStoredAuthTokenKeyName = @"FlickrOAuthToken";
NSString *kStoredAuthTokenSecretKeyName = @"FlickrOAuthTokenSecret";

NSString *kGetAccessTokenStep = @"kGetAccessTokenStep";
NSString *kCheckTokenStep = @"kCheckTokenStep";
NSString *kFetchRequestTokenStep = @"kFetchRequestTokenStep";

NSString *kSetImagePropertiesStep = @"kSetImagePropertiesStep";
NSString *kUploadImageStep = @"kUploadImageStep";

NSString *kCreatePhotoset = @"kCreatePhotoset";
NSString *kUploadPhotoToPhotoset = @"kUploadPhotoToPhotoset";
NSString *kGetURLForUserPhotos = @"kGetURLForUserPhotos";

//NSString *SRCallbackURLBaseString = @"imagetransferplusflickr://auth";

@interface PBFlickrUploadingEngine ()

@property (nonatomic, retain) NSString *photosetName;
@property (nonatomic, retain) NSString *photosetId;
@property (nonatomic, retain) NSString *uploadedPhotoId;

@end

@implementation PBFlickrUploadingEngine

@synthesize flickrContext;
@synthesize flickrUserName;

-(id)init {
    self = [super init];
    
    if (self) {
        self.engineName = @"Flickr";
        self.photosetName = @"";
        self.photosetId = @"";
        self.uploadedPhotoId = @"";
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userWasLoggedOut)
                                                     name:@"UserWasSignenOut" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userWasLoggedOut)
                                                     name:@"FlickrUserCancelledAuthentification" object:nil];
    }
    
    return self;
    
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.flickrContext release];
    [self.flickrRequest release];
    [super dealloc];
}

-(void)startAuthentification {

    self.flickrRequest.sessionInfo = kFetchRequestTokenStep;
    NSString *str = PB_CALLBACK_URL_BASE_STRING;
 
    [self.flickrRequest fetchOAuthRequestTokenWithCallbackURL:[NSURL URLWithString:str]];
}

-(BOOL)runAuthStepWithURL:(NSURL *)url {
    if ([self flickrRequest].sessionInfo) {
        // already running some other request
        NSLog(@"Already running some other request");
    }
    else {
        NSString *token = nil;
        NSString *verifier = nil;
        NSString *str = PB_CALLBACK_URL_BASE_STRING;
        BOOL result = OFExtractOAuthCallback(url, [NSURL URLWithString:str], &token, &verifier);
        
        if (!result) {
            NSLog(@"Cannot obtain token/secret from URL: %@", [url absoluteString]);
            return NO;
        }
        
        [self flickrRequest].sessionInfo = kGetAccessTokenStep;
        [flickrRequest fetchOAuthAccessTokenWithRequestToken:token verifier:verifier];

    }
    return YES;
}

-(void)userWasLoggedOut {
    self.flickrContext.OAuthToken = nil;
    [self setAndStoreFlickrAuthToken:nil secret:nil];
    
}

- (BOOL)isAuthorized {
    return [self.flickrContext.OAuthToken length];
}

-(void)checkIfTokenValid {
    if ([self.flickrContext.OAuthToken length]) {
        [self flickrRequest].sessionInfo = kCheckTokenStep;
        [flickrRequest callAPIMethodWithGET:@"flickr.test.login" arguments:nil];
    }
}

#pragma mark Common Upload Engine Routine

-(void)createFolderForUploading:(NSString *)folderName {
    self.photosetName = folderName;
    self.photosetId = @"";
    self.uploadedPhotoId = @"";
    
    self.flickrRequest.sessionInfo = kGetURLForUserPhotos;
    [self.flickrRequest callAPIMethodWithGET:@"flickr.urls.getUserPhotos"
                                   arguments:nil];

}

-(void)uploadFile:(NSString *)fileName toPath:(NSString *)destinationDirectory fromPath:(NSString *)sourceFilePath {
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:sourceFilePath];
    
    self.flickrRequest.sessionInfo = kUploadImageStep;
    [self.flickrRequest uploadImageStream:[NSInputStream inputStreamWithData:data]
                        suggestedFilename:fileName
                                 MIMEType:@""
                                arguments:[NSDictionary dictionaryWithObjectsAndKeys:@"1", @"is_public", nil]];
    
}

-(void)cancelUploading {
    [flickrRequest cancel];
    self.flickrRequest.sessionInfo = nil;
}

#pragma mark -

- (void)setAndStoreFlickrAuthToken:(NSString *)inAuthToken secret:(NSString *)inSecret {
    if (![inAuthToken length] || ![inSecret length]) {
        self.flickrContext.OAuthToken = nil;
        self.flickrContext.OAuthTokenSecret = nil;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kStoredAuthTokenKeyName];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kStoredAuthTokenSecretKeyName];
        
    }
    else {
        self.flickrContext.OAuthToken = inAuthToken;
        self.flickrContext.OAuthTokenSecret = inSecret;
        [[NSUserDefaults standardUserDefaults] setObject:inAuthToken forKey:kStoredAuthTokenKeyName];
        [[NSUserDefaults standardUserDefaults] setObject:inSecret forKey:kStoredAuthTokenSecretKeyName];
    }
}

- (OFFlickrAPIContext *)flickrContext {
    if (!flickrContext) {
        flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:PB_FLICKR_API_KEY
                                                      sharedSecret:PB_FLICKR_API_SECRET];
        
        NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:kStoredAuthTokenKeyName];
        NSString *authTokenSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kStoredAuthTokenSecretKeyName];
        
        if (([authToken length] > 0) && ([authTokenSecret length] > 0)) {
            flickrContext.OAuthToken = authToken;
            flickrContext.OAuthTokenSecret = authTokenSecret;
        }
    }
    
    return flickrContext;
}



- (OFFlickrAPIRequest *)flickrRequest {
    if (!flickrRequest) {
        flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
        flickrRequest.delegate = self;
        flickrRequest.requestTimeoutInterval = 60.0;
    }
    
    return flickrRequest;
}

#pragma mark OFFlickrAPIRequest delegate methods

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didObtainOAuthRequestToken:(NSString *)inRequestToken secret:(NSString *)inSecret {
    // these two lines are important
    self.flickrContext.OAuthToken = inRequestToken;
    self.flickrContext.OAuthTokenSecret = inSecret;
    
    NSURL *authURL = [self.flickrContext userAuthorizationURLWithRequestToken:inRequestToken requestedPermission:OFFlickrWritePermission];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowAuthentificationWebView"
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:authURL                                                                                                        forKey:@"authURL"]];
    [self flickrRequest].sessionInfo = nil;
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didObtainOAuthAccessToken:(NSString *)inAccessToken secret:(NSString *)inSecret userFullName:(NSString *)inFullName userName:(NSString *)inUserName userNSID:(NSString *)inNSID {
    [self setAndStoreFlickrAuthToken:inAccessToken secret:inSecret];
    self.flickrUserName = inUserName;
    
    [self flickrRequest].sessionInfo = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AuthentificationSuccessfullyFinished" object:nil];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary {
  //  NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, inRequest.sessionInfo, inResponseDictionary);
    
    if (inRequest.sessionInfo == kCheckTokenStep) {
        self.flickrUserName = [inResponseDictionary valueForKeyPath:@"user.username._text"];
    }
    else if (inRequest.sessionInfo == kUploadImageStep) {
        self.uploadedPhotoId = [[inResponseDictionary valueForKeyPath:@"photoid"] textContent];
        
        flickrRequest.sessionInfo = kSetImagePropertiesStep;
        [flickrRequest callAPIMethodWithPOST:@"flickr.photos.setMeta" arguments:[NSDictionary dictionaryWithObjectsAndKeys:self.uploadedPhotoId, @"photo_id", PB_APP_NAME, @"title", @"Uploaded from my iPhone/iPod Touch", @"description", nil]];
    }
    else if (inRequest.sessionInfo == kGetURLForUserPhotos) {
        self.sharableLinkOnFolder = [inResponseDictionary valueForKeyPath:@"user.url"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FolderCreatedByUploadingEngine" object:nil];
        
    }
    else if (inRequest.sessionInfo == kSetImagePropertiesStep) {
        if ([self.photosetId isEqualToString:@""]) {
            self.flickrRequest.sessionInfo = kCreatePhotoset;
            [self.flickrRequest callAPIMethodWithPOST:@"flickr.photosets.create"
                                            arguments:[NSDictionary dictionaryWithObjectsAndKeys:self.photosetName, @"title", @"Uploaded from my iPhone/iPod Touch", @"description", self.uploadedPhotoId, @"primary_photo_id",nil]];
        }
        else {
            self.flickrRequest.sessionInfo = kUploadPhotoToPhotoset;
            [self.flickrRequest callAPIMethodWithPOST:@"flickr.photosets.addPhoto"
                                            arguments:[NSDictionary dictionaryWithObjectsAndKeys:self.photosetId, @"photoset_id", self.uploadedPhotoId, @"photo_id", nil]];
            
        }
    }
    else if (inRequest.sessionInfo == kUploadPhotoToPhotoset) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SuccessfullyUploadedFileByUploadingEngine" object:nil];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    else if (inRequest.sessionInfo == kCreatePhotoset) {
        self.sharableLinkOnFolder = [inResponseDictionary valueForKeyPath:@"photoset.url"];
        self.photosetId = [inResponseDictionary valueForKeyPath:@"photoset.id"];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"SuccessfullyUploadedFileByUploadingEngine" object:nil];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
    }
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError {
    if (inRequest.sessionInfo == kGetAccessTokenStep) {
    }
    else if (inRequest.sessionInfo == kCheckTokenStep) {
        [self setAndStoreFlickrAuthToken:nil secret:nil];
    }
    else if (inRequest.sessionInfo == kUploadImageStep) {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FailedUploadingFileByUploadingEngine" object:nil];
    }
    else if ((inRequest.sessionInfo == kCreatePhotoset) || (inRequest.sessionInfo == kUploadPhotoToPhotoset)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SuccessfullyUploadedFileByUploadingEngine" object:nil];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    else if (inRequest.sessionInfo == kGetURLForUserPhotos) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FolderCreatedByUploadingEngine" object:nil];
    }
  
  //  [[[[UIAlertView alloc] initWithTitle:@"API Failed" message:[inError description] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
    
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes {
   self.uploadingProgress = (CGFloat)inSentBytes/(CGFloat)inTotalBytes;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadProgressReceivedByUploadingEngine" object:nil];

}



@end
