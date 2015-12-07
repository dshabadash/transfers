//
//  PBGoogleDriveUploadingEngine.m
//  PhotoBox
//
//  Created by Dara on 03.04.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import "PBGoogleDriveUploadingEngine.h"
#import "GTLDrive.h"



@interface PBGoogleDriveUploadingEngine ()

@property (nonatomic, retain) GTLServiceDrive *driveService;
@property (nonatomic, retain) NSString *destinationDirectoryName;
@property (nonatomic, retain) GTLServiceTicket *uploadingTicket;
@property (nonatomic, retain) NSString *parentFolderID;

@end


@implementation PBGoogleDriveUploadingEngine

-(id)init {
    self = [super init];
    
    if (self) {
        self.driveService = [[GTLServiceDrive alloc] init];
        self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:PB_GOOGLE_KEYCHAIN_ITEM_NAME
                                                                                              clientID:PB_GOOGLE_DRIVE_CLIENT_KEY
                                                                                         clientSecret:PB_GOOGLE_DRIVE_CLIENT_SECRET];
        self.engineName = @"GoogleDrive";
    }
    return self;
    
}

-(void)setAuthorizer:(id <GTMFetcherAuthorizationProtocol>)authorizer {
    self.driveService.authorizer = authorizer;
}

-(void)dealloc {
    [self.driveService release];
    [super dealloc];
}


#pragma mark - 
#pragma mark Authorization
#pragma mark -

// Helper to check if user is authorized
- (BOOL)isAuthorized {
    if (!self.driveService.authorizer)
        return NO;
    else
        return [((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize];
}

#pragma mark -
-(void)createFolderForUploading:(NSString *)folderName {
    GTLDriveFile *folder = [GTLDriveFile object];
    folder.title = [NSString stringWithFormat:@"%@_%@", PB_APP_NAME, folderName];
    folder.mimeType = @"application/vnd.google-apps.folder";
    
    self.destinationDirectoryName = folder.title;
    
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:folder uploadParameters:nil];
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                  GTLDriveFile *updatedFile,
                                                  NSError *error) {
        if (error == nil) {
            NSLog(@"Created folder");
            
            self.parentFolderID = updatedFile.identifier;
            
            GTLDrivePermission *drivePermission = [GTLDrivePermission object];
            drivePermission.role = @"reader";
            drivePermission.withLink = [NSNumber numberWithBool:YES];
            drivePermission.type = @"anyone";
            drivePermission.value = @"";
                        
            GTLQueryDrive *permQuery = [GTLQueryDrive queryForPermissionsInsertWithObject:drivePermission fileId:self.parentFolderID];
            [self.driveService executeQuery:permQuery completionHandler:^(GTLServiceTicket *ticket,
                                                                          GTLDrivePermission *drivePermission,
                                                                          NSError *error) {
                if (error == nil) {
                    self.sharableLinkOnFolder = updatedFile.alternateLink;
                    NSLog(@"sharable link %@", updatedFile.alternateLink);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"FolderCreatedByUploadingEngine" object:nil];
                }
                else {
                    NSLog(@"Sharing folder failed. An error occurred: %@", error);
                }
            }];
        }
        else {
            NSLog(@"Folder creating failed. An error occurred: %@", error);
        }
    }];
    
}

-(void)uploadFile:(NSString *)fileName toPath:(NSString *)destinationDirectory fromPath:(NSString *)sourceFilePath {
    
    GTLDriveParentReference *parent = [GTLDriveParentReference object];
    parent.identifier = self.parentFolderID;
    
    GTLDriveFile *file = [GTLDriveFile object];
    file.title = fileName;
    file.descriptionProperty = [NSString stringWithFormat:@"Uploaded from %@", PB_APP_NAME];
    file.parents = @[parent];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:sourceFilePath];
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithFileHandle:fileHandle
                                                                                       MIMEType:@"image"];
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:file
                                                       uploadParameters:uploadParameters];

    self.uploadingTicket = [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                                                     GTLDriveFile *insertedFile,
                                                                                     NSError *error) {
        if (error == nil) {

            [[NSNotificationCenter defaultCenter] postNotificationName:@"SuccessfullyUploadedFileByUploadingEngine" object:nil];
            
        }
        else {
            NSLog(@"An error occurred: %@", error);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FailedUploadingFileByUploadingEngine" object:nil];
        }
    }];
    
    self.uploadingTicket.uploadProgressBlock = ^(GTLServiceTicket *ticket,
                                                 unsigned long long numberOfBytesRead,
                                                 unsigned long long dataLength) {
        self.uploadingProgress = (1.0 / dataLength * numberOfBytesRead);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadProgressReceivedByUploadingEngine" object:nil];
    };
    
}

-(void)cancelUploading {
    if (self.uploadingTicket) {
        [self.uploadingTicket cancelTicket];
    }
    
}

@end
