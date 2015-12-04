//
//  PBAssetManager.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 19/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "PBAssetManager.h"
#import "ZipFile.h"
#import "ZipException.h"
#import "FileInZipInfo.h"
#import "ZipWriteStream.h"
#import "ZipReadStream.h"

NSString * const PBAssetManagerDidAddAssetNotification = @"PBAssetManagerDidAddAssetNotification";
NSString * const PBAssetManagerDidRemoveAssetNotification = @"PBAssetManagerDidRemoveAssetNotification";
NSString * const PBAssetManagerDidRemoveAllAssetsNotification = @"PBAssetManagerDidRemoveAllAssetsNotification";

NSString * const PBAssetManagerPrepareAssetProgressDidChangeNotification = @"PBAssetManagerPrepareAssetProgressDidChangeNotification";
NSString * const PBAssetManagerPrepareAssetDidFinishNotification = @"PBAssetManagerPrepareAssetDidFinishNotification";

NSString * const PBAssetManagerDidGetAccessToAssetsLibraryNotification = @"PBAssetManagerDidGetAccessToAssetsLibraryNotification";
NSString * const PBAssetManagerFailedToGetAccessToAssetsLibraryNotification = @"PBAssetManagerFailedToGetAccessToAssetsLibraryNotification";
NSString * const PBAssetManagerDidFailedToImportAssetToLibrary = @"PBAssetManagerDidFailedToImportAssetToLibrary";

@interface PBAssetManager () {
    ALAssetsLibrary *_assetsLibrary;
    ALAssetsGroup *_savedPhotosAssetsGroup;
    NSMutableOrderedSet *_assetUrls;
    NSMutableDictionary *_groupUrlDictionary;
    NSOperationQueue *_importOperationQueue;

    BOOL _importIsInProgress;
    BOOL _busy;
    BOOL _readyToSend;
    BOOL _cancelled;
    BOOL _shouldRestart;
    BOOL _lastPhotolibraryAccessGranted;

    NSInteger _maximumPhotos;
    NSInteger _maximumVideos;
    NSTimeInterval _maximumVideoDuration;
}

@property (copy, nonatomic) NSString *assetsZipFilePath;
- (void)importFailImageWithFileName:(NSString *)fileName;

@end

@implementation PBAssetManager

+ (id)sharedManager {
    static id sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
        [sharedManager setMaximumNumberOfPhotos:NSIntegerMax];
        [sharedManager setMaximumNumberOfVideos:NSIntegerMax];
        [sharedManager setMaximumVideoDuration:0];
    });

    return sharedManager;
}

- (ContentType)contentTypeForPhotoURLs:(NSArray *)assetUrlList {
    NSUInteger checkResult = NOTHING_SELECTED;

    NSInteger numberOfSelectedPhotos = [self selectedAssetsOfType:ALAssetTypePhoto];
    NSInteger numberOfSelectedVideos = [self selectedAssetsOfType:ALAssetTypeVideo];

    if (numberOfSelectedPhotos > 0) {
        if (numberOfSelectedPhotos > _maximumPhotos) {
            checkResult |= PHOTOS_MORE_THAN_MAXIMUM;
        }
        else {
            checkResult |= PHOTOS_LESS_THAN_MAXIMUM;
        }
    }

    if (numberOfSelectedVideos > 0) {
        if (numberOfSelectedVideos > _maximumVideos) {
            checkResult |= VIDEOS_MORE_THAN_MAXIMUM;
        }
        else {
            checkResult |= VIDEOS_LESS_THAN_MAXIMUM;
        }

        for (NSURL *assetURL in assetUrlList) {
            if ([self shouldTruncateVideoFileWithAssetURL:assetURL]) {
                checkResult |= VIDEOS_DURATION_MORE_THAN_MAXIMUM;
                break;
            }
        }
    }


    return (int)checkResult;
}

+ (NSString *)allVideosGroupLocalizedName {
    return NSLocalizedString(@"All Videos", @"Photo library All Videos group name");
}

- (id)init {
    self = [super init];
    if (self) {
        _assetsLibrary = [ALAssetsLibrary new];

        _assetUrls = [NSMutableOrderedSet new];
        _groupUrlDictionary = [NSMutableDictionary new];
        _readyToSend = NO;
        _importOperationQueue = [[[NSOperationQueue alloc] init] retain];
        [_importOperationQueue setMaxConcurrentOperationCount:1];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(assetsLibraryDidChange:)
                                   name:ALAssetsLibraryChangedNotification
                                 object:nil];
        
#if PB_LITE        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self savedPhotosAssetsGroup];
        });
#endif

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_assetUrls release];
    [_assetsLibrary release];
    [_groupUrlDictionary release];

    [_assetsZipFilePath release];
    _assetsZipFilePath = nil;

    [_importOperationQueue cancelAllOperations];
    [_importOperationQueue release];
    _importOperationQueue = nil;

    [super dealloc];
}

- (ALAssetsLibrary *)assetsLibrary {
    return _assetsLibrary;
}

- (void)allAssetsGroups:(void (^)(NSArray *groups))completion {
    ALAssetsLibrary *assetsLibrary = [self assetsLibrary];
    NSMutableArray *foundGroups = [NSMutableArray arrayWithCapacity:0];

    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            *stop = (nil == group);
            
            if (*stop) {
                
                completion(foundGroups);
            }
            else {
                if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] != ALAssetsGroupPhotoStream) {
                   [foundGroups insertObject:group atIndex:0]; 
                }
            }
        }
        failureBlock:^(NSError *error) {
            completion(nil);
        }];
}

- (void)assetsLibraryDidChange:(NSNotification *)notification {
    //runloop-independent autorelease
    [_savedPhotosAssetsGroup performSelector:@selector(release) withObject:nil afterDelay:0.01];
    
    _savedPhotosAssetsGroup = nil;
}

- (void)checkAssetsLibraryAccessGranted {
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
              *stop = YES;
              dispatch_async(dispatch_get_main_queue(), ^{
                  _lastPhotolibraryAccessGranted = YES;
                  [[NSNotificationCenter defaultCenter]
                      postNotificationName:PBAssetManagerDidGetAccessToAssetsLibraryNotification
                      object:nil
                      userInfo:nil];
              });
        }
        failureBlock:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _lastPhotolibraryAccessGranted = NO;
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:PBAssetManagerFailedToGetAccessToAssetsLibraryNotification
                    object:nil
                    userInfo:nil];
            });
        }];
}

- (BOOL)isAssetsLibraryAccessGranted {
    return _lastPhotolibraryAccessGranted;
}

- (NSURL *)savedPhotosAssetsGroupUrl {
    static NSURL *savedPhotosAssetsGroupUrl = nil;
    
    if (savedPhotosAssetsGroupUrl == nil) {
        ALAssetsGroup *savedPhotosAssetsGroup = [self savedPhotosAssetsGroup];
        savedPhotosAssetsGroupUrl = [[savedPhotosAssetsGroup valueForProperty:ALAssetsGroupPropertyURL] copy];
    }
    
    return savedPhotosAssetsGroupUrl;
}

- (void)allVideosAssetsGroup:(void (^)(ALAssetsGroup *assetGroup))completion {
    ALAssetsLibrary *assetsLibrary = [self assetsLibrary];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group) {
                [group setAssetsFilter:[ALAssetsFilter allVideos]];
                *stop = YES;
                completion(group);
            }
        }
        failureBlock:^(NSError *error) {
            completion(nil);
        }];
}

- (ALAssetsGroup *)savedPhotosAssetsGroup {
    if (_savedPhotosAssetsGroup == nil) {
        dispatch_semaphore_t mutex = dispatch_semaphore_create(0);
        
        __block ALAssetsGroup *tmpGroup = nil;
        
        
        //albums
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                          usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                              if (group) {
                                                  tmpGroup = [group retain];
                                                  
                                                  *stop = YES;
                                              }
                                              dispatch_semaphore_signal(mutex);
                                          }
                                        failureBlock:^(NSError *error) {
                                            dispatch_semaphore_signal(mutex);
                                        }];
        });

        dispatch_semaphore_wait(mutex, DISPATCH_TIME_FOREVER);
        dispatch_release(mutex);
        
        _savedPhotosAssetsGroup = tmpGroup;
    }
    
    //NSLog(@"name %@",[_savedPhotosAssetsGroup valueForProperty:ALAssetsGroupPropertyName]);
    
    return _savedPhotosAssetsGroup;
}

// This method doesn't block calling thread, and return right after beening called
- (void)savedPhotosAssetsGroupCompletionBlock:(void (^)(ALAssetsGroup *assetGroup))completion {
    if (_savedPhotosAssetsGroup == nil) {
        __block ALAssetsGroup *tmpGroup = nil;
        [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
            usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if (group) {
                    tmpGroup = [group retain];
                    *stop = YES;
                    _savedPhotosAssetsGroup = tmpGroup;
                    completion(_savedPhotosAssetsGroup);
                }
            }
            failureBlock:^(NSError *error) {
                completion(nil);
            }];
    }
    else {
        completion(_savedPhotosAssetsGroup);
    }
}


#pragma mark - Adding and removing assets

- (void)addAsset:(ALAsset *)asset {
    NSURL *assetUrl = asset.defaultRepresentation.url;
    BOOL shouldNotify = NO;
    
    @synchronized(_assetUrls) {
        if ([_assetUrls containsObject:assetUrl] == NO) {
            [_assetUrls insertObject:assetUrl atIndex:0];
            shouldNotify = YES;
        }
    }
    
    if (shouldNotify) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{kPBAssetUrl : assetUrl};
            [[NSNotificationCenter defaultCenter]
                postNotificationName:PBAssetManagerDidAddAssetNotification
                object:self
                userInfo:userInfo];
        });
    }
}

