
#import "AFHTTPSessionManager.h"

@class LSITunesSoftwareItem;

typedef void (^LSITunesSoftwareItemCompletionBlock)(LSITunesSoftwareItem *softwareItem, NSError *error);

typedef void (^LSITunesRssFeedCompletionBlock)(NSArray *items, NSError *error);

@protocol LSITunesRequest <NSObject>

- (void)cancel;

@end

@protocol LSITunesClient <NSObject>

+ (void)setSharedClient:(id<LSITunesClient>)client;

+ (id<LSITunesClient>)sharedClient;

- (id<LSITunesRequest>)softwareItemWithID:(NSString *)itemID
                                  country:(NSString *)countryCode
                               completion:(LSITunesSoftwareItemCompletionBlock)completion;

- (id<LSITunesRequest>)topSongsForCountry:(NSString *)countryCode
                               completion:(LSITunesRssFeedCompletionBlock)completion;
@end







@interface LSITunesClient : AFHTTPSessionManager <LSITunesClient>

+ (instancetype)client;

@end
