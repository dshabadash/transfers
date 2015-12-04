//
//  PBConnectionManager.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 26/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBConnectionManager.h"
#import "RSReachability.h"
#import "RDHTTP.h"
#import "NSData+CB.h"

#if PB_LITE
#import "PBPurchaseManager.h"
#endif

NSString * const PBConnectionManagerPermanentUrlPrefix = @"http://sendp.com";
NSString * const PBConnectionManagerPermanentUrlDidChangeNotification = @"PBConnectionManagerPermanentUrlDidChangeNotification";

@interface PBConnectionManager () {
    BOOL _retrievePermanentUrlIsInProgress;
}

@property (copy, atomic) NSString *permanentId;
@property (retain, nonatomic) RSReachability *reachability;

@end

@implementation PBConnectionManager

+ (id)sharedManager {
    static id sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
    });

    return sharedManager;
}

+ (void)start {
    //this will actually create PBConnectionManager singletone and start it
    [self sharedManager];
}

- (id)init {
    self = [super init];
    if (self) {
        [self startReachability];
    }

    return self;
}


#pragma mark - Reachability

- (void)startReachability {
    
    // allocate a reachability object
    RSReachability* reachability = [RSReachability RSReachabilityForInternetConnection];
    self.reachability = reachability; //this will keep reachability instance living for a long time

    
    // here we set up a NSNotification observer. The Reachability that caused the notification
    // is passed in the object parameter

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(reachabilityChanged:)
                               name:kRSReachabilityChangedNotification
                             object:nil];


    [notificationCenter addObserver:self
                           selector:@selector(requestUpdatePermalink)
                               name:PBApplicationDidBecomeActiveNotification
                             object:nil];


    [reachability startNotifier];
}

- (void)reachabilityChanged:(NSNotification *)notification {
    RSReachability *reachability = notification.object;
    BOOL reachableViaWiFi = reachability.currentRSReachabilityStatus == RSReachableViaWiFi;
    if (reachableViaWiFi) {
        NSLog(@"Reachable via WiFi");
        self.permanentId = nil;
        [self performSelector:@selector(requestUpdatePermalink) withObject:nil afterDelay:1.0];
    } else {
        NSLog(@"Not reachable via WiFi");
        self.permanentId = nil;
    }
}


#pragma mark - Permalink

- (NSString *)encryptedMacAddressString:(NSString *)macAddressString {
    NSString *str = [macAddressString stringByReplacingOccurrencesOfString:@":" withString:@""];
    str = [str lowercaseString];

    NSMutableString *tmpString = [NSMutableString string];

    for (NSInteger i=0; i<str.length; i++) {
        unichar c = [str characterAtIndex:i];
        if (c >= '0' && c <= '9') {
            c = 'z' - (c - '0');
        } else {
            c += 6;
        }
        [tmpString appendFormat:@"%C", c];
    }
    
    
//    NSLog(@"\n\nBefore: %@ \nAfter: %@", macAddressString, tmpString);
    return [NSString stringWithString:tmpString];
}

- (NSString *)keyWithFormat:(NSString *)format mac:(NSString *)encryptedMacAddrString ip:(NSString *)ip {
    NSString *encodedDeviceId = [NSString stringWithFormat:format, ip, encryptedMacAddrString];
    NSData *encodedDeviceIdData = [encodedDeviceId dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger crc32 = [encodedDeviceIdData crc32];
    NSString *crc32Str = [NSString stringWithFormat:@"%u", (int)crc32];
    
    NSString *encodedCrc32Str = crc32Str;
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"0" withString:@"q"];
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"1" withString:@"e"];
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"2" withString:@"t"];
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"3" withString:@"u"];
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"4" withString:@"o"];
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"5" withString:@"s"];
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"6" withString:@"f"];
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"7" withString:@"h"];
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"8" withString:@"n"];
    encodedCrc32Str = [encodedCrc32Str stringByReplacingOccurrencesOfString:@"9" withString:@"v"];
    
    //    NSLog(@"Sum: %@", encodedCrc32Str);

    return encodedCrc32Str;
}

- (NSString *)activationKeyForEncryptedMacAddressString:(NSString *)encryptedMacAddrString ip:(NSString *)ip {
    static NSString *__activationKey = nil;
    
    if (__activationKey == nil && [encryptedMacAddrString hasContent] && [ip hasContent]) {
        __activationKey = [self keyWithFormat:@"Hydrogene12%@atok%@13CapableBits"
                                          mac:encryptedMacAddrString
                                           ip:ip];
        [__activationKey retain];
    }
    
    return __activationKey;
}

- (NSString *)deactivationKeyForEncryptedMacAddressString:(NSString *)encryptedMacAddrString ip:(NSString *)ip{
    static NSString *__deactivationKey = nil;
    
    if (__deactivationKey == nil && [encryptedMacAddrString hasContent] && [ip hasContent]) {
        __deactivationKey = [self keyWithFormat:@"CherryLime04%@tape%@07CapableBits"
                                            mac:encryptedMacAddrString
                                             ip:ip];
        [__deactivationKey retain];
    }
    
    return __deactivationKey;
}

