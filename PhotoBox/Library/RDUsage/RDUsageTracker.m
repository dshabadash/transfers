//
//  RDUsageTracker.m
//  ReaddleDocs2
//
//  Created by Andrian Budantsov on 04.05.12.
//  Copyright (c) 2012 Readdle. All rights reserved.
//

#import "RDUsageTracker.h"

// for stat syscall
#include <sys/stat.h>

// for MAC addr identifier
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
// for MAC addr identifier 

// for SHA1 hash
#import <CommonCrypto/CommonDigest.h>
// end 

static NSData   *RDUDataXOR(NSData *data);
static NSString *RDUMacIdentifier(void);
static NSString *RDUDeviceModelID();
static NSString *RDUUserStoreID();
static NSString *RDUGetUUIDString();
static int RDUIsDeviceNotGood();
static NSString *RDUBase64EncodedData(NSData *data);
static NSData *RDUSHA1DigestOfData(NSData *data);

static void MurmurHash3_x86_32 ( const void * key, int len, uint32_t seed, void * out);
static NSString *RDUApplicationBinaryHash();

static NSString *const RDUTrackerURLString = @"http://usage.readdle.com/";
static const NSTimeInterval RDUTrackerTransmitTimeResolution = 60;

@interface RDUJSONDictionaryStream : NSObject  {
    NSMutableString *jsonString;
    BOOL finilized;
}

- (NSString *)JSONString;
+ (NSString *)JSONStringEscape:(NSString *)string;
- (void)setObject:(NSObject *)object forKey:(NSString *)key;
@end



@interface RDUSimpleHTTP : NSObject<NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    NSMutableData   *responseData;
}
+ (RDUSimpleHTTP *)request;
@property(nonatomic, retain)    NSURL               *URL;
@property(nonatomic, retain)    NSData              *postBodyData; 
@property(nonatomic, retain)    NSError             *error;
@property(nonatomic, retain)    NSHTTPURLResponse   *response;
@property(nonatomic, readonly)  NSData              *responseData;
@property(nonatomic, readonly)  NSDictionary        *responseHeaders;
@property(nonatomic, assign)    NSObject            *target;
@property(nonatomic, assign)    SEL                 selector;
- (void)sendRequest;
@end



@interface RDUsageTargetAction : NSObject {
    id _target;
    SEL _action;
}

- (void)performWithArray:(NSArray *)array;
@end

@implementation RDUsageTargetAction

- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super init];
    if (self) {
        _target = target;
        _action = action;
    }
    return self;
}

- (NSUInteger)hash {
    return (NSUInteger)((void* )_target) ^ (NSUInteger)((void *)_action);
}

- (BOOL)isEqual:(RDUsageTargetAction *)anObject {
    return _target == anObject->_target && _action == anObject->_action;
}

- (void)performWithArray:(NSArray *)array {
    
    if ([array count] == 0)
        [_target performSelector:_action];
    else if ([array count] == 1)
        [_target performSelector:_action withObject:array[0]];
    else if ([array count] == 2)
        [_target performSelector:_action withObject:array[0] withObject:array[1]];
    
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ : %@", _target, NSStringFromSelector(_action)];
}

@end


#pragma mark -

@interface RDUsageTracker() {
    NSString        *installId;
    NSString        *launchId;
    NSData          *lastSendPushToken;
    BOOL            needsResendPushToken;
    NSTimeInterval  lastTransmit;
    
    NSTimeInterval  sessionStart;
    
    RDUShouldAskBlock shouldAskEmailBlock;
    RDUShouldAskBlock shouldAskTwitterBlock;
    
    NSMutableSet    *_actions;
}

- (NSString *)preparePayloadDetailed:(BOOL)detailed withDictionary:(NSDictionary *)dict;
@end


@implementation RDUsageTracker

@synthesize debugMode;
@synthesize appTag;
@synthesize needsAppHash;
@synthesize waitForPushToken;
@synthesize pushToken;

+ (RDUsageTracker *)sharedTracker {
    static RDUsageTracker *sharedTracker = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [RDUsageTracker new];
    });
    
    return sharedTracker;
}

