//
//  RDSystemInformation.m
//  ReaddleLib
//
//  Created by Sergey Falcon on 5/16/13.
//  Copyright (c) 2013 Readdle Inc. All rights reserved.
//

#import "RDSystemInformation.h"
#import <sys/sysctl.h>

// for ethernetIP
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>

BOOL RDDeviceIs(RDDeviceType queryType) {
	static RDDeviceType deviceType = RD_NONE;
	if (deviceType == RD_NONE) {
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			if ([UIScreen mainScreen].bounds.size.height == 568)
                deviceType = RD_IPHONE_TALL;
            else
                deviceType = RD_IPHONE;
        }
		else
			deviceType = RD_IPAD;
		
	}
	if (queryType == RD_IPHONE)
        return deviceType == RD_IPHONE || deviceType == RD_IPHONE_TALL;
    
	return (queryType == deviceType);
}

float RDGetSystemVersion() {
	static float iphoneOsVersion = -1;
	
	if (iphoneOsVersion == -1) {
		NSString *version = [[UIDevice currentDevice] systemVersion];
		iphoneOsVersion = [version floatValue];
	}
	
	return iphoneOsVersion;
}

float RDScreenScaleFactor() {
	static float screenScaleFactor = 0.0;
	
	if (screenScaleFactor == 0.0) {
		SEL scaleSelector = @selector(scale);
		UIScreen *screen = [UIScreen mainScreen];
		
		if ([screen respondsToSelector:scaleSelector]) {
			
			NSMethodSignature *sig = nil;
			sig = [UIScreen instanceMethodSignatureForSelector:scaleSelector];
			NSInvocation *myInvocation = nil;
			myInvocation = [NSInvocation invocationWithMethodSignature:sig];
			[myInvocation setTarget:screen];
			[myInvocation setSelector:scaleSelector];
			[myInvocation invoke];
			[myInvocation getReturnValue:&screenScaleFactor];
			
		}
		else
			screenScaleFactor = 1.0;
	}
	
	return screenScaleFactor;
}

NSString *RDDeviceModelID() {
    static NSString *_modelName = nil;
    
    if (_modelName == nil) {
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        _modelName = [NSString stringWithUTF8String:machine];
        [_modelName retain];
        free(machine);
    }
    
    return _modelName;
}

NSString *RDDeviceModelSupportLogName() {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    
    NSString * userFriendlyModel = platform;
    
    //iPhones
    if([platform isEqualToString:@"iPhone1,1"])
        userFriendlyModel = @"iPhone Orginal";
    else if([platform isEqualToString:@"iPhone1,2"])
        userFriendlyModel = @"iPhone 3G";
    else if([platform isEqualToString:@"iPhone2,1"])
        userFriendlyModel = @"iPhone 3GS";
    else if ([platform isEqualToString:@"iPhone3,1"])
        userFriendlyModel = @"iPhone 4";
    else if ([platform isEqualToString:@"iPhone4,1"])
        userFriendlyModel = @"iPhone 4S";
    else if ([platform isEqualToString:@"iPhone5,1"])
        userFriendlyModel = @"iPhone 5";
    else if ([platform isEqualToString:@"iPhone5,2"])
        userFriendlyModel = @"iPhone 5";
    
    //iPod touches are ommited
    
    //iPad1
    else if([platform isEqualToString:@"iPad1,1"])
        userFriendlyModel = @"iPad Orginal";
    
    //iPad2
    else if([platform isEqualToString:@"iPad2,1"])
        userFriendlyModel = @"iPad2 Wi-Fi";
    else if([platform isEqualToString:@"iPad2,2"])
        userFriendlyModel = @"iPad2 3G";
    else if([platform isEqualToString:@"iPad2,3"])
        userFriendlyModel = @"iPad2 CDMA";
    else if([platform isEqualToString:@"iPad2,4"])
        userFriendlyModel = @"iPad2 Wi-Fi";//New
    
    //iPad Mini
    else if([platform isEqualToString:@"iPad2,5"])
        userFriendlyModel = @"iPad Mini Wi-Fi";
    else if([platform isEqualToString:@"iPad2,6"])
        userFriendlyModel = @"iPad Mini 3G";
    else if([platform isEqualToString:@"iPad2,7"])
        userFriendlyModel = @"iPad Mini CDMA";
    
    //iPad3
    else if([platform isEqualToString:@"iPad3,1"])
        userFriendlyModel = @"iPad3 Wi-Fi";
    else if([platform isEqualToString:@"iPad3,2"])//For iPad3 CDMA/3G is inverted
        userFriendlyModel = @"iPad3 CDMA";
    else if([platform isEqualToString:@"iPad3,3"])
        userFriendlyModel = @"iPad3 3G";
    
    //iPad4
    else if([platform isEqualToString:@"iPad3,4"])
        userFriendlyModel = @"iPad4 Wi-Fi";
    else if([platform isEqualToString:@"iPad3,5"])
        userFriendlyModel = @"iPad4 3G";
    else if([platform isEqualToString:@"iPad3,6"])
        userFriendlyModel = @"iPad4 CDMA";
    
    else
        userFriendlyModel = platform;
    
    return userFriendlyModel;
}

NSString *RDUUIDString(void) {
	CFUUIDRef uuid = CFUUIDCreate(nil);
	NSString *str = (NSString *)CFUUIDCreateString(nil, uuid);
	CFRelease(uuid);
	[str autorelease];
	return str;
}

NSString *ethernetIP() {
	NSString *iPhoneIPAddress = nil;
	
	BOOL success;
	struct ifaddrs *addrs;
	const struct ifaddrs *cursor;
	
	success = getifaddrs(&addrs) == 0;
	if (success) {
		cursor = addrs;
		while (cursor != NULL) {
			if (cursor->ifa_addr->sa_family == AF_INET) {
				NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
				NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
				
				if ([name hasPrefix:@"en0"]) {
					[iPhoneIPAddress release];
					iPhoneIPAddress = [addr copy];
					break;
				}
				
				if ([name hasPrefix:@"en1"]) {
					[iPhoneIPAddress release];
					iPhoneIPAddress = [addr copy];
				}
			}
			cursor = cursor->ifa_next;
		}
		freeifaddrs(addrs);
	}
	
	return [iPhoneIPAddress autorelease];
}