- (void)requestUpdatePermalink {
    @synchronized(self) {
        _retrievePermanentUrlIsInProgress = YES;
    }
    

    PBConnectionManager *connectionManager = self;
    NSString *permanentIdPrefix = [PBAppDelegate serviceName];
    permanentIdPrefix = [permanentIdPrefix componentsSeparatedByString:@" "][0];
    permanentIdPrefix = [permanentIdPrefix componentsSeparatedByString:@"'"][0];
    permanentIdPrefix = [permanentIdPrefix componentsSeparatedByString:@"`"][0];
    permanentIdPrefix = [[permanentIdPrefix uppercaseString] lowercaseString]; //“Straße” => “STRASSE” => “strasse”

    NSCharacterSet *okayCharset = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789"];
    if ([[permanentIdPrefix stringByTrimmingCharactersInSet:okayCharset] length] != 0) {
        permanentIdPrefix = @"user";
    }

    //make permanent id with only first 10 characters
    if (permanentIdPrefix.length > 10) {
        permanentIdPrefix = [permanentIdPrefix substringToIndex:10];
    }

    NSString *breed = @"oak"; //initially Plus paid app
#if PB_LITE
    BOOL isFullVersion = [[PBAppDelegate sharedDelegate] isFullVersion];
    
    PBPurchaseManager *purchaseManager = [PBPurchaseManager sharedManager];
    BOOL isAdminFullVersion = [purchaseManager isAdminFullVersionUnlocked];
    BOOL isInAppFullversion = [purchaseManager isFullVersionUnlocked];
    
    if (isInAppFullversion) {
        breed = @"beech"; //Plus upgraded via InApp purchase
    } else if (isAdminFullVersion) {
        breed = @"walnut"; //Plus granted by remote admin
    } else {
        breed = @"cork"; //Lite version with send limit
    }
#endif

    NSDictionary *localInterfaceInfo = PBGetLocalNetworkInterfaceInfo();
    NSString *ipAddStr = localInterfaceInfo[kPBIpAddress];
    NSString *deviceId = [self deviceIndentifier];

    NSString *urlString =
        [NSString stringWithFormat:@"%@/getpermalink.php?id=%@&ip=%@&breed=%@&perm_id_prefix=%@",
            PBConnectionManagerPermanentUrlPrefix,
            deviceId,
            ipAddStr,
            breed,
            permanentIdPrefix];

    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURLString:urlString];
    request.timeoutInterval = 20;
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        @synchronized(self) {
            _retrievePermanentUrlIsInProgress = NO;
        }

        if (response.error == nil && response.statusCode == 200) {
            NSError *error = nil;
            NSDictionary *info = [NSJSONSerialization JSONObjectWithData:response.responseData
                                                                 options:0
                                                                   error:&error];
            if (info) {
//                NSLog(@"Got response: %@", info);
                
#if PB_LITE
                NSString *key = info[@"key"];
       
                if (isFullVersion && key) {
                    NSString *validKey = [self deactivationKeyForEncryptedMacAddressString:deviceId
                                                                                        ip:ipAddStr];
                    if ([key isEqualToString:validKey]) {
                        NSLog(@"Got valid deactivate key!");
                        [[PBPurchaseManager sharedManager] deactivateAdminFullVersion];
                    }
                } else if (!isFullVersion && key) {
                    NSString *validKey = [self activationKeyForEncryptedMacAddressString:deviceId
                                                                                      ip:ipAddStr];
                    
                    if ([key isEqualToString:validKey]) {
                        NSLog(@"Got valid unlock key");
                        [[PBPurchaseManager sharedManager] unlockAdminFullVersion];
                    }
                }
#endif
                
                NSString *permanentId = info[@"permanent_id"];
                connectionManager.permanentId = permanentId;
                NSLog(@"Got permanent Id: %@", permanentId);
            } else {
                connectionManager.permanentId = nil;
                NSLog(@"Failed to parse permanent id. Error: %@", error);
                NSLog(@"Responce body: %@", response.responseString);
            }
            
        } else {
            connectionManager.permanentId = nil;
            NSLog(@"Failed to get permanent id. Error: %@", response.error);
        }
    }];
}

- (NSString *)permanentUrlString {
    if (_permanentId) {
        return [NSString stringWithFormat:@"%@/%@", PBConnectionManagerPermanentUrlPrefix, _permanentId];
    }
    
    return nil;
}

- (NSString *)localUrlString {
    NSString *localUrlString = nil;

    NSString *localIpString = PBGetLocalIP();
    if (localIpString) {
        localUrlString = [NSString stringWithFormat:@"http://%@:%ld", localIpString, (long)PBGetServerPort()];
    }
    
    return localUrlString;
}

- (BOOL)isRetrievePermanentUrlInProgress {
    @synchronized(self) {
        return _retrievePermanentUrlIsInProgress;
    }
}

- (NSString *)deviceIndentifier {
    NSString *identifier = @"";

    CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

    if (systemVersion < 7.0) {
        NSDictionary *localInterfaceInfo = PBGetLocalNetworkInterfaceInfo();
        NSString *macAddrStr = [localInterfaceInfo objectForKey:kPBMacAddress];
        identifier = [self encryptedMacAddressString:macAddrStr];
    }
    else {
        identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];

        // In rare cases identifier may be nil, for simplicity just ignore it
    }

    return identifier;
}


#pragma mark - Properties

@synthesize permanentId = _permanentId;

- (void)setPermanentId:(NSString *)permanentId {
    @synchronized(self) {
        [_permanentId autorelease];
        _permanentId = [permanentId retain];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
                postNotificationName:PBConnectionManagerPermanentUrlDidChangeNotification
                object:nil
                userInfo:nil];
        });
    }
}

- (NSString *)permanentId {
    @synchronized(self) {
        return _permanentId;
    }
}

@end