- (id)init {
    self = [super init];
    if (self) {
        _actions = [NSMutableSet new];
    }
    return self;
}

- (void)addTarget:(id)target action:(SEL)action {
    RDUsageTargetAction *ta = [[RDUsageTargetAction alloc] initWithTarget:target action:action];
    [_actions addObject:ta];
    [ta release];
}

- (void)removeTarget:(id)target action:(SEL)action {
    RDUsageTargetAction *ta = [[RDUsageTargetAction alloc] initWithTarget:target action:action];
    [_actions removeObject:ta];
    [ta release];
}


- (void)appStartAfterDelay {
    
    if (needsAppHash) {
        // app hash takes 0.05 sec (longer on older devices)
        // lets do it in background 
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            NSString *jsonString = [self preparePayloadDetailed:YES withDictionary:nil];
            
            NSData *data = RDUDataXOR([jsonString dataUsingEncoding:NSUTF8StringEncoding]);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                lastTransmit = CFAbsoluteTimeGetCurrent();
                RDUSimpleHTTP *http = [RDUSimpleHTTP request];
                http.URL = [NSURL URLWithString:RDUTrackerURLString];
                http.postBodyData = data;
                http.target = self;
                [http sendRequest];
            });
            
        });
        
        return;
    }
    
    sessionStart = CFAbsoluteTimeGetCurrent();
    lastTransmit = CFAbsoluteTimeGetCurrent();
    RDUSimpleHTTP *http = [RDUSimpleHTTP request];
    http.URL = [NSURL URLWithString:RDUTrackerURLString];
    
    
    NSString *jsonString = [self preparePayloadDetailed:YES withDictionary:nil];
    http.postBodyData = RDUDataXOR([jsonString dataUsingEncoding:NSUTF8StringEncoding]);
    http.target = self;
    [http sendRequest];
}

- (void)appStart {
    
    if (waitForPushToken) 
        [self performSelector:@selector(appStartAfterDelay) withObject:nil afterDelay:10.0];
    else 
        [self appStartAfterDelay];
    
    sessionStart = CFAbsoluteTimeGetCurrent();
    
}

- (void)appEnterForeground {
    
    if (CFAbsoluteTimeGetCurrent() - lastTransmit < RDUTrackerTransmitTimeResolution)
        return;
    
    sessionStart = CFAbsoluteTimeGetCurrent();
    lastTransmit = CFAbsoluteTimeGetCurrent();
    
    [self sendEventWithType:@"fg" dictionary:nil];
}

- (void)appEnterBackground {
    
    NSTimeInterval sessionLength = CFAbsoluteTimeGetCurrent() - sessionStart;
    NSUInteger sessionLengthHalfMin = (NSUInteger)sessionLength / 30;

    
    [self sendEventWithType:@"bg" dictionary:@{@"session_len":@(sessionLengthHalfMin)}];
}


- (void)appShouldAskForEmail:(RDUShouldAskBlock)block {
    [shouldAskEmailBlock release];
    shouldAskEmailBlock = [block copy];
    
    
    RDUSimpleHTTP *http = [RDUSimpleHTTP request];
    http.URL = [NSURL URLWithString:[RDUTrackerURLString stringByAppendingString:@"subs"]];

    NSString *userStoreID = RDUUserStoreID();
    NSDictionary *dict = nil;
    if (userStoreID)
        dict = @{ @"user" : userStoreID};
    
    NSString *jsonString = [self preparePayloadDetailed:NO withDictionary:dict];    
    http.postBodyData = RDUDataXOR([jsonString dataUsingEncoding:NSUTF8StringEncoding]);
    http.target = self;
    [http sendRequest];
}
 

- (void)appSendEmail:(NSString *)email {
    if (email == nil)
        email = @"no";
    
    NSString *localeId = [[NSLocale currentLocale] localeIdentifier];
    
    if (localeId == nil)
        localeId = @"(nil)";
    
    [self sendEventWithType:@"mail"
                 dictionary:@{@"email" : email,
                              @"locale" : localeId}];
}