- (void)removeAsset:(ALAsset *)asset {
    NSURL *assetUrl = asset.defaultRepresentation.url;
    BOOL shouldNotify = NO;

    @synchronized(_assetUrls) {
        NSInteger index = [_assetUrls indexOfObject:assetUrl];
        if (index != NSNotFound) {
            [_assetUrls removeObjectAtIndex:index];
            shouldNotify = YES;
        }
    }
    
    if (shouldNotify) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{kPBAssetUrl : assetUrl};
            [[NSNotificationCenter defaultCenter]
                postNotificationName:PBAssetManagerDidRemoveAssetNotification
                object:self
                userInfo:userInfo];
        });
    }
}

- (void)removeAllAssets {
    @synchronized(_assetUrls) {
        [_assetUrls removeAllObjects];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBAssetManagerDidRemoveAllAssetsNotification
            object:self
            userInfo:nil];
    });
}

- (BOOL)hasAsset:(ALAsset *)asset {
    NSURL *assetUrl = asset.defaultRepresentation.url;
    
    if (!assetUrl)
        return NO;
    
    BOOL hasAsset;
    @synchronized(_assetUrls) {
        hasAsset = [_assetUrls containsObject:assetUrl];
    }
    
    return hasAsset;
}

- (NSUInteger)assetCount {
    @synchronized(_assetUrls) {
        return _assetUrls.count;
    }
}

- (NSArray *)assetUrlList {
    @synchronized(_assetUrls) {
        //important to make a new array, because [NSOrderedSet array] is not real array but proxy object
        NSArray *result = [NSArray arrayWithArray:_assetUrls.array];
        return result;
    }
}

- (NSArray *)assetExportList {
    BOOL appVersionIsFullFeatured = [PBAppDelegate sharedDelegate].isFullVersion;
    if (appVersionIsFullFeatured) {
        return [self assetUrlList];
    }

    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:0];

    NSInteger photosNumber = 0;
    NSInteger videosNumber = 0;

    for (NSURL *assetURL in [[_assetUrls copy] autorelease]) {
        ALAsset *asset = [self assetForUrl:assetURL];

        if ((photosNumber < _maximumPhotos) &&
            ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto)) {

            ++photosNumber;
            [urls addObject:assetURL];
        }
        else if ((videosNumber < _maximumVideos) &&
                 ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)) {

            ++videosNumber;
            [urls addObject:assetURL];
        }

        if ((photosNumber >= _maximumPhotos) && (videosNumber >= _maximumVideos)) {
            break;
        }
    }

    
    return urls;
}

- (NSInteger)selectedPhotosNumber {
    return [self exportAssetsOfType:ALAssetTypePhoto];
}

- (NSInteger)selectedVideosNumber {
    return [self exportAssetsOfType:ALAssetTypeVideo];
}

- (NSInteger)exportAssetsOfType:(NSString *)assetType {
    NSInteger assetsNumber = 0;

    NSArray *exportList = [self assetExportList];

    for (NSURL *assetURL in exportList) {
        ALAsset *asset = [self assetForUrl:assetURL];
        if ([[asset valueForProperty:ALAssetPropertyType] isEqual:assetType]) {
            ++assetsNumber;
        }
    }

    return assetsNumber;
}

- (NSInteger)selectedAssetsOfType:(NSString *)assetType {
    NSInteger assetsNumber = 0;

    NSArray *selectedAssetsUrls = [self assetUrlList];

    for (NSURL *assetURL in selectedAssetsUrls) {
        ALAsset *asset = [self assetForUrl:assetURL];
        if ([[asset valueForProperty:ALAssetPropertyType] isEqual:assetType]) {
            ++assetsNumber;
        }
    }

    return assetsNumber;
}

- (void)setGroup:(ALAssetsGroup *)group forAssetUrl:(NSURL *)assetUrl {
    if (group && assetUrl) {
        [_groupUrlDictionary setObject:[group valueForProperty:ALAssetsGroupPropertyURL]
                                forKey:assetUrl];
    }
}

- (NSURL *)getGroupUrlForAssetUrl:(NSURL *)assetUrl {
    if (assetUrl) {
        NSURL *groupUrl = _groupUrlDictionary[assetUrl];
        return groupUrl;
    }
    return nil;
}

- (ALAssetsGroup *)getGroupForAssetUrl:(NSURL *)assetUrl {
    if (assetUrl) {
        NSURL *groupUrl = _groupUrlDictionary[assetUrl];
        return [self groupForUrl:groupUrl];
    }
    return nil;
}

- (void)setMaximumNumberOfPhotos:(NSInteger)numberOfPhotos {
    _maximumPhotos = numberOfPhotos;
}

- (void)setMaximumNumberOfVideos:(NSInteger)numberOfVideos {
    _maximumVideos = numberOfVideos;
}

- (void)setMaximumVideoDuration:(NSTimeInterval)duration {
    _maximumVideoDuration = duration;
}


#pragma mark - Prepare assets to send

- (BOOL)prepareAssetsToSendWithCompletion:(PBPrepareAssetsToSendCompletion)completion {
    @synchronized(self) {
        if (_busy) {
            return NO;
        }
        _busy = YES;
        _cancelled = NO;
    }
    
    NSLog(@"Starting preparing assets");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self _prepareAssetsToSendWithCompletion:completion];
    });
    
    return YES;
}

