//
//  LSAppUpdateManager.m
//  MyApp
//
//  Created by ameleshko on 12/26/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "LSAppUpdateManager.h"
#import "LSITunesClient.h"
#import "LSITunesSoftwareItem.h"
#import "NSString+LSAdditions.h"
#import "NSNotificationCenter+LSAdditions.h"
#import "WhatsNewViewController.h"
#import "Appirater.h"


NSString * const LSAppUpdateManagerDidFinishCheckForUpdateNotification = @"LSAppUpdateManagerDidFinishCheckForUpdateNotification";


static id<LSAppUpdateManager> _sharedManager;

@implementation LSAppUpdateManager

+ (void)setSharedManager:(id<LSAppUpdateManager>)manager{
    _sharedManager = manager;
}

+ (id<LSAppUpdateManager>)sharedManager{
    return _sharedManager;
}

@end


NSString * const kLSAppUpdateManagerLastVersionInfo = @"kLSAppUpdateManagerLastVersionInfo";
NSString * const kLSAppUpdateManagerLastUserPromt = @"kLSAppUpdateManagerLastUserPromt";
NSString * const kLSAppUpdateManagerLastStartedAppVersion = @"kLSAppUpdateManagerLastStartedAppVersion";



@interface LSAppVersionInfo : NSObject

@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *trackId;
@property (nonatomic, copy) NSString *releaseNotes;
@property (nonatomic, copy) NSString *trackViewUrl;

-(instancetype)initWithDictionary:(NSDictionary *)dict;

- (instancetype)initWithItunesItem:(LSITunesSoftwareItem *)item;

- (NSDictionary *)dictionaryRepresentation;

@end

@implementation LSAppVersionInfo


-(instancetype)initWithDictionary:(NSDictionary *)dict{
    self = [super init];
    if (self != nil){
        self.version = [dict objectForKey:@"version"];
        self.trackId = [dict objectForKey:@"trackId"];
        self.releaseNotes = [dict objectForKey:@"releaseNotes"];
        self.trackViewUrl = [dict objectForKey:@"trackViewUrl"];
    }
    return self;
}

- (instancetype)initWithItunesItem:(LSITunesSoftwareItem *)item{
    self = [super init];
    if(self){
        self.version = item.version;
        self.trackId = item.trackId;
        self.releaseNotes = item.releaseNotes;
        self.trackViewUrl = item.trackViewUrl;
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if(self.version){
        [dict setObject:self.version forKey:@"version"];
    }
    if(self.trackId){
        [dict setObject:self.trackId forKey:@"trackId"];
    }
    if(self.releaseNotes){
        [dict setObject:self.releaseNotes forKey:@"releaseNotes"];
    }
    if(self.trackViewUrl){
        [dict setObject:self.trackViewUrl forKey:@"trackViewUrl"];
    }
    return dict;
}

@end



@interface  LSItunesAppUpdateManager (){
    LSAppVersionInfo *_lastAppVersionInfo;
    NSString *_lastUserPromt;
    NSString *_lastStartedAppVersion;
}

@property (nonatomic,strong)LSITunesClient *itunesClient;

@property (nonatomic,copy)NSString *appID;

- (void)saveLastVersionInfo:(LSAppVersionInfo *)lastVersionInfo;

@end



@implementation LSItunesAppUpdateManager


- (instancetype)initWithAppID:(NSString *)appID{
    self = [super init];
    if(self){
        
        self.itunesClient = [LSITunesClient client];
        self.appID = appID;
        
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kLSAppUpdateManagerLastVersionInfo];
        if(dict){
            _lastAppVersionInfo = [[LSAppVersionInfo alloc] initWithDictionary:dict];
        }
        _lastUserPromt = [[NSUserDefaults standardUserDefaults] stringForKey:kLSAppUpdateManagerLastUserPromt];
        _lastStartedAppVersion = [[NSUserDefaults standardUserDefaults] stringForKey:kLSAppUpdateManagerLastStartedAppVersion];
    }
    return self;
}

- (NSString *)currentAppVersion{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return version;
}

- (void)saveLastVersionInfo:(LSAppVersionInfo *)lastVersionInfo{
    if(lastVersionInfo){
        [[NSUserDefaults standardUserDefaults] setObject:[lastVersionInfo dictionaryRepresentation] forKey:kLSAppUpdateManagerLastVersionInfo];
        
    } else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLSAppUpdateManagerLastVersionInfo];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    _lastAppVersionInfo = lastVersionInfo;
}

- (void)saveLastUserPromt:(NSString *)version{
    
    if(version){
        [[NSUserDefaults standardUserDefaults] setObject:version forKey:kLSAppUpdateManagerLastUserPromt];
    } else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLSAppUpdateManagerLastUserPromt];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    _lastUserPromt = version;
}

- (NSString *)lastAppVersionURL{
    return _lastAppVersionInfo.trackViewUrl;
}

- (NSString *)lastAppVersion{
    return _lastAppVersionInfo.version;
}

