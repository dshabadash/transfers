//
//  PBAssetManager.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 19/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

extern NSString * const PBAssetManagerDidAddAssetNotification;
extern NSString * const PBAssetManagerDidRemoveAssetNotification;
extern NSString * const PBAssetManagerDidRemoveAllAssetsNotification;
extern NSString * const PBAssetManagerPrepareAssetProgressDidChangeNotification;
extern NSString * const PBAssetManagerPrepareAssetDidFinishNotification;

extern NSString * const PBAssetManagerDidGetAccessToAssetsLibraryNotification;
extern NSString * const PBAssetManagerFailedToGetAccessToAssetsLibraryNotification;
extern NSString * const PBAssetManagerDidFailedToImportAssetToLibrary;

#define PBAssetsLibrary [[PBAssetManager sharedManager] assetsLibrary];

typedef void(^PBPrepareAssetsToSendCompletion)(NSString *resultFilePath);
typedef void(^PBAssetManagerProgressBlock)(float progress);

typedef enum {
    NOTHING_SELECTED = 0,
    PHOTOS_LESS_THAN_MAXIMUM = 1 << 1,
    PHOTOS_MORE_THAN_MAXIMUM = 1 << 2,
    VIDEOS_LESS_THAN_MAXIMUM = 1 << 3,
    VIDEOS_MORE_THAN_MAXIMUM = 1 << 4,
    VIDEOS_DURATION_MORE_THAN_MAXIMUM = 1 << 5
} ContentType;

@interface PBAssetManager : NSInputStream

+ (id)sharedManager;
- (ContentType)contentTypeForPhotoURLs:(NSArray *)assetUrlList;
+ (NSString *)allVideosGroupLocalizedName;

- (ALAssetsLibrary *)assetsLibrary;
- (void)allAssetsGroups:(void (^)(NSArray *groups))completion;
- (void)checkAssetsLibraryAccessGranted;
- (BOOL)isAssetsLibraryAccessGranted;

- (ALAssetsGroup *)savedPhotosAssetsGroup;
- (void)savedPhotosAssetsGroupCompletionBlock:(void (^)(ALAssetsGroup *assetGroup))completion;
- (NSURL *)savedPhotosAssetsGroupUrl;
- (void)allVideosAssetsGroup:(void (^)(ALAssetsGroup *assetGroup))completion;

- (ALAsset *)assetForUrl:(NSURL *)url;
- (NSString *)writeAssetToTempFile:(ALAsset *)asset progressHandler:(PBAssetManagerProgressBlock)progressHandler;

- (ALAssetsGroup *)groupForUrl:(NSURL *)url;

- (void)setGroup:(ALAssetsGroup *)group forAssetUrl:(NSURL *)assetUrl;
- (NSURL *)getGroupUrlForAssetUrl:(NSURL *)assetUrl;
- (ALAssetsGroup *)getGroupForAssetUrl:(NSURL *)assetUrl;

- (void)addAsset:(ALAsset *)asset;
- (void)removeAsset:(ALAsset *)asset;
- (BOOL)hasAsset:(ALAsset *)asset;

- (NSUInteger)assetCount;
- (NSArray *)assetUrlList;
- (NSArray *)assetExportList;
- (NSInteger)selectedPhotosNumber;
- (NSInteger)selectedVideosNumber;
- (void)setMaximumNumberOfPhotos:(NSInteger)numberOfPhotos;
- (void)setMaximumNumberOfVideos:(NSInteger)numberOfVideos;

// Value - 0 means no limitations
- (void)setMaximumVideoDuration:(NSTimeInterval)duration;

- (void)removeAllAssets;
- (BOOL)prepareAssetsToSendWithCompletion:(PBPrepareAssetsToSendCompletion)completion; //returns NO if already preparing photos
- (void)cancelPreparingAssets;
- (void)restartPreparingAssets;

- (BOOL)isBusy;
- (BOOL)isReadyToSend;

// Truncate video to asset to maximumVideoDuration
- (void)truncatedVideoFileWithAssetURL:(NSURL *)assetURL completion:(void (^)(NSURL *outputURL))completion;
- (NSURL *)truncatedVideoFileWithAssetURL:(NSURL *)assetURL;

- (NSString *)assetsZipFilePath;

// importing assets
- (void)importAssetFromFileAtPath:(NSString *)filePath;
- (BOOL)isImportAssetInProgress;

@end


#pragma mark - PBAssetInputStream class

/**
 *  PBAssetInputStream provide direct access to asset content over by
 *      subclass of NSInputStream
 */
@interface PBAssetInputStream : NSInputStream<NSStreamDelegate>
@property (nonatomic, copy, readonly) NSURL *assetURL;
- (NSString *)fileName;
- (long long)totalSize;
- (PBAssetInputStream *)initWithAssetURL:(NSURL *)assetURL;
@end