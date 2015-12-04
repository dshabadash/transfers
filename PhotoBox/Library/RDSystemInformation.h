//
//  RDSystemInformation.h
//  ReaddleLib
//
//  Created by Sergey Falcon on 5/16/13.
//  Copyright (c) 2013 Readdle Inc. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, RDDeviceType) {
    RD_IPHONE,
    RD_IPAD,
    RD_IPHONE_TALL,
    RD_NONE
};

BOOL RDDeviceIs(RDDeviceType queryType);
float RDScreenScaleFactor();
float RDGetSystemVersion();

extern NSString *RDDeviceModelSupportLogName();
NSString *RDDeviceModelID();    
NSString *RDUUIDString();

NSString *RDGetSystemIPAddress();

