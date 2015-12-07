//
//  PBAppDelegate.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBViewController.h"
#import "PBTransferSession.h"
#import "PBServiceBrowser.h"
#import "PBAdImageViewController.h"
#import "PBPermissionsRequestViewController.h"
#import "RDSystemInformation.h"
#import "PBFlickrUploadingEngine.h"
#import "PBGoogleDriveUploadingEngine.h"

extern NSString * const PBApplicationDidBecomeActiveNotification;
@class PBMongooseServer;

@interface PBAppDelegate : UIResponder<UIApplicationDelegate, AdImageViewControllerDelegate, PBPermissionsRequestViewControllerDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) PBViewController *viewController;
@property (strong, nonatomic) PBMongooseServer *httpServer;
@property (strong) PBTransferSession *transferSession;
@property (assign, nonatomic) BOOL isFullVersion;
@property (nonatomic, strong) PBFlickrUploadingEngine *flickrEngine;
@property (nonatomic, strong) PBGoogleDriveUploadingEngine *googleDriveEngine;

@property (nonatomic,strong) NSDictionary *sendToCloudAppleWatchData;


- (NSInteger)numberOfTimesApplicationBeenLaunched;
+ (PBAppDelegate *)sharedDelegate;
- (void)presentConnectViewControllerInNavigationController:(UINavigationController *)navigationController;
- (void)presentContactSupportEmailComposeViewControllerFromViewController:(UIViewController *)viewController;

//==== for subclassing only
- (void)actionSheetDidSelectSendToIosDevice:(id)userInfo;
- (void)actionSheetDidSelectSendToDesktopComputer:(id)userInfo;
+ (NSString *)backgroundTaskNotificationMessage;
//====

+ (id)rootViewController;
+ (void)setupAppearance;
+ (NSString *)serviceName;
- (void)endBackgroundTask;

+ (PBAdImageViewController *)adImageViewController;
- (void)presentAdImageViewController;
- (NSString *)supportInformation;
- (void)showGoogleAuthorizationController;

@end
