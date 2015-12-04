//
//  LSAppUpdateManager.h
//  MyApp
//
//  Created by ameleshko on 12/26/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^LSAppUpdateManagerCompletionBlock)(void);

extern NSString * const LSAppUpdateManagerDidFinishCheckForUpdateNotification;


@protocol LSAppUpdateRequest <NSObject>

- (void)cancel;

@end


@protocol LSAppUpdateManager <NSObject>

- (instancetype)initWithAppID:(NSString *)appID;


- (NSString *)appID;

- (NSString *)currentAppVersion;

- (NSString *)lastAppVersion;

- (void)saveLastStartedAppVersion;

- (NSString *)lastStartedAppVersion;


- (BOOL)shouldShowUpdateAvailableUserPromt;

- (BOOL)shouldShowWhatsNewUserPromt;

- (BOOL)isUpdateRequired;



- (id<LSAppUpdateRequest>)checkForUpdateWithCompletion:(LSAppUpdateManagerCompletionBlock)completion;

- (void)showUpdateAvailableUserPromtWithCompletion:(LSAppUpdateManagerCompletionBlock)completion;

- (void)updateApplication;

- (void)showWhatsNewUserPromtWithCompletion:(LSAppUpdateManagerCompletionBlock)completion;

@end


@interface LSAppUpdateManager : NSObject

+ (void)setSharedManager:(id<LSAppUpdateManager>)manager;

+ (id<LSAppUpdateManager>)sharedManager;

@end



@interface LSItunesAppUpdateManager : NSObject <LSAppUpdateManager>

@end

