//
//  PBUtils.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 21/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBUtils.h"

// for ethernetIP
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#import "PBAppDelegate.h"
#import "PBMongooseServer.h"

//for mac
#import "IPAddress.h"


//for dumpstacktrace
#include <execinfo.h>

BOOL PBDeviceIs4InchPhone() {
    static BOOL _deviceIs4InchPhone;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _deviceIs4InchPhone = NO;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            if ([[UIScreen mainScreen] bounds].size.height == 568) {
                _deviceIs4InchPhone = YES;
            }
        }
    });
    
    return _deviceIs4InchPhone;
}

NSString * PBDumpStackTrace() {
    
   	void *backtraceFrames[128];
   	int frameCount = backtrace(&backtraceFrames[0], 128);
   	char **frameStrings = backtrace_symbols(&backtraceFrames[0], frameCount);
   	NSMutableString *str = [[NSMutableString new] autorelease];
   	if(frameStrings != NULL) {
   		int x = 0;
   		for(x = 0; x < frameCount; x++) {
   			if(frameStrings[x] == NULL)
   				break;
			
   			[str appendFormat:@"%s\n", frameStrings[x]];
   		}
   		free(frameStrings);
   	}
    
    return str;
}


#pragma mark - System Information

NSString* PBGetAppVersion()
{
    static NSString *appVersion = nil;
    if (appVersion == nil) {
        appVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] copy];
    }
    return appVersion;
}

NSURL *PBAppstoreAppUrl() {
    NSString *appUrlString = [NSString stringWithFormat:PB_APPSTORE_URLSTRING_FORMAT, PB_APPSTORE_ID];
    NSURL *appUrl = [NSURL URLWithString:appUrlString];
    return appUrl;
}

NSString *PBGetSystemMajorMinorVersionString() {
    static NSString * sysMMVersion = nil;
    
    if (sysMMVersion == nil) {
        NSString *version = [[UIDevice currentDevice] systemVersion];
        NSArray *versionParts = [version componentsSeparatedByString:@"."];
        if (versionParts.count == 0) {
            sysMMVersion = @"0.0";
        } else {
            NSString *majorVersion = versionParts[0];
            NSString *minorVersion;
            if (versionParts.count > 1) {
                minorVersion = versionParts[1];
            } else {
                minorVersion = @"0";
            }
            sysMMVersion = [[NSString stringWithFormat:@"%@.%@", majorVersion, minorVersion] retain];
        }
    }
    
    return sysMMVersion;
}

float PBGetSystemVersion() {
    static float version = 0.0;
    
    if (version == 0.0) {
        version = [PBGetSystemMajorMinorVersionString() floatValue];
    }
    
    return version;
}

#pragma mark - Network Interfaces

NSString *PBGetLocalIP() {
    NSDictionary *interfaceInfo = PBGetLocalNetworkInterfaceInfo();

    return interfaceInfo[kPBIpAddress];
}

NSInteger PBGetServerPort() {
    PBAppDelegate *appDelegate = (PBAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSInteger port = appDelegate.httpServer.startedOnPort;
    if (port <= 0) {
        return 8080;
    }
    
    return port;
}

NSString *PBGetLocalMac() {
    NSDictionary *interfaceInfo = PBGetLocalNetworkInterfaceInfo();
    return interfaceInfo[kPBMacAddress];
}

NSDictionary *PBGetLocalNetworkInterfaceInfo() {
    NSDictionary *localInterfaceInfo = nil;
    
    NSArray *interfaces = PBGetNetworkInterfacesInfo();
    for (NSDictionary *d in interfaces) {
        if ([d[kPBName] hasPrefix:@"en0"]) {
            localInterfaceInfo = d;
            break;
        }

        if ([d[kPBName] hasPrefix:@"en1"]) {
            localInterfaceInfo = d;
        }
    }
    
    return localInterfaceInfo;
}

NSArray *PBGetNetworkInterfacesInfo() {
    InitAddresses();
    GetIPAddresses();
    GetHWAddresses();
    
    NSMutableArray *interfaces = [NSMutableArray array];
    
    int i;
    for (i=0; i<MAXADDRS; ++i)
    {
        static unsigned long localHost = 0x7F000001;        // 127.0.0.1
        unsigned long theAddr;
        
        theAddr = ip_addrs[i];
        
        if (theAddr == 0) continue;
        if (theAddr == localHost) continue;
        if (if_names[i] == 0) continue;
        
        NSString *ifName = [NSString stringWithUTF8String:if_names[i]];
        NSString *ifMac = [NSString stringWithUTF8String:hw_addrs[i]];
        NSString *ifIp = [NSString stringWithUTF8String:ip_names[i]];
        
        NSDictionary *ifInfo = @{ kPBName:ifName, kPBIpAddress:ifIp, kPBMacAddress:ifMac};
        [interfaces addObject:ifInfo];
        
       // NSLog(@"Name: %s MAC: %s IP: %s\n", if_names[i], hw_addrs[i], ip_names[i]);
    }
    
    return [NSArray arrayWithArray:interfaces];
}

#pragma mark - Dir

NSString *PBApplicationDocumentsDirectory() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

NSString *PBApplicationDocumentsDirectoryAdd(NSString *pathComponentToAdd) {
    return [PBApplicationDocumentsDirectory() stringByAppendingPathComponent:pathComponentToAdd];
}

NSString *PBApplicationLibraryDirectory() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

NSString *PBApplicationLibraryDirectoryAdd(NSString *pathComponentToAdd) {
    return [PBApplicationLibraryDirectory() stringByAppendingPathComponent:pathComponentToAdd];
}

#pragma mark - Temp Dir

void PBCleanTemporaryDirectory() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDir = PBTemporaryDirectory();
    
    [fileManager removeItemAtPath:tmpDir error:nil];
    [fileManager createDirectoryAtPath:tmpDir
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
}

NSString *PBTemporaryDirectory() {
    static NSString *tmpDir = nil;
    if (tmpDir == nil) {
        tmpDir = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"files"] retain];
    }
    return tmpDir;
}

NSString *PBUUIDString() {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString *tempUUID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    
    NSString *result = [NSString stringWithString:tempUUID];
    
    [tempUUID release];
    CFRelease(theUUID);
    
    return result;
}

#pragma mark - Geometry

CGPoint PBCenter(CGPoint center) {
    NSInteger x = center.x;
    NSInteger y = center.y;
    
    x += 0 - (x % 2);
    y += 0 - (y % 2);
    
    center.x = x;
    center.y = y;
    return center;
}

#pragma mark - Debugging

void _PBTimeStamp(const char *prettyFunction, NSString *message) {
    NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
    
    static NSTimeInterval timeStamp = 0;
    if (timeStamp == 0) {
        timeStamp = now;
    }
    
    NSTimeInterval intervalSinceLastStamp = now - timeStamp;
    NSLog(@"TIME STAMP: %f since last stamp. Message: %@", intervalSinceLastStamp, message);
    
    timeStamp = now;
}

