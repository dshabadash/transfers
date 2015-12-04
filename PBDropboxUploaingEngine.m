//
//  PBDropboxUploaingEngine.m
//  PhotoBox
//
//  Created by Dara on 02.04.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import "PBDropboxUploaingEngine.h"
#import <DropboxSDK/DropboxSDK.h>

@interface PBDropboxUploaingEngine()<DBRestClientDelegate>

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) NSString *destinationFilePath;
@end

@implementation PBDropboxUploaingEngine

-(id)init {
    self = [super init];
    
    if (self) {
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
        self.engineName = @"Dropbox";
    }
    
    return self;
        
}

-(void)dealloc {
    [self.restClient release];
    
    [super dealloc];
}


- (BOOL)isAuthorized {
    return [[DBSession sharedSession] isLinked];
}


-(void)createFolderForUploading:(NSString *)folderName {
    [self.restClient createFolder:folderName];
}

-(void)uploadFile:(NSString *)fileName toPath:(NSString *)destinationDirectory fromPath:(NSString *)sourceFilePath {
    [self.restClient uploadFile:fileName
                         toPath:destinationDirectory
                  withParentRev:nil
                       fromPath:sourceFilePath];
}

-(void)cancelUploading {
    [self.restClient cancelFileUpload:self.destinationFilePath];
    [self.restClient cancelAllRequests];
}

#pragma mark - DBRestClientDelegate

- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder {
    //save sharable link
    [client loadSharableLinkForFile:folder.path];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FolderCreatedByUploadingEngine" object:nil];
}

-(void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error {
    NSLog(@"Creating folder failed with error %@, %@", error, error.description);
}

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString*)link
           forFile:(NSString*)path {
    self.sharableLinkOnFolder = link;
}

- (void)restClient:(DBRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error {
    NSLog(@"Loading sharable link failed with error %@, %@", error, error.description);
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath {
    self.destinationFilePath = destPath;
    self.uploadingProgress = progress;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadProgressReceivedByUploadingEngine" object:nil];
}

- (void)restClient:(DBRestClient *)client
      uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath
          metadata:(DBMetadata *)metadata {
    
    NSLog(@"File %@ uploaded successfully to path: %@", srcPath, metadata.path);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SuccessfullyUploadedFileByUploadingEngine" object:nil];
    
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error.description);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FailedUploadingFileByUploadingEngine" object:nil];

}

@end