- (void)_prepareAssetsToSendWithCompletion:(PBPrepareAssetsToSendCompletion)completion {
    NSMutableSet *urls = [NSMutableSet setWithArray:[self assetExportList]];
    
    ContentType checkResult = [self contentTypeForPhotoURLs:[self assetUrlList]];
    if ((checkResult & PHOTOS_MORE_THAN_MAXIMUM) ||
        (checkResult & VIDEOS_MORE_THAN_MAXIMUM) ||
        (checkResult & VIDEOS_DURATION_MORE_THAN_MAXIMUM)) {

        NSString *adFilename = PB_LITE_VERSION_AD_FILENAME;
        NSString *adFilePath = PBApplicationLibraryDirectoryAdd(adFilename);
        NSURL *adURL = [[[NSURL alloc] initFileURLWithPath:adFilePath] autorelease];
        [urls addObject:adURL];
    }

    PBTimeStamp(@"ZIP Start");
    
    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *zipFileName = [NSString stringWithFormat:@"%@_%@.zip", PB_UPLOAD_ARCHIVE_PREFIX, dateString];
    NSString *zipFilePath = [PBTemporaryDirectory() stringByAppendingPathComponent:zipFileName];
    self.assetsZipFilePath = zipFilePath;

    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:zipFilePath mode:ZipFileModeCreate];
    
    NSInteger fileNum = 0;
    NSInteger fileCount = urls.count;
    for (NSURL *assetUrl in urls) {
        @synchronized(self) {
            if (_cancelled) {
                break;
            }
        }

        @autoreleasepool {
            NSURL *assetToZip = [[assetUrl copy] autorelease];

            AVAsset *testAsset = [AVURLAsset assetWithURL:assetUrl];
            if ([[testAsset tracks] count] > 0) {
                assetToZip = [self truncatedVideoFileWithAssetURL:assetToZip];
            }


            if ([assetToZip isFileURL]) {
                NSString *fileName = [assetToZip lastPathComponent];
                NSData *fileData = [NSData dataWithContentsOfURL:assetToZip
                                                         options:NSDataReadingMappedIfSafe
                                                           error:nil];

                if (fileData) {
                    ZipWriteStream *zipWriteStream = [zipFile writeFileInZipWithName:fileName
                                                                    compressionLevel:ZipCompressionLevelNone];

                    [zipWriteStream writeData:fileData];
                    [zipWriteStream finishedWriting];
                }
            }
            else {
                ALAsset *asset = [self assetForUrl:assetToZip];
                NSString *filename = asset.defaultRepresentation.filename;
                
                if (asset) {
                    ZipWriteStream *zipWriteStream = [zipFile writeFileInZipWithName:filename
                                                                    compressionLevel:ZipCompressionLevelNone];
                    
                    [self writeAsset:asset toZipWriteStream:zipWriteStream progressHandler:^(float fileProgress) {
                        CGFloat preProgress = (CGFloat)fileNum / (CGFloat)fileCount;
                        CGFloat currentProgress = 1.0f / (CGFloat)fileCount * fileProgress;
                        CGFloat progress = preProgress + currentProgress;
                        
                        NSDictionary *userInfo = @{kPBProgress : @(progress)};
                        [[NSNotificationCenter defaultCenter]
                            postNotificationName:PBAssetManagerPrepareAssetProgressDidChangeNotification
                            object:nil
                            userInfo:userInfo];
                    }];
                    
                    [zipWriteStream finishedWriting];
                    NSLog(@"Finished writing file: %@", filename);
                }
                else {
                    NSLog(@"!!! Failed to write file: %@", filename);
                }
            }

            fileNum++;

            //post progress notification
            dispatch_async(dispatch_get_main_queue(), ^{
                CGFloat progress = (CGFloat)fileNum / (CGFloat)fileCount;
                NSDictionary *userInfo = @{kPBProgress : @(progress)};
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:PBAssetManagerPrepareAssetProgressDidChangeNotification
                    object:nil
                    userInfo:userInfo];
            });
        }
    }
    
    [zipFile close];
    [zipFile release];
    
    PBTimeStamp(@"ZIP Finish");
    
    @synchronized(self) {
        if (_cancelled) {
            [[NSFileManager defaultManager] removeItemAtPath:zipFileName error:nil];
            NSLog(@"Cancelled preparing ZIP with assets");
            
            self.assetsZipFilePath = nil;

            _readyToSend = NO;
            
            if (_shouldRestart) {
                NSLog(@"Restarting preparing photos");
                _shouldRestart = NO;
                [self prepareAssetsToSendWithCompletion:completion];
            }

        } else {
            NSLog(@"===== %d files written to %@ =====", (int)fileNum, zipFileName.lastPathComponent);
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(zipFileName);
                });
            }
            
            _readyToSend = YES;
            self.assetsZipFilePath = zipFilePath;
            
            //post finsh notification
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userInfo = @{kPBFilePath : zipFilePath};
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:PBAssetManagerPrepareAssetDidFinishNotification
                    object:nil
                    userInfo:userInfo];
            });
        }
    
        _busy = NO;
    }
}

