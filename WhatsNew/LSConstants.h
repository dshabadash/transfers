//
//  LSConstants.h
//  MyApp
//
//  Created by Artem Meleshko on 12/25/13.
//  Copyright (c) 2013 My Company. All rights reserved.
//

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define BUNDLE_VERSION                              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]

#define BUNDLE_VERSION_EQUAL_TO(v)                  ([BUNDLE_VERSION compare:v options:NSNumericSearch] == NSOrderedSame)
#define BUNDLE_VERSION_GREATER_THAN(v)              ([BUNDLE_VERSION compare:v options:NSNumericSearch] == NSOrderedDescending)
#define BUNDLE_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([BUNDLE_VERSION compare:v options:NSNumericSearch] != NSOrderedAscending)
#define BUNDLE_VERSION_LESS_THAN(v)                 ([BUNDLE_VERSION compare:v options:NSNumericSearch] == NSOrderedAscending)
#define BUNDLE_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([BUNDLE_VERSION compare:v options:NSNumericSearch] != NSOrderedDescending)


#define DEVICE_IS_IPHONE() (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
#define DEVICE_IS_IPAD() (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
#define DEVICE_IS_RETINA() ([[UIScreen mainScreen] scale] >= 2.0)


#define SCREEN_WIDTH() ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT() ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH() (MAX(SCREEN_WIDTH(), SCREEN_HEIGHT()))
#define SCREEN_MIN_LENGTH() (MIN(SCREEN_WIDTH(), SCREEN_HEIGHT()))


#define DEVICE_IS_IPHONE_4_OR_LESS() (DEVICE_IS_IPHONE() && SCREEN_MAX_LENGTH() < 568.0)
#define DEVICE_IS_IPHONE_5() (DEVICE_IS_IPHONE() && SCREEN_MAX_LENGTH() == 568.0)
#define DEVICE_IS_IPHONE_6() (DEVICE_IS_IPHONE() && SCREEN_MAX_LENGTH() == 667.0)
#define DEVICE_IS_IPHONE_6_PLUS() (DEVICE_IS_IPHONE() && SCREEN_MAX_LENGTH() == 736.0)


#define INTERFACE_IS_PORTRAIT() UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])
#define INTERFACE_IS_LANDSCAPE() UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])

#define EMAIL_FORMAT_IS_CORRECT(email) \
(email!=nil && [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"(?:[A-Za-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[A-Za-z0-9!#$%\\&'*+/=?\\^_`{|}" \
@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" \
@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[A-Za-z0-9](?:[a-" \
@"z0-9-]*[A-Za-z0-9])?\\.)+[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?|\\[(?:(?:25[0-5" \
@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" \
@"9][0-9]?|[A-Za-z0-9-]*[A-Za-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" \
@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"] evaluateWithObject:email])

