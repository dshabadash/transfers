//
//  PBAssetUploader.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 14/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "PBAssetUploader.h"
#import "PBAssetManager.h"
#import "RDHTTP.h"
#import "PBServiceBrowser.h"
#import "PBMongooseServer.h"

NSString * const PBAssetUploaderUploadProgressDidUpdateNotification = @"PBAssetUploaderUploadProgressDidUpdateNotification";
NSString * const PBAssetUploaderUploadDidFinishNotification = @"PBAssetUploaderUploadDidFinishNotification";

@interface PBAssetUploader () {
    NSMutableArray *_assetUrls;
    NSMutableSet *_truncatedFiles;
    BOOL _uploadCanceled;
    NSEnumerator *_assetsEnumerator;
}

@property (strong, nonatomic) RDHTTPOperation *requestOperation;
@property (copy, nonatomic) NSString *deviceName;
@property (copy, nonatomic) NSString *deviceType;
@property (copy, nonatomic) NSString *deviceUrlString;
@property (copy, nonatomic) NSString *uploadUrlString;
@end

@implementation PBAssetUploader

+ (instancetype)uploader {
    return [[[self class] new] autorelease];
}

- (id)init {
    self = [super init];

    if (nil != self) {
        _uploadCanceled = NO;
        _assetUrls = [NSMutableArray new];
        _truncatedFiles = [[NSMutableSet setWithCapacity:0] retain];

        [self registerOnTransferWasCanceledNotification];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (nil != _assetUrls) {
        [_assetUrls removeAllObjects];
        [_assetUrls release];
        _assetUrls = nil;
    }

    [_truncatedFiles removeAllObjects];
    [_truncatedFiles release];
    _truncatedFiles = nil;

    [_uploadUrlString release];
    _uploadUrlString = nil;
    
    [_deviceName release];
    _deviceName = nil;

    [_deviceType release];
    _deviceType = nil;

    [_requestOperation release];
    _requestOperation = nil;

    [_assetsEnumerator release];
    _assetsEnumerator = nil;

    [super dealloc];
}

- (void)sendAssetsToDeviceWithUrlString:(NSString *)deviceUrlString
                             deviceName:(NSString *)deviceName
                             deviceType:(NSString *)deviceType {

    self.deviceName = deviceName;
    self.deviceUrlString = deviceUrlString;
    self.deviceType = deviceType;
    self.uploadUrlString = [deviceUrlString stringByAppendingString:@"upload"];

    [self sendDidBeginUploadNotification];

    NSArray *assets = [[PBAssetManager sharedManager] assetExportList];
    [_assetUrls removeAllObjects];
    [_assetUrls addObjectsFromArray:assets];
    [self beginTransfer];


    [self retain];
}


- (void)sendNextAsset {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (_uploadCanceled) {
            [self cancelUpload];
            return;
        }


        NSURL *url = [self nextURL];
        
        if (nil == url) {
            [self finishTransfer];
            return;
        }


        ALAsset *asset = [[PBAssetManager sharedManager] assetForUrl:url];
        if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo]) {
            [[PBAssetManager sharedManager] truncatedVideoFileWithAssetURL:url
                completion:^(NSURL *outputURL) {
                    if ([outputURL isFileURL]) {
                        [_truncatedFiles addObject:outputURL];
                    }

                    [self sendAssetWithURL:outputURL];
                }];
        }
        else {
            [self sendAssetWithURL:url];
        }

    });
}

- (void)sendAssetWithURL:(NSURL *)url {
    NSInteger totalAssetsNumber = [_assetUrls count];
    float fraction = 1.0f / (float)totalAssetsNumber;
    id progressHandler = ^(float currentItemProgress) {
        if (_uploadCanceled) {
            [self cancelUpload];
            return;
        }

        NSInteger currentAssetNumber = [_assetUrls indexOfObject:url];
        float progress = ((float)(totalAssetsNumber - currentAssetNumber - 1) * fraction) + (fraction * currentItemProgress);
        NSDictionary *userInfo = @{kPBProgress : @(progress),
                                   kPBDeviceName : self.deviceName,
                                   kPBDeviceType : self.deviceType};
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBAssetUploaderUploadProgressDidUpdateNotification
            object:nil
            userInfo:userInfo];
    };

    __block id myself = self;
    void (^completion)(void) = ^{
        if (_uploadCanceled) {
            [myself cancelUpload];
            return;
        }

        _requestOperation = nil;
        [myself sendNextAsset];
    };


    RDHTTPRequest *rq = [RDHTTPRequest postRequestWithURLString:_uploadUrlString];
    [rq setValue:[PBAppDelegate serviceName] forHTTPHeaderField:@"X-Device-Name"];
    [rq setValue:[[UIDevice currentDevice] model] forHTTPHeaderField:@"X-Device-Type"];
    [rq setUploadProgressHandler:progressHandler];

    if ([url isFileURL]) {
        NSLog(@"Uploading file: %@", url);

        NSString *filePath = [url path];
        [rq setHTTPBodyFilePath:filePath guessContentType:YES];
        [rq setValue:[filePath lastPathComponent] forHTTPHeaderField:@"X-File-Name"];
        [rq setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    }
    else {
        NSLog(@"Uploading asset: %@", url);

        PBAssetInputStream *inputStream = [[[PBAssetInputStream alloc] initWithAssetURL:url] autorelease];
        if (nil == inputStream) {
            NSLog(@"Failed to open asset %@. \nSkipping", url);

            completion();
            return;
        }

        NSString *fileName = [inputStream fileName];
        [rq setValue:fileName forHTTPHeaderField:@"X-File-Name"];

        // "Content-Length" is needed because of PBMongooseServer, which is skiping posted files
        //  without this header
        NSString *lengthString = [NSString stringWithFormat:@"%lld", [inputStream totalSize]];
        [rq setValue:lengthString forHTTPHeaderField:@"Content-Length"];

        [rq setHTTPBodyStream:inputStream contentType:@"application/octet-stream"];
        [rq setHTTPBodyStreamCreationBlock:^NSInputStream *{
            PBAssetInputStream *inputStream = [[PBAssetInputStream alloc] initWithAssetURL:url];
            return inputStream;
        }];
    }


    self.requestOperation = [rq startWithCompletionHandler:^(RDHTTPResponse *response) {
        NSLog(@"Upload complete:\n url:%@\n httpError: %@\n error: %@", url, response.httpError, response.error);

        completion();
    }];
}

