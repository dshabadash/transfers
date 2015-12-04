//
//  PBAssetUploader.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 14/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * const PBAssetUploaderUploadProgressDidUpdateNotification;
NSString * const PBAssetUploaderUploadDidFinishNotification;

@interface PBAssetUploader : NSObject

+ (instancetype)uploader;
- (void)sendAssetsToDeviceWithUrlString:(NSString *)deviceUrlString
                             deviceName:(NSString *)deviceName
                             deviceType:(NSString *)deviceType;



@end
