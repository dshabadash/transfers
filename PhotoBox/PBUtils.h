//
//  PBUtils.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 21/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>

BOOL PBDeviceIs4InchPhone();
NSString * PBDumpStackTrace();


#pragma mark - System Information

NSString* PBGetAppVersion();
NSURL *PBAppstoreAppUrl();

float PBGetSystemVersion();
NSString *PBGetSystemMajorMinorVersionString();


#pragma mark - Network Interfaces

NSArray *PBGetNetworkInterfacesInfo();
NSDictionary *PBGetLocalNetworkInterfaceInfo();

NSString *PBGetLocalIP();
NSInteger PBGetServerPort();
NSString *PBGetLocalMac();

NSString *PBApplicationDocumentsDirectory();
NSString *PBApplicationDocumentsDirectoryAdd(NSString *pathComponentToAdd);

NSString *PBApplicationLibraryDirectory();
NSString *PBApplicationLibraryDirectoryAdd(NSString *pathComponentToAdd);

void PBCleanTemporaryDirectory();
NSString *PBTemporaryDirectory();

NSString *PBUUIDString();

#pragma mark - Geometry

CGPoint PBCenter(CGPoint center);

#pragma mark - Debugging

#if DEBUG
#define PBTimeStamp(x) _PBTimeStamp(__PRETTY_FUNCTION__, x);
#else
#define PBTimeStamp(x)
#endif

void _PBTimeStamp(const char *prettyFunction, NSString *message);