- (NSURL *)nextURL {
    NSURL *nextURL = [_assetsEnumerator nextObject];

    return nextURL;
}

- (void)beginTransfer {
    _assetsEnumerator = [[_assetUrls objectEnumerator] retain];

    [self sendStatistic];

    PBTransferSession *session =
        [[PBTransferSession alloc] initWithDeviceName:self.deviceName
                                            URLString:self.deviceUrlString];

    [[PBAppDelegate sharedDelegate] setTransferSession:session];

    __block id myself = self;
    [session beginSessionCompletion:^(BOOL started) {
        if (started) {
            [myself sendNextAsset];
        }
        else {
            [myself cancelUpload];
        }
    }];
}

- (void)finishTransfer {
    NSLog(@"All assets Upload complete");

    _requestOperation = nil;

    [self removeTemporaryFiles];


    __block id myself = self;
    [[PBAppDelegate sharedDelegate].transferSession finishSessionCompletion:^{
        [[PBAppDelegate sharedDelegate] setTransferSession:nil];

        //post notification here
        [self sendDidFinishUploadNotification];

        [myself release];
    }];
}

- (void)cancelUpload {
    if (_uploadCanceled) {
        return;
    }

    _uploadCanceled = YES;

    
    NSLog(@"AssertUploader: cancel upload");

    if (nil != _requestOperation && _requestOperation.isExecuting) {
        [_requestOperation cancel];
        self.requestOperation = nil;
    }

    NSString *zipFilePath = [[PBAssetManager sharedManager] assetsZipFilePath];
    [self removeUploadedFilePath:zipFilePath];
    [self removeTemporaryFiles];

    PBTransferSession *session = [PBAppDelegate sharedDelegate].transferSession;
    if (nil != session) {
        [session cancel];
    }

    [self release];
}

- (void)removeTemporaryFiles {
    [self removeFiles:_assetUrls];
    [_assetUrls removeAllObjects];

    [self removeFiles:[_truncatedFiles allObjects]];
    [_truncatedFiles removeAllObjects];
}

- (void)removeFiles:(NSArray *)urls {
    for (NSURL *URLToDelete in urls) {
        if ([URLToDelete isFileURL]) {
            NSString *pathToDelete = [URLToDelete path];
            [self removeUploadedFilePath:pathToDelete];
        }
    }
}

- (void)removeUploadedFilePath:(NSString *)filePath {
    if (nil == filePath) {
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath isDirectory:NO]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
}


#pragma mark - Notifications

- (void)registerOnTransferWasCanceledNotification {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(transferWasCanceled:)
        name:PBTransferWasCanceledNotification
        object:nil];
}

- (void)transferWasCanceled:(NSNotification *)notification {
    [self cancelUpload];
}

- (void)sendDidFinishUploadNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBAssetUploaderUploadDidFinishNotification
            object:nil
            userInfo:nil];
    });
}

- (void)sendDidBeginUploadNotification {
    // Send notification to indicate that upload has started
    NSDictionary *userInfo = @{kPBProgress : @(0.0),
                               kPBDeviceName : self.deviceName,
                               kPBDeviceType : self.deviceType};

    [[NSNotificationCenter defaultCenter]
        postNotificationName:PBAssetUploaderUploadProgressDidUpdateNotification
        object:nil
        userInfo:userInfo];
}


#pragma mark - Statistic

- (void)sendStatistic {
    CBAnalyticsManager *analyticsManager = [CBAnalyticsManager sharedManager];

    NSInteger photosNumber = [[PBAssetManager sharedManager] selectedPhotosNumber];
    NSString *photosNumberString = [NSString stringWithInteger:photosNumber];
    [analyticsManager logEvent:@"SendPhotosNumber"
        withParameters:@{@"photosNumber" : photosNumberString}];

    NSInteger videosNumber = [[PBAssetManager sharedManager] selectedVideosNumber];
    NSString *videosNumberString = [NSString stringWithInteger:videosNumber];
    [analyticsManager logEvent:@"SendVideosNumber"
        withParameters:@{@"videosNumber" : videosNumberString}];

    NSDictionary *parameters = @{@"photosNumber" : photosNumberString,
                                 @"videosNumber" : videosNumberString};


    NSString *deviceType = [[UIDevice currentDevice] model];
    NSString *transferDirection = [NSString stringWithFormat:@"SendFrom%@To%@", deviceType, _deviceType];
    [analyticsManager logEvent:@"TransferDirection"
        withParameters:@{@"direction" : transferDirection}];
    
    [analyticsManager logEvent:transferDirection withParameters:parameters];
}

@end