- (void)shouldAskForTwitter:(RDUShouldAskBlock)block {
    [shouldAskTwitterBlock release];
    shouldAskTwitterBlock = [block copy];
    
    RDUSimpleHTTP *http = [RDUSimpleHTTP request];
    http.URL = [NSURL URLWithString:[RDUTrackerURLString stringByAppendingString:@"twit"]];
    
    NSString *userStoreID = RDUUserStoreID();
    NSDictionary *dict = nil;
    if (userStoreID)
        dict = @{ @"user" : userStoreID};
    
    NSString *jsonString = [self preparePayloadDetailed:NO withDictionary:dict];
    http.postBodyData = RDUDataXOR([jsonString dataUsingEncoding:NSUTF8StringEncoding]);
    http.target = self;
    [http sendRequest];
}


- (void)appTwitterFollowDone:(NSString *)username {
    if (username == nil)
        username = @"no";
    
    [self sendEventWithType:@"twit" dictionary:@{@"twitter" : username}];
}


#pragma mark -


- (void)sendEventWithType:(NSString *)type dictionary:(NSDictionary *)dictionary {
    if (type == nil)
        return;
    
    NSMutableDictionary *eventDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
    eventDictionary[@"evnt"] = type;
    if(dictionary)
        [eventDictionary addEntriesFromDictionary:dictionary];
    
    
    RDUSimpleHTTP *http = [RDUSimpleHTTP request];
    http.URL = [NSURL URLWithString:RDUTrackerURLString];
    NSString *jsonString = [self preparePayloadDetailed:NO withDictionary:eventDictionary];
    http.postBodyData = RDUDataXOR([jsonString dataUsingEncoding:NSUTF8StringEncoding]);
    http.target = self;
    [http sendRequest];
}



- (void)httpDone:(RDUSimpleHTTP *)request {
    if (request.error) return;
    if (request.responseData == nil) return;
    
    NSDictionary *responseHeaders = [request.response allHeaderFields];
    [_actions makeObjectsPerformSelector:@selector(performWithArray:)
                              withObject:@[request.URL, responseHeaders]];
    
    
    NSString *resp = [[NSString alloc] initWithData:request.responseData 
                                           encoding:NSUTF8StringEncoding];
    
    if (shouldAskEmailBlock && [[request.URL absoluteString] rangeOfString:@"/subs"].location != NSNotFound) {

        BOOL show = [resp rangeOfString:@"show"].location != NSNotFound;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            shouldAskEmailBlock(show);
            [shouldAskEmailBlock release];
            shouldAskEmailBlock = nil;            
        });
        
        [resp release];
        return;
    }
    
    if (shouldAskTwitterBlock && [[request.URL absoluteString] rangeOfString:@"/twit"].location != NSNotFound) {
        BOOL show = [resp rangeOfString:@"show"].location != NSNotFound;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            shouldAskTwitterBlock(show);
            [shouldAskTwitterBlock release];
            shouldAskTwitterBlock = nil;
        });
        
        [resp release];
        return;
    }
    
    
    BOOL off = [resp hasPrefix:@"RDOFF:"];
    BOOL msg = [resp hasPrefix:@"RDMSG:"];
    
    if (msg || off) {
        NSString *str = [resp substringFromIndex:6];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:str
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
    if (off) 
        [UIApplication sharedApplication].keyWindow.alpha = 0.0;
    
    [resp release];

}


- (void)setPushToken:(NSData *)token {
    if (token == pushToken) 
        return;
    
    [pushToken release];
    pushToken = [token retain];

    if (lastSendPushToken == nil) 
        needsResendPushToken = YES;
    else {
        
        if ([lastSendPushToken isEqualToData:token])
            needsResendPushToken = NO;
        else
            needsResendPushToken = YES;
    }
    
    if (needsResendPushToken && launchId == nil) {
        [self appEnterForeground];
    }
    
}

+ (NSString *)RDUUserStoreID {
    return RDUUserStoreID();
}

