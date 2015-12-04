//
//  PBCommonUploadingEngine.h
//  PhotoBox
//
//  Created by Dara on 03.04.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

//ABSTARCT CLASS!!!

#import <Foundation/Foundation.h>

@interface PBCommonUploadingEngine : NSObject

-(void)createFolderForUploading:(NSString *)folderName;
-(void)uploadFile:(NSString *)fileName toPath:(NSString *)destinationDirectory fromPath:(NSString *)sourceFilePath;
-(void)cancelUploading;

- (BOOL)isAuthorized;

@property (nonatomic, strong) NSString *sharableLinkOnFolder;
@property (nonatomic) CGFloat uploadingProgress;

@property (nonatomic, strong) NSString *engineName;

@end