- (ALAsset *)assetForUrl:(NSURL *)url {
    dispatch_semaphore_t mutex = dispatch_semaphore_create(0);
    __block ALAsset *resultAsset = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_assetsLibrary assetForURL:url
                        resultBlock:^(ALAsset *asset) {
                            if (asset) {
                                resultAsset = [asset retain];
                            }
                            dispatch_semaphore_signal(mutex);
                            
                        }
                       failureBlock:^(NSError *error) {
                           dispatch_semaphore_signal(mutex);
                       }];
    });
    
    dispatch_semaphore_wait(mutex, DISPATCH_TIME_FOREVER);
    dispatch_release(mutex);
    
    return [resultAsset autorelease];
}

- (ALAssetsGroup *)groupForUrl:(NSURL *)url {
    if (url == nil) return nil;
    
    dispatch_semaphore_t mutex = dispatch_semaphore_create(0);
    __block ALAssetsGroup *resultGroup = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_assetsLibrary groupForURL:url
            resultBlock:^(ALAssetsGroup *group) {
                if (group) {
                    resultGroup = [group retain];
                }

                dispatch_semaphore_signal(mutex);
            }
            failureBlock:^(NSError *error) {
                dispatch_semaphore_signal(mutex);
            }];
    });
    
    dispatch_semaphore_wait(mutex, DISPATCH_TIME_FOREVER);
    dispatch_release(mutex);
    
    return [resultGroup autorelease];
}

- (void)writeAsset:(ALAsset *)asset
    toZipWriteStream:(ZipWriteStream *)zipWriteStream
    progressHandler:(PBAssetManagerProgressBlock)progressHandler {
    
    ALAssetRepresentation *assetDefaultRepresentation = asset.defaultRepresentation;

    NSUInteger length = assetDefaultRepresentation.size;
    NSUInteger bufferSize = 1024*1024;
    NSMutableData *bufferData = [NSMutableData dataWithLength:bufferSize];
    uint8_t *buffer = [bufferData mutableBytes];
    NSUInteger pos = 0;
    NSRange range;
    while (pos < length) {
        range.location = pos;
        range.length = length-pos < bufferSize ? length-pos : bufferSize;
        if (range.length != bufferSize) {
            [bufferData setLength:range.length];
        }
        
        NSUInteger bytesRead = [assetDefaultRepresentation getBytes:buffer
                                                         fromOffset:range.location
                                                             length:range.length
                                                              error:nil];
        pos += bytesRead;
        
        [zipWriteStream writeData:bufferData];
        
        if (progressHandler) {
            float progress = (float)pos / (float)length;
            dispatch_async(dispatch_get_main_queue(), ^{
                progressHandler(progress);
            });
        }
    }
}

- (NSString *)writeAssetToTempFile:(ALAsset *)asset progressHandler:(PBAssetManagerProgressBlock)progressHandler {
    ALAssetRepresentation *assetDefaultRepresentation = asset.defaultRepresentation;
    NSUInteger length = assetDefaultRepresentation.size;
    
    NSString *tmpFileName = [PBTemporaryDirectory() stringByAppendingPathComponent:assetDefaultRepresentation.filename];
    
    [[NSFileManager defaultManager] createFileAtPath:tmpFileName
                                            contents:nil
                                          attributes:nil];
    
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:tmpFileName];
    
    if (!handle)
        return nil;
    
    NSUInteger bufferSize = 1024*1024;
    NSMutableData *bufferData = [NSMutableData dataWithLength:bufferSize];
    uint8_t *buffer = [bufferData mutableBytes];
    int bytesRead;
    NSInteger totalBytesRead = 0;
    
    do {
        @try {
            bytesRead = (int)[assetDefaultRepresentation getBytes:buffer
                                                       fromOffset:totalBytesRead
                                                           length:bufferSize
                                                            error:nil];
            [bufferData setLength:bytesRead];
            [handle writeData:bufferData];
            totalBytesRead += bytesRead;
        
            if (progressHandler) {
                float progress = (float)totalBytesRead / (float)length;
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressHandler(progress);
                });
            }
        }
        @catch (NSException *exception) {
            return nil;
        }

    } while (bytesRead);

    [handle closeFile];
    
    return tmpFileName;
}

- (void)cancelPreparingAssets {
    @synchronized(self) {
        if (_busy) {
            _cancelled = YES;
        }

        if (_assetsZipFilePath) {
            NSLog(@"Cancelled preparing assets");
            [[NSFileManager defaultManager] removeItemAtPath:_assetsZipFilePath error:nil];
            self.assetsZipFilePath = nil;
        }

        _readyToSend = NO;
    }
}

- (void)restartPreparingAssets {
    @synchronized(self) {
        if (_busy) {
            [self cancelPreparingAssets];
            _shouldRestart = YES;
        } else {
            _shouldRestart = NO;
            [self prepareAssetsToSendWithCompletion:nil];
        }
    }
}