+ (NSString *)RDUUserStoreIDHash {
    static NSString *userStoreHash = nil;
    
    if (userStoreHash)
        return userStoreHash;
    
    NSString *userStoreId = RDUUserStoreID();
    if (userStoreId == nil)
        return nil;
    
    userStoreId = [userStoreId stringByAppendingString:@"-READDLE"];
    
    NSData *outdata = [userStoreId dataUsingEncoding:NSUTF8StringEncoding];
    
    userStoreHash = [[NSString alloc] initWithFormat:@"RUD1-%@", RDUBase64EncodedData(RDUSHA1DigestOfData(outdata))];
    return userStoreHash;
}



+ (NSString *)RDUMacIdentifier {
    return RDUMacIdentifier();
}



#pragma mark - 

- (void)dealloc {
    self.appTag = nil;
    [lastSendPushToken release];
    [launchId release];
    [super dealloc];
}

- (NSString *)preparePayloadDetailed:(BOOL)detailed withDictionary:(NSDictionary *)dict {
    
    if (launchId == nil) 
        launchId = [RDUGetUUIDString() retain];
    
    if (installId == nil) {
        installId = [[[NSUserDefaults standardUserDefaults] objectForKey:@"_RDUIId"] retain];
        if (installId == nil) {
            installId = [RDUGetUUIDString() retain];
            [[NSUserDefaults standardUserDefaults] setObject:installId forKey:@"_RDUIId"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    RDUJSONDictionaryStream *payload = [RDUJSONDictionaryStream new];

    NSBundle *mainBundle = [NSBundle mainBundle];
    
    if (debugMode)
        [payload setObject:@1
                    forKey:@"dbg"];
    
    [payload setObject:[mainBundle bundleIdentifier]
                forKey:@"app.id"];

    [payload setObject:RDUMacIdentifier()
                forKey:@"rid"];

    [payload setObject:launchId
                forKey:@"launch"];
    
    if (appTag) 
        [payload setObject:appTag
                    forKey:@"tag"];
    
    if (pushToken && needsResendPushToken) {
        
        [payload setObject:RDUBase64EncodedData(pushToken)
                    forKey:@"push"];
        
        if (lastSendPushToken != pushToken) {
            [lastSendPushToken release];
            lastSendPushToken = [pushToken retain];
        }
        
        needsResendPushToken = NO;
    }

    [payload setObject:RDUUserStoreID()
                forKey:@"user"];

    
    for(NSString *key in dict) {
        [payload setObject:[dict objectForKey:key] forKey:key];
    }
        
    
    if (detailed) {
        [payload setObject:[[NSLocale currentLocale] localeIdentifier]
                    forKey:@"locale"];
        
        [payload setObject:@((int)[[NSDate date] timeIntervalSince1970])
                    forKey:@"time"];
        
        [payload setObject:RDUDeviceModelID() 
                    forKey:@"device.model"];
        
        [payload setObject:[NSNumber numberWithInt:[UIDevice currentDevice].userInterfaceIdiom]
                    forKey:@"device.idiom"];
        
        NSTimeZone *tz = [NSTimeZone localTimeZone];
        [payload setObject:@([tz secondsFromGMT])
                    forKey:@"tz.offset"];
        
        [payload setObject:[tz name]
                    forKey:@"tz.name"];
        
        [payload setObject:[UIDevice currentDevice].systemVersion
                    forKey:@"os.ver"];
        
        [payload setObject:@(RDUIsDeviceNotGood())
                    forKey:@"os.cm"];
        
        if (needsAppHash) {
            [payload setObject:RDUApplicationBinaryHash()
                        forKey:@"app.hash"];
        }
        
        [payload setObject:[mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]
                    forKey:@"app.ver"];
        
        [payload setObject:[mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
                    forKey:@"app.vershort"];
    }
    
    NSString *payloadJSON = [payload JSONString];
    [payload release];
    
    return payloadJSON;
}




@end


#pragma mark -

@implementation RDUJSONDictionaryStream

- (void)dealloc {
    [jsonString release];
    [super dealloc];
}

- (NSString *)JSONString {
    finilized = YES;
    [jsonString appendString:@"}"];    
    return [NSString stringWithString:jsonString];
}

+ (NSString *)JSONStringEscape:(NSString *)string {
    string = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return string;
}

- (void)setObject:(NSObject *)object forKey:(NSString *)key {
    if (key == nil) {
        NSLog(@"%s key is nil", __PRETTY_FUNCTION__);
        return;
    }
    
    if (finilized) {
        NSLog(@"%s : finalized, unable to add object", __PRETTY_FUNCTION__);
        return;
    }
    
    if (jsonString == nil) {
        jsonString = [[NSMutableString alloc] initWithCapacity:4096];
        [jsonString appendString:@"{"];
    }
    else {
        [jsonString appendString:@","];
    }
    
    key = [[self class] JSONStringEscape:key];
    
    if (object == nil) 
        [jsonString appendFormat:@"\"%@\":null", key];
    else if ([object isKindOfClass:[NSNumber class]])
        [jsonString appendFormat:@"\"%@\":%@", key, [(NSNumber *)object stringValue]];
    else {
        
        NSString *stringValue;
        
        if ([object isKindOfClass:[NSString class]] == NO)
            stringValue = [object description];
        else 
            stringValue = (NSString *)object;
        
        stringValue = [[self class] JSONStringEscape:stringValue];
        
        [jsonString appendFormat:@"\"%@\":\"%@\"", key, stringValue];
    }
}

@end


static NSString *RDUApplicationBinaryHash() {
    NSString *appBinaryPath = [NSBundle mainBundle].executablePath;
    
    NSData *appContent = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:appBinaryPath] options:NSDataReadingMappedIfSafe error:nil];
    const char *bytes = (const char *)[appContent bytes];
    NSUInteger len = [appContent length];
    NSUInteger hashLen = 512*1024;
    
    if (hashLen > len)
        hashLen = len;
    else {
        bytes = bytes + len - 1 - hashLen;
    }

    uint32_t two32ints[2];
    two32ints[0] = len;
    MurmurHash3_x86_32(bytes, hashLen, 0xB0F57EE3, &two32ints[1]);
        
    [appContent release];
    
    NSData *resultData = [[NSData alloc] initWithBytes:two32ints length:sizeof(two32ints)];
    NSString *baseResult = RDUBase64EncodedData(resultData);
    [resultData release];
    
    return baseResult;
}

static NSString *RDUGetUUIDString() {
	CFUUIDRef uuid = CFUUIDCreate(nil);
    CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuid);
    
    NSString *str = RDUBase64EncodedData([NSData dataWithBytesNoCopy:&uuidBytes 
                                                                  length:sizeof(uuidBytes) 
                                                            freeWhenDone:NO]);
	CFRelease(uuid);
	return str;
}

static int RDUIsDeviceNotGood() {
    char notgoodapp[256];
    snprintf(notgoodapp, 255, "/Ap%sons/%s%cdi%sapp", "plicati", "C", 'y', "a."); // /Applications/Cydia.app
    
    return (stat(notgoodapp, NULL) != -1);
}

static NSString *RDUUserStoreID() {
    static NSString *cachedUserStoreID = nil;
    
    if (cachedUserStoreID) 
        return cachedUserStoreID;
    
    NSString *bundlePath = [NSBundle mainBundle].bundlePath;

    NSString *sci = [NSString stringWithFormat:@"%@_I%s", @"SC", "nfo"]; // SC_Info, scrambled 
    NSString *inf_file = [NSString stringWithFormat:@"%@.s%s", [[NSBundle mainBundle].executablePath lastPathComponent], "inf"]; // executableName.sinf
    
    NSString *fullPath = [bundlePath stringByAppendingFormat:@"/%@/%@", sci, inf_file];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath] == NO) 
        return nil;
    
    NSData *data = [NSData dataWithContentsOfFile:fullPath];
    
    if (data == nil)
        return nil;
    
    unsigned char *bytes = (unsigned char *)[data bytes];
    NSUInteger len = [data length];
    unsigned char *user_offset = NULL;
    for(NSUInteger i=3; i<len; i++) {
        if (bytes[i] == 'r' && bytes[i-1] == 'e' && bytes[i-2] == 's' && bytes[i-3] == 'u' && len - i - 1 > 4) {
            user_offset = &bytes[i+1];
            break;
        }
    }
    
    if (user_offset == NULL)
        return NULL;
    
    unsigned int userid = user_offset[0] << 24 | user_offset[1] << 16 | user_offset[2] << 8 | user_offset[3];
    
    cachedUserStoreID  = [NSString stringWithFormat:@"%u", userid];
    [cachedUserStoreID retain];
    
    return cachedUserStoreID;
}