- (NSString *)lastAppReleaseNotes{
    return _lastAppVersionInfo.releaseNotes;
}

- (NSString *)lastUserPromt{
    return _lastUserPromt;
}

- (BOOL)isUpdateRequired{
    if([self lastAppVersion]!=nil){
        return (NSOrderedAscending == [[NSString class] compareVersion:[self currentAppVersion] toVersion:[self lastAppVersion]]);
    }
    return NO;
}

- (void)updateApplication{
    NSURL *url = [NSURL URLWithString:[self lastAppVersionURL]];
    [[UIApplication sharedApplication] openURL:url];
}

- (BOOL)shouldShowUpdateAvailableUserPromt{
    if([self lastAppVersion]!=nil && [self isUpdateRequired]){
        return (NSOrderedAscending == [[NSString class] compareVersion:[self lastUserPromt] toVersion:[self lastAppVersion]]);
    }
    return NO;
}

- (void)showUpdateAvailableUserPromtWithCompletion:(void(^)(void))completion{
   
    //removed
      
}

- (void)saveLastStartedAppVersion{
    NSString *version = [self currentAppVersion];
    if(version){
        [[NSUserDefaults standardUserDefaults] setObject:version forKey:kLSAppUpdateManagerLastStartedAppVersion];
    }
    else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLSAppUpdateManagerLastStartedAppVersion];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    _lastStartedAppVersion = version;
}

- (NSString *)lastStartedAppVersion{
    return _lastStartedAppVersion;
}

- (BOOL)shouldShowWhatsNewUserPromt{
    return (NSOrderedAscending == [[NSString class] compareVersion:[self lastStartedAppVersion] toVersion:[self currentAppVersion]]);
}

- (BOOL)isCurrentAppVersionLastPublished{
    return NSOrderedSame == [[NSString class] compareVersion:[self currentAppVersion] toVersion:[self lastAppVersion]];
}

- (void)showWhatsNewUserPromtWithCompletion:(LSAppUpdateManagerCompletionBlock)completion{
    
    __weak typeof (self) weakSelf = self;
    
    void(^completionBlock)(void) = ^{
        
        NSString *appNameWithVersion = [NSString stringWithFormat:@"%@ %@",APPIRATER_APP_NAME,[weakSelf currentAppVersion]];
        
        NSString *rateTitle = [NSString stringWithFormat:@"%@ %@",[NSString stringWithFormat:NSLocalizedString(@"We hope you'll like everything we added in %@.", @""),appNameWithVersion],NSLocalizedString(@"Please rate it on the App Store and tell your friends about it.", @"")];
        
        NSString *rateButtonTitle = APPIRATER_RATE_BUTTON;
        
        NSDictionary *rateInfo = [WhatsNewViewController rateInfoWithMessage:rateTitle title:rateButtonTitle];
        
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Meet %@", @""),appNameWithVersion];
        
        NSString *detail = nil;
        
        if([weakSelf isCurrentAppVersionLastPublished]){
            detail = [weakSelf lastAppReleaseNotes];
        }
        else{
            detail = [NSString stringWithFormat:@"- %@\n- %@",
                      NSLocalizedString(@"Stability fixes.", @""),
                      NSLocalizedString(@"General performance improvements.", @"")];
        }
        
        WhatsNewViewController *vc = [[WhatsNewViewController alloc] initWithTitle:title detail:detail rateInfo:rateInfo completion:completion];
        [vc show:YES];
    };
    
    if([self isCurrentAppVersionLastPublished]){
        completionBlock();
    }
    else{
        [self checkForUpdateWithCompletion:completionBlock];
    }
    
}

- (void)notifyDidFinishCheck{
    [[NSNotificationCenter defaultCenter] postInMainThreadNotificationName:LSAppUpdateManagerDidFinishCheckForUpdateNotification object:nil];
}

- (id<LSAppUpdateRequest>)checkForUpdateWithCompletion:(LSAppUpdateManagerCompletionBlock)completion{
    
    NSString *language = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0] lowercaseString];
    NSString *country = nil;//[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    
    if([language isEqual:@"ru"]){
        country = @"RU";
    }
    else if([language isEqual:@"de"]){
        country = @"DE";
    }
    else if([language isEqual:@"en"]){
        country = @"US";
    }
    else{
        NSAssert(NO, @"unknown language");
        country = nil;//default country US
    }
    
    id<LSITunesRequest> r = [self.itunesClient softwareItemWithID:self.appID country:country completion:^(LSITunesSoftwareItem *softwareItem, NSError *error) {
        
        if(softwareItem!=nil){
            LSAppVersionInfo *versionInfo = [[LSAppVersionInfo alloc] initWithItunesItem:softwareItem];
            [self saveLastVersionInfo:versionInfo];
        }
        
        [self notifyDidFinishCheck];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completion){
                completion();
            }
        });
        
    }];
    
    return (id<LSAppUpdateRequest>)r;
}

@end