- (BOOL)isBusy {
    @synchronized(self) {
        return _busy;
    }
}

- (BOOL)isReadyToSend {
    @synchronized(self) {
        return _readyToSend;
    }
}


#pragma mark - Truncate exported video files

- (BOOL)shouldTruncateVideoFileWithAssetURL:(NSURL *)assetURL {
    if (0 == _maximumVideoDuration) {
        return NO;
    }

    ALAssetRepresentation *representation = [[self assetForUrl:assetURL] defaultRepresentation];

    AVAsset *asset = [AVURLAsset URLAssetWithURL:[representation url]
                                         options:nil];

    if (CMTimeGetSeconds(asset.duration) > _maximumVideoDuration) {
        return YES;
    }

    return NO;
}

- (AVAssetExportSession *)exportSessionWithAssetURL:(NSURL *)assetURL {
    ALAssetRepresentation *representation = [[self assetForUrl:assetURL] defaultRepresentation];

    AVAsset *asset = [AVURLAsset URLAssetWithURL:[representation url]
                                         options:nil];

    if (nil == asset) {
        return nil;
    }

    AVAssetExportSession *exportSession =
        [[[AVAssetExportSession alloc] initWithAsset:asset
                                         presetName:AVAssetExportPresetPassthrough]
         autorelease];

    exportSession.outputFileType = AVFileTypeQuickTimeMovie;

    
    CMTime beginTime = CMTimeMake(0, 1);
    CMTime endTime = CMTimeMake(_maximumVideoDuration, 1);
    exportSession.timeRange = CMTimeRangeMake(beginTime, endTime);

    NSString *filename = ([assetURL isFileURL])
        ? [assetURL lastPathComponent]
        : [representation filename];


    NSString *exportFileName = [PBTemporaryDirectory() stringByAppendingPathComponent:filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:exportFileName isDirectory:NO]) {
        [fileManager removeItemAtPath:exportFileName error:nil];
    }

    exportSession.outputURL = [NSURL fileURLWithPath:exportFileName];

    return exportSession;
}

- (void)truncatedVideoFileWithAssetURL:(NSURL *)assetURL completion:(void (^)(NSURL *outputURL))completion {
    if (![self shouldTruncateVideoFileWithAssetURL:assetURL]) {
        completion(assetURL);
        return;
    }

    AVAssetExportSession *exportSession = [self exportSessionWithAssetURL:assetURL];
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            completion(exportSession.outputURL);
        }
        else {
            completion(nil);
        }
    }];
}

- (NSURL *)truncatedVideoFileWithAssetURL:(NSURL *)assetURL {
    if (![self shouldTruncateVideoFileWithAssetURL:assetURL]) {
        return assetURL;
    }

    __block NSURL *truncatedFileURL = nil;

    dispatch_semaphore_t mutex = dispatch_semaphore_create(0);

    AVAssetExportSession *exportSession = [self exportSessionWithAssetURL:assetURL];
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            truncatedFileURL = [[exportSession.outputURL copy] autorelease];
        }
        else {
            NSLog(@"%@", exportSession.error);
        }

        dispatch_semaphore_signal(mutex);
    }];

    dispatch_semaphore_wait(mutex, DISPATCH_TIME_FOREVER);

    return truncatedFileURL;
}


#pragma mark - Importing assets

typedef void (^pbAssetsGroupCompletion)(ALAssetsGroup *assetsGroup);

- (void)photoboxAssetsGroupWithCompletion:(pbAssetsGroupCompletion)completion {
    __block BOOL found = NO;
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group) {
                NSString *groupTitle = [group valueForProperty:ALAssetsGroupPropertyName];
                if ([groupTitle isEqualToString:PB_APP_NAME]) {
                    completion(group);
                    found = YES;
                    *stop = YES;
                }
            }
            else if (!found) {
                [_assetsLibrary addAssetsGroupAlbumWithName:PB_APP_NAME
                                                resultBlock:^(ALAssetsGroup *group) {
                                                    completion(group);
                                                }
                                               failureBlock:^(NSError *error) {
                                                   completion(nil);
                                               }];
            }
        }
        failureBlock:^(NSError *error) {
            completion(nil);
        }];
}

- (BOOL)isImportAssetInProgress {
    @synchronized(self) {
        return _importIsInProgress;
    }
}

- (void)importAssetFromFileAtPath:(NSString *)filePath {
    NSString *extension = [[filePath pathExtension] lowercaseString];
    NSString *imageExtensions = @"png,jpg,jpeg,cr2,gif,tiff,tif,cur,ico,xbm";
    
    if ([imageExtensions rangeOfString:extension].location != NSNotFound) {
        [_importOperationQueue addOperationWithBlock:^{
            [self importImageFromFileAtPath:filePath];
        }];

    } else {
        [_importOperationQueue addOperationWithBlock:^{
            [self importVideoFromFileAtPath:filePath];
        }];
    }
}