static NSString *RDUDeviceModelID() {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    if (size <= 0)
        return NULL;
    
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *modelName = @(machine);
    free(machine);
    
    return modelName;
}


static NSData *RDUSHA1DigestOfData(NSData *data) {
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([data bytes], [data length], result);
    return [NSData dataWithBytes:result length:CC_SHA1_DIGEST_LENGTH];
}


static NSString *RDUBase64EncodedData(NSData *data) {
    static const char cb64[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    const char *dataptr = [data bytes];
    const NSUInteger input_length = [data length];
    NSMutableString *response = [NSMutableString stringWithCapacity:input_length*2];
    
    for(NSUInteger i=0; i<input_length;) {
        uint32_t octet_a = i < input_length ? dataptr[i++] : 0;
        uint32_t octet_b = i < input_length ? dataptr[i++] : 0;
        uint32_t octet_c = i < input_length ? dataptr[i++] : 0;
        uint32_t triple = (octet_a << 0x10) + (octet_b << 0x08) + octet_c;
        [response appendFormat:@"%c", cb64[(triple >> 3 * 6) & 0x3F]];
        [response appendFormat:@"%c", cb64[(triple >> 2 * 6) & 0x3F]];
        [response appendFormat:@"%c", cb64[(triple >> 1 * 6) & 0x3F]];
        [response appendFormat:@"%c", cb64[(triple >> 0 * 6) & 0x3F]];        
    }
    
    static const int mod_table[] = {0, 2, 1};
    for (int i = 0; i < mod_table[input_length % 3]; i++)
        [response appendString:@"="];
    
    return response;
}

static NSString *RDUMacIdentifier(void) {
    static NSString *macIdentifier = nil;
    
    if (macIdentifier) 
        return macIdentifier;
    
    // code from https://github.com/gekitz/UIDevice-with-UniqueIdentifier-for-iOS-5/blob/master/Classes/UIDevice+IdentifierAddition.m
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"READDLE-%02X:%02X:%02X:%02X:%02X:%02X", 
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    NSData *outdata = [outstring dataUsingEncoding:NSUTF8StringEncoding];
    
    macIdentifier = [[NSString alloc] initWithFormat:@"RID1-%@", RDUBase64EncodedData(RDUSHA1DigestOfData(outdata))];
    return macIdentifier;
}

static NSData *RDUDataXOR(NSData *data) {
    static char keyData[61];
    
    if (keyData[0] == 0) {
        const char *p1 = "5zNLN";
        const char *p2 = "tBIh1";
        const char *p3 = "Bm7xs";
        const char *p4 = "icsnD";
        
        snprintf(keyData, 61, "%s%s%s%s%s%s%s%s%s%s%s%s", 
                 p1, p2, p3, p4, p2, p3, p1, p3, p2, p4, p1, p2);
    }
    
    int keyIndex = 0;
    const int keyLength = 60;

    char *dataPtr = (char *) [data bytes];
    int dataLength = [data length];
    
    char *result = (char *)malloc(dataLength);

    for (int i = 0; i < dataLength; i++) 
    {
        result[i] = dataPtr[i] ^ keyData[keyIndex % keyLength];
        keyIndex++;
    }
    
    return [NSData dataWithBytesNoCopy:result length:dataLength freeWhenDone:YES];
}


@implementation RDUSimpleHTTP 
@synthesize URL=_URL;
@synthesize postBodyData=_postBodyData;
@synthesize error=_error;
@synthesize response=_response;
@synthesize target;
@synthesize selector;

- (id)init
{
    self = [super init];
    if (self) {
        selector = @selector(httpDone:);
    }
    return self;
}

+ (RDUSimpleHTTP *)request {
    return [[self new] autorelease];
}

- (NSData *)responseData {
    return responseData;
}

- (void)dealloc {
    self.URL = nil;
    self.postBodyData = nil;
    self.error = nil;
    self.response = nil;
    [responseData release];
    [super dealloc];
}

- (void)sendRequest {
    if (_URL == nil)
        return;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_URL];
    [request setCachePolicy:NSURLCacheStorageNotAllowed]; 
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"R" forHTTPHeaderField:@"User-Agent"];
    [request setValue:nil forHTTPHeaderField:@"Accept-Language"];
    [request setValue:nil forHTTPHeaderField:@"Accept-Encoding"];
    [request setTimeoutInterval:15.0];
    
    if (_postBodyData) {
        [request setHTTPBody:_postBodyData];    
        [request setValue:[NSString stringWithFormat:@"%u", [_postBodyData length]] forHTTPHeaderField:@"Content-Length"];
    }
    
    [NSURLConnection connectionWithRequest:request delegate:self];
    [self retain];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.error = error;
    if ([target respondsToSelector:selector])
        [target performSelector:selector withObject:self];
    [connection cancel];
    [self release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = (NSHTTPURLResponse *)response;
    if ([_response expectedContentLength] != NSURLResponseUnknownLength)  {
        [responseData release];
        responseData = [[NSMutableData alloc] initWithCapacity:[_response expectedContentLength]];
    }
    else
        responseData = [[NSMutableData alloc] initWithCapacity:128];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([target respondsToSelector:selector])
        [target performSelector:selector withObject:self];
    
    [connection cancel];
    [self release];
}

