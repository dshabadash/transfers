
#import "LSITunesClient.h"
#import "LSITunesSoftwareItem.h"
#import "LSItunesRssFeedItem.h"



#define BASE_URL @"https://itunes.apple.com/"


static id<LSITunesClient> _sharedClient;



@implementation LSITunesClient

+ (instancetype)client{
    NSURL *url = [NSURL URLWithString:BASE_URL];
    LSITunesClient *client = [[LSITunesClient alloc] initWithBaseURL:url];
    client.responseSerializer = [AFJSONResponseSerializer serializer];
    return client;
}

+ (void)setSharedClient:(id<LSITunesClient>)client{
    if(client!=_sharedClient){
        _sharedClient = client;
    }
}

+ (id<LSITunesClient>)sharedClient{
    return _sharedClient;
}

- (id<LSITunesRequest>)softwareItemWithID:(NSString *)itemID
                                  country:(NSString *)countryCode
                               completion:(LSITunesSoftwareItemCompletionBlock)completion{
    
    NSAssert(itemID, @"itemID is nil");
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:itemID forKey:@"id"];

    if (countryCode) {
        [params setObject:countryCode forKey:@"country"];
    }
    
    id<LSITunesRequest> request = (id<LSITunesRequest>)[self GET:@"lookup" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        
            NSArray *results = responseObject[@"results"];
            NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[results count]];
        
            for (NSDictionary *jsonObj in results) {
                NSError *error = nil;
                LSITunesSoftwareItem *object = [MTLJSONAdapter modelOfClass:[LSITunesSoftwareItem class] fromJSONDictionary:jsonObj error:&error];
            
                if (object && !error) {
                    [objects addObject:object];
                } else {
                    NSLog(@"Error processing object: %@", jsonObj);
                }
            }
        
            if (completion) completion([objects lastObject], nil);
        
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            if (completion) completion(nil, error);
        }];
    
    return request;
}

- (id<LSITunesRequest>)topSongsForCountry:(NSString *)countryCode
                               completion:(LSITunesRssFeedCompletionBlock)completion{
    
    NSAssert(countryCode, @"countryCode is nil");
    
    NSString *getPath = [NSString stringWithFormat:@"%@/rss/topsongs/limit=100/json",countryCode];
    
    id<LSITunesRequest> request = (id<LSITunesRequest>)[self GET:getPath parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSArray *results = responseObject[@"feed"][@"entry"];
        NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[results count]];
        
        for (NSDictionary *jsonObj in results) {
            NSError *error = nil;
            LSItunesRssFeedItem *object = [MTLJSONAdapter modelOfClass:[LSItunesRssFeedItem class] fromJSONDictionary:jsonObj error:&error];
            
            if (object && !error) {
                [objects addObject:object];
            } else {
                NSLog(@"Error processing object: %@", jsonObj);
            }
        }
        
        if (completion) completion(objects, nil);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (completion) completion(nil, error);
    }];
    
    return request;
}

@end