- (void)importImageFromFileAtPath:(NSString *)filePath {
    ALAssetsLibraryWriteImageCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error) {
        @synchronized(self) {
            _importIsInProgress = NO;
        }
        if (assetURL) {
            [self photoboxAssetsGroupWithCompletion:^(ALAssetsGroup *assetsGroup) {
                if (assetsGroup) {
                    [_assetsLibrary assetForURL:assetURL
                        resultBlock:^(ALAsset *asset) {
                            [assetsGroup addAsset:asset];
                            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                            NSLog(@"Added image: %@", [filePath lastPathComponent]);
                        }
                        failureBlock:^(NSError *error) {
                            NSLog(@"Failed to write image. %@", error);
                            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                            [self postDidFailImportAssetNotification];
                        }];
                }
                else {
                    NSLog(@"Failed to get asset group");
                }
            }];
        }
        else {
            if (error.code == ALAssetsLibraryWriteBusyError) {
                NSLog(@"AssetsLibrary is busy. Scheduling image import for a bit later, %@", [filePath lastPathComponent]);
                int64_t delayInSeconds = 1.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
                    [self importImageFromFileAtPath:filePath];
                });
            } else {
                NSLog(@"Failed to write asset, %@", error);
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                [self postDidFailImportAssetNotification];
            }
        }
    };
    
    NSData *imageData = [NSData dataWithContentsOfFile:filePath
                                               options:NSDataReadingMapped
                                                 error:nil];

    UIImage *testImage = [UIImage imageWithData:imageData];
    if (nil == testImage) {
        [self postDidFailImportAssetNotification];
        return;
    }

    if (imageData) {
        [_assetsLibrary writeImageDataToSavedPhotosAlbum:imageData
                                                metadata:nil
                                         completionBlock:completionBlock];
    }
}

- (void)importVideoFromFileAtPath:(NSString *)filePath {
    ALAssetsLibraryWriteVideoCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error) {
        @synchronized(self) {
            _importIsInProgress = NO;
        }
        if (assetURL) {
            [self photoboxAssetsGroupWithCompletion:^(ALAssetsGroup *assetsGroup) {
                if (assetsGroup) {
                    [_assetsLibrary assetForURL:assetURL
                        resultBlock:^(ALAsset *asset) {
                            [assetsGroup addAsset:asset];
                            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                            NSLog(@"Added video: %@", [filePath lastPathComponent]);
                        }
                        failureBlock:^(NSError *error) {
                            NSLog(@"Failed to write video. %@", error);
                            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];

                            [self postDidFailImportAssetNotification];
                        }];
                }
                else {
                    NSLog(@"Failed to get asset group");
                }
            }];
        }
        else {
            if (error.code == ALAssetsLibraryWriteBusyError) {
                NSLog(@"AssetsLibrary is busy. Scheduling video import for a bit later, %@", [filePath lastPathComponent]);
                int64_t delayInSeconds = 1.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
                    [self importVideoFromFileAtPath:filePath];
                });
            } else {
                NSLog(@"Failed to write asset, %@", error);
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];

                [self postDidFailImportAssetNotification];
            }
        }
    };
    
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    if (NO == [_assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:fileUrl]) {
        [self postDidFailImportAssetNotification];
        return;
    }

    if (fileUrl) {
        [_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:fileUrl completionBlock:completionBlock];
    }
}

- (void)importFailImageWithFileName:(NSString *)fileName {

    // Render label above image and save to tmp folder

    UIImage *failureImage = [UIImage imageNamed:@"no_photolibrary_acces_screen-ipad@2x"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:failureImage];
    CGRect labelFrame = CGRectMake(0, 0, failureImage.size.width, 40);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor lightGrayColor];


    // adding date

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY.MM.dd";
    label.text = [NSString stringWithFormat:NSLocalizedString(@"Saving failed: %@\n%@", @""), fileName, [formatter stringFromDate:[NSDate date]]];
    [formatter release];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    [imageView addSubview:label];
    [label release];

    UIGraphicsBeginImageContext(imageView.bounds.size);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [imageView release];
    
    NSString *imagePath = [PBTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_failure.png", fileName]];
    [UIImagePNGRepresentation(resultingImage) writeToFile:imagePath atomically:YES];
    
    [self importImageFromFileAtPath:imagePath];
}

- (void)postDidFailImportAssetNotification {
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSNotification *notification = [NSNotification
            notificationWithName:PBAssetManagerDidFailedToImportAssetToLibrary
            object:nil];

        [[NSNotificationCenter defaultCenter]
            performSelectorOnMainThread:@selector(postNotification:)
            withObject:notification
            waitUntilDone:NO];
    });
}

@end


#pragma mark - PBAssetInputStream class

/**
 *  PBAssetInputStream provide direct access to asset content over by
 *      subclass of NSInputStream
 */
@interface PBAssetInputStream() {
    long long _totalSize;
    long long _currentPosition;

    NSError *_error;
    NSStreamStatus _status;
    id<NSStreamDelegate> _delegate;