@end




// Hash

#define FORCE_INLINE __attribute__((always_inline))
FORCE_INLINE uint32_t getblock ( const uint32_t * p, int i );
FORCE_INLINE uint32_t rotl32 ( uint32_t x, int8_t r );
FORCE_INLINE uint32_t fmix ( uint32_t h );

FORCE_INLINE uint32_t getblock ( const uint32_t * p, int i )
{
    return p[i];
}

FORCE_INLINE uint32_t rotl32 ( uint32_t x, int8_t r )
{
    return (x << r) | (x >> (32 - r));
}

#define ROTL32(x,y)     rotl32(x,y)

FORCE_INLINE uint32_t fmix ( uint32_t h )
{
    h ^= h >> 16;
    h *= 0x85ebca6b;
    h ^= h >> 13;
    h *= 0xc2b2ae35;
    h ^= h >> 16;
    
    return h;
}

static void MurmurHash3_x86_32 ( const void * key, int len, uint32_t seed, void * out)
{
    const uint8_t * data = (const uint8_t*)key;
    const int nblocks = len / 4;
    
    uint32_t h1 = seed;
    
    uint32_t c1 = 0xcc9e2d51;
    uint32_t c2 = 0x1b873593;
    
    //----------
    // body
    
    const uint32_t * blocks = (const uint32_t *)(data + nblocks*4);
    
    for(int i = -nblocks; i; i++)
    {
        uint32_t k1 = getblock(blocks,i);
        
        k1 *= c1;
        k1 = ROTL32(k1,15);
        k1 *= c2;
        
        h1 ^= k1;
        h1 = ROTL32(h1,13); 
        h1 = h1*5+0xe6546b64;
    }
    
    //----------
    // tail
    
    const uint8_t * tail = (const uint8_t*)(data + nblocks*4);
    
    uint32_t k1 = 0;
    
    switch(len & 3)
    {
        case 3: k1 ^= tail[2] << 16;
        case 2: k1 ^= tail[1] << 8;
        case 1: k1 ^= tail[0];
            k1 *= c1; k1 = ROTL32(k1,15); k1 *= c2; h1 ^= k1;
    };
    
    //----------
    // finalization
    
    h1 ^= len;
    
    h1 = fmix(h1);
    
    *(uint32_t*)out = h1;
} 