    CFReadStreamClientCallBack _copiedCallback;
    CFStreamClientContext _copiedContext;
    CFOptionFlags _requestedEvents;
}

@property (nonatomic, strong) ALAsset *asset;
@end

@implementation PBAssetInputStream

- (PBAssetInputStream *)initWithAssetURL:(NSURL *)assetURL {
    self = [super init];

    if (nil != self) {
        _assetURL = [assetURL copy];
        self.asset = [[PBAssetManager sharedManager] assetForUrl:_assetURL];

        _totalSize = _asset.defaultRepresentation.size;
        _currentPosition = 0;
        
        [self setStatus:NSStreamStatusNotOpen];
        [self setDelegate:self];
    }

    return self;
}

- (NSString *)fileName {
    if (nil != _asset) {
        return _asset.defaultRepresentation.filename;
    }

    return nil;
}

- (long long)totalSize {
    return _totalSize;
}


#pragma mark - NSStream methods

- (void)setDelegate:(id<NSStreamDelegate>)delegate {
    if (nil == delegate) {
        _delegate = self;
    }
    else {
        _delegate = delegate;
    }
}

- (id<NSStreamDelegate>)delegate {
    return _delegate;
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return NO;
}

- (id)propertyForKey:(NSString *)key {
    return nil;
}

- (void)open {
    _currentPosition = 0;

    [self setStatus:NSStreamStatusOpening];

    if (nil != _asset) {
        [self setStatus:NSStreamStatusOpen];
    }
    else {
        [self setStatus:NSStreamStatusError];
    }
}

- (void)close {
    [self setStatus:NSStreamStatusClosed];
    _currentPosition = 0;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // Do nothing
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // Do nothing
}

- (BOOL)hasBytesAvailable {
    return (_totalSize > _currentPosition);
}

- (NSStreamStatus)streamStatus {
    return _status;
}

- (void)setStatus:(NSStreamStatus)newStatus {
    _status = newStatus;
}

- (NSError *)streamError {
    return _error;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
    return NO;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    [self setStatus:NSStreamStatusReading];

    NSUInteger bytesRead = [_asset.defaultRepresentation getBytes:buffer
        fromOffset:_currentPosition
        length:len
        error:&_error];

    if (nil != _error) {
        [self setStatus:NSStreamStatusError];
        NSLog(@"%@", [_error localizedDescription]);

        return bytesRead;
    }

    // FIXME: Endless loop possible.
    // bytesRead == 0 is also an error,
    // but assume here that next iteration will get some data

    
    _currentPosition += bytesRead;

    if ([self hasBytesAvailable]) {
        [self setStatus:NSStreamStatusOpen];
        if (_copiedCallback && (_requestedEvents & kCFStreamEventHasBytesAvailable)) {
            if (RDGetSystemVersion() >= 8.0 && _copiedContext.retain == nil) {
                _copiedCallback((CFReadStreamRef)self, kCFStreamEventHasBytesAvailable, NULL);
            }
            else {
                _copiedCallback((CFReadStreamRef)self, kCFStreamEventHasBytesAvailable, &_copiedContext);
            }

        }
    }
    else {
        [self setStatus:NSStreamStatusAtEnd];
    }

    return bytesRead;
}


#pragma mark - Privat

- (void)_scheduleInCFRunLoop:(NSRunLoop *)inRunLoop forMode:(id)inMode {
    // Do nothing
}

- (void)_unscheduleFromRunLoop:(NSRunLoop *)inRunLoop forMode:(id)inMode {
    // Do nothing
}

- (BOOL)_setCFClientFlags:(CFOptionFlags)inFlags
                 callback:(CFReadStreamClientCallBack)inCallback
                  context:(CFStreamClientContext *)inContext {

    if (NULL != inCallback) {
        _requestedEvents = inFlags;
        _copiedCallback = inCallback;
        memcpy(&_copiedContext, inContext, sizeof(CFStreamClientContext));

        if (_copiedContext.info && _copiedContext.retain) {
            _copiedContext.retain(_copiedContext.info);
        }

       // _copiedCallback((CFReadStreamRef)self, kCFStreamEventHasBytesAvailable, NULL);
        if (RDGetSystemVersion() >= 8.0 && _copiedContext.retain == nil) {
            _copiedCallback((CFReadStreamRef)self, kCFStreamEventHasBytesAvailable, NULL);
        }
        else {
            _copiedCallback((CFReadStreamRef)self, kCFStreamEventHasBytesAvailable, &_copiedContext);
        }

    }
    else {
        _requestedEvents = kCFStreamEventNone;
        _copiedCallback = NULL;

        if (_copiedContext.info && _copiedContext.release) {
            _copiedContext.release(_copiedContext.info);
        }

        memset(&_copiedContext, 0, sizeof(CFStreamClientContext));
    }

    return YES;
}


#pragma mark - Memory management

- (void)dealloc {
    _delegate = nil;

    [_assetURL release];
    _assetURL = nil;

    [_asset release];
    _asset = nil;

    _error = nil;

    [super dealloc];
}

@end
