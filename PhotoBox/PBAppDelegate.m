//
//  PBAppDelegate.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "PBAppDelegate.h"

#import "CBAnalyticsManager.h"
#import "NSString+CB.h"

#import "PBAssetsGroupListViewController.h"
#import "PBAssetListViewControllerIpad.h"
#import "PBMongooseServer.h"
#import "PBServlets.h"

#import "PBPhotoBar.h"
#import "PBToolbar.h"
#import "PBNavigationController.h"
#import "PBRootViewController.h"
#import "PBHomeScreenTopView.h"
#import "PBHomeScreenBottomView.h"

#import "PBReceiveViewController.h"

#import "PBConnectionManager.h"
#import "PBAssetManager.h"
#import "PBConnectViewController.h"
#import "PBNearbyDeviceListViewController.h"
#import "PBCommonUploadToViewController.h"
#import "PBDropboxUploaingEngine.h"

#import "PBAssetUploader.h"

#import "ZipFile.h"
#import "FileInZipInfo.h"
#import "ZipReadStream.h"
#import "RDHTTP.h"
#import "NSData+Base64.h"

#import <DropboxSDK/DropboxSDK.h>
#import "PBGoogleAuthViewController.h"
#import "GTLDrive.h"
#import "PBFlickrAuthentificationViewController.h"

#import "Appirater.h"
#import "LSAppUpdateManager.h"
#import "RD2RateThisAppManager.h"

#import "RSReachability.h"

static NSString * const kDidRegisterForRemoteNotificationsKey = @"didRegisterForRemoteNotifications";

// Time gap to notify user before application will be terminated
static NSTimeInterval const notificationTimeGap = 60.0;
NSString * const PBApplicationDidBecomeActiveNotification = @"PBApplicationDidBecomeActiveNotification";

typedef enum {
    sendToNowhere = 0,
    sendToDropbox = 1,
    sendToFlickr = 2,
    sendToGoogleDrive = 3
} SendToDestination;

@interface PBAppDelegate () <MFMailComposeViewControllerDelegate, DBRestClientDelegate> {
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
    UILocalNotification *_wakeUpNotification;
    BOOL loggingToDropboxFromHelp;
    BOOL loggingToGoogleFromHelp;
    BOOL flickrAuthentificationFromHelp;

    DBRestClient *dbRestClient;
}
@property (nonatomic, retain, readwrite) UINavigationController *navigationController;
@property (nonatomic, strong) id userInfo;
@property (nonatomic, strong) DBRestClient *dbRestClient;

@property (nonatomic, strong) PBFlickrAuthentificationViewController *flickrAuthVC;

@end

@implementation PBAppDelegate

@synthesize dbRestClient = _dbRestClient;

+ (PBAppDelegate *)sharedDelegate {
    return (PBAppDelegate *) [[UIApplication sharedApplication] delegate];
}

+ (id)rootViewController {
    PBNavigationController *sendNavigationController =
        [[[PBNavigationController alloc]
            initWithNavigationBarClass:nil
            toolbarClass:[PBToolbar class]] autorelease];

    PBToolbar *toolbar = (PBToolbar *)sendNavigationController.toolbar;
    toolbar.tapDelegate = [PBRootViewController sharedController];

    BOOL isIphone = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;

    //photoBar
    CGFloat photoBarHeight = isIphone ? 54 : 105;
    PBPhotoBar *photoBar = [[[PBPhotoBar alloc] initWithFrame:CGRectMake(0, 0, 100, photoBarHeight)] autorelease];
    photoBar.alpha = 0;
    sendNavigationController.topToolBar = photoBar;

    if (isIphone) {
        PBAssetsGroupListViewController *vc = [[PBAssetsGroupListViewController new] autorelease];
        [sendNavigationController pushViewController:vc animated:NO];
    }
    else {
        __block PBAssetListViewControllerIpad *vc = [[[PBAssetListViewControllerIpad alloc] initWithAssetsGroup:nil] autorelease];
        [sendNavigationController pushViewController:vc animated:NO];

        PBAssetManager *assetManager = [PBAssetManager sharedManager];
        [assetManager savedPhotosAssetsGroupCompletionBlock:^(ALAssetsGroup *assetGroup) {
            [vc setAssetsGroupUrl:[assetGroup valueForProperty:ALAssetsGroupPropertyURL]];
        }];
    }

    //root viewController
    PBRootViewController *rootVC = [PBRootViewController sharedController];
    rootVC.topViewController = sendNavigationController;
    rootVC.bottomViewController = [[PBReceiveViewController new] autorelease];

    PBHomeScreenBottomView *bottomView = [PBHomeScreenBottomView view];
    bottomView.delegate = rootVC;
    rootVC.bottomView = bottomView;

    PBHomeScreenTopView *topView = [PBHomeScreenTopView view];
    topView.delegate = rootVC;
    rootVC.topView = topView;

    return rootVC;
}

+ (NSString *)serviceName {
    return [[NSString normalizedASCIIStringWithString:[UIDevice currentDevice].name] trim];
}

- (void)endBackgroundTask {
    [self cancelWakeUpNotification];
    [self stopServer];

    if (UIBackgroundTaskInvalid != _backgroundTaskIdentifier) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
    }

    _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
}

+ (NSString *)backgroundTaskNotificationMessage {
    return NSLocalizedString(@"Hury up! Go back to Image Transfer to continue data transfer!", @"Push notification text");
}


#pragma mark - AdImageViewController

+ (PBAdImageViewController *)adImageViewController {
    PBAdImageViewController *controller = [[[PBAdImageViewController alloc]
        initWithNibName:@"PBAdImageViewController" bundle:nil]
        autorelease];

    return controller;
}

- (void)presentAdImageViewControllerWithAdMessage:(AdMessage *)message {
    if (nil == message.adImageURLString) {
        [self registerForRemoteNotifications];
        return;
    }

    NSString *imageURLString = [[message.adImageURLString copy] autorelease];
    NSString *adLinkURLString = [[message.adLinkURLString copy] autorelease];

    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURLString:imageURLString];

    request.timeoutInterval = 20.0;
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        UIImage *adImage = nil;

        if (nil == response.error) {
            NSData *imageData = response.responseData;
            adImage = [UIImage imageWithData:imageData];
        }

        if (nil != adImage) {
            PBAdImageViewController *adImageController = [[self class] adImageViewController];
            adImageController.delegate = self;
            adImageController.modalPresentationStyle = UIModalPresentationFormSheet;

            // Load view to instanciate outlets and be able to set image
            [adImageController view];
            
            [adImageController.adImageView setImage:adImage];
            adImageController.adLinkURL = [NSURL URLWithString:adLinkURLString];

            [self.viewController presentViewController:adImageController
                                              animated:YES
                                            completion:^{

                                            }];
        }
        else {
            [self registerForRemoteNotifications];
        }
    }];
}

- (void)presentAdImageViewController {
    NSInteger launchNumber = [self numberOfTimesApplicationBeenLaunched];

    PBAdMessageLoader *messageLoader = [[[PBAdMessageLoader alloc] init] autorelease];
    [messageLoader loadAdMessageLaunchNumber:launchNumber
        applicationName:PB_APP_NAME
        completion:^(AdMessage *message) {
            [self presentAdImageViewControllerWithAdMessage:message];
        }];
}

- (void)presentAdImageFromRemoteNotification:(NSDictionary *)remoteNotificationPayload {
    NSDictionary *userDict = [remoteNotificationPayload objectForKey:@"user"];
    NSString *messageIDString = [userDict
        objectForKey:@"message_id"];

    NSInteger messageID = [messageIDString integerValue];

    PBAdMessageLoader *messageLoader = [[[PBAdMessageLoader alloc] init] autorelease];
    [messageLoader loadAdMessageID:messageID completion:^(AdMessage *message) {
        [self presentAdImageViewControllerWithAdMessage:message];
    }];
}


#pragma mark - AdImageViewControllerDelegate protocol

- (void)dismissAdImageViewController:(PBAdImageViewController *)controller {
    [self.viewController dismissViewControllerAnimated:YES
                                            completion:^{
                                                [self registerForRemoteNotifications];
                                            }];
}


#pragma mark - Memory management

- (void)dealloc {
    [_userInfo release];
    [_window release];
    [_viewController release];
    [_transferSession release];

    [super dealloc];
}


#pragma mark - UIApplicationDelegate protocol

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  //  [ALAssetsLibrary disableSharedPhotoStreamsSupport];
    
    _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    _wakeUpNotification = nil;
    
    self.userInfo = nil;
    

    [self logNumberOfTimesApplicationWereLaunched];
  //  [[self class] setupAppearance];
    
    // Create window
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.viewController = [[self class] rootViewController];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    [PBConnectionManager start];
    [self registerOnNotifications];
    [self prepareHttpServer];
    [[CBAnalyticsManager sharedManager] appStart];

    //check flickr token
    self.flickrEngine = [[[PBFlickrUploadingEngine alloc] init] autorelease];
    if ([self.flickrEngine isAuthorized]) {
        [self.flickrEngine checkIfTokenValid];
    }
    
    //set up DBSession for Dropbox
    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:PB_DROPBOX_APP_KEY
                            appSecret:PB_DROPBOX_APP_SECRET
                            root:PB_DROPBOX_ROOT];
    [DBSession setSharedSession:dbSession];
    
    //rate the app
    [Appirater setAppId:PB_APPSTORE_ID];
    
    LSItunesAppUpdateManager *updateManager = [[LSItunesAppUpdateManager alloc] initWithAppID:PB_APPSTORE_ID];
    [updateManager checkForUpdateWithCompletion:nil];
    [LSAppUpdateManager setSharedManager:updateManager];
    
    [self showSplash:launchOptions];
    
    [[LSAppUpdateManager sharedManager] saveLastStartedAppVersion];
    
    [self parseString:@"Send last 10 media files"];

    return YES;
}

#pragma mark-
#pragma WhatsNew
#pragma mark -

- (BOOL)showUpdateAvailableIfNeeded{
    BOOL result = NO;
    id<LSAppUpdateManager> updateManager = [LSAppUpdateManager sharedManager];
    result = [updateManager shouldShowUpdateAvailableUserPromt];
    if(result){
        [updateManager showUpdateAvailableUserPromtWithCompletion:nil];
    }
    return result;
}

- (BOOL)showWhatsNewIfNeeded{
    BOOL result = NO;
    result = [[LSAppUpdateManager sharedManager] shouldShowWhatsNewUserPromt];
    if(result){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO forKey:kPBUserRatedApp];
        [defaults removeObjectForKey:kPBLastDateRateWasShown];
        [defaults setInteger:0 forKey:kPBNumberOfTimesPhotosWereSentForRate];
        [defaults synchronize];
        
        [[LSAppUpdateManager sharedManager] showWhatsNewUserPromtWithCompletion:nil];
    }
    return result;
}

- (void)showSplash:(NSDictionary *)launchOptions{
    BOOL splashDidShow = [self showWhatsNewIfNeeded];
    if(splashDidShow==NO){
        splashDidShow = [self showUpdateAvailableIfNeeded];
    }
    
    // Check launch options
    // if it's remote notification load Ad image from remote notification
    
    NSDictionary *remoteNotificationPayload =
    [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    
    
    // Registration for remote notification is launched from dismissAdImageViewController:
    // It can be interchanged with registerForRemoteNotifications, but do not run simultaneosly because
    // both of them try to present child controller from root view controller.
    
    if (nil == remoteNotificationPayload) {
        [self presentAdImageViewController];
    }
    else {
        [self presentAdImageFromRemoteNotification:remoteNotificationPayload];
    }
}

#pragma mark-

- (void)applicationWillResignActive:(UIApplication *)application {
    if (((nil == _transferSession) || _transferSession.isCanceled) &&
        (NO == _httpServer.isUploadInProgress)) {

        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        [self stopServer];
        return;
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _backgroundTaskIdentifier = UIBackgroundTaskInvalid;

    if (PBGetSystemVersion() < 6.0) {
        if ([[PBAssetManager sharedManager] isAssetsLibraryAccessGranted] == NO) {
            NSLog(@"iOS5 specific: No AssetsLibrary access, exiting instead of sleeping");
            exit(0);
        }
    }

    if (((nil == _transferSession) || _transferSession.isCanceled) &&
        ((nil == self.httpServer) || (NO == _httpServer.isUploadInProgress))) {

        [self stopServer];
        return;
    }


    // Begin background task if transfer session is in progress
    _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];

    if (_backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        [self stopServer];
        return;
    }


    // Schedule local notification, so user could bring application to foreground
    //  before it would be terminated

    NSTimeInterval remainingTime = [[UIApplication sharedApplication] backgroundTimeRemaining];
    remainingTime -= notificationTimeGap;

    if (remainingTime > 0) {
        NSDate *notificationFireDate = [NSDate dateWithTimeIntervalSinceNow:remainingTime];
        [self scheduleWakeUpNotificationOnDate:notificationFireDate];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self cancelWakeUpNotification];
    [[CBAnalyticsManager sharedManager] appEnterForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (_backgroundTaskIdentifier == UIBackgroundTaskInvalid) {

        // Do not start server if there is no access to assets library.
        // It prevents upload and errors after import attempts.
        [[PBAssetManager sharedManager] savedPhotosAssetsGroupCompletionBlock:
            ^(ALAssetsGroup *assetGroup) {
                if (nil != assetGroup) {
                    [self startHttpServer];
                }
            }];
    }
    else {
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }

    [[NSNotificationCenter defaultCenter]
        postNotificationName:PBApplicationDidBecomeActiveNotification
        object:nil
        userInfo:nil];

    [[PBAssetManager sharedManager] checkAssetsLibraryAccessGranted];
}

- (void)applicationWillTerminate:(UIApplication *)application {

}

- (BOOL)application:(UIApplication *)application
    openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
    annotation:(id)annotation {
    //flickr
    if ([[url absoluteString] containsString:@"flickr"]) {
        //dismiss
        [self.flickrAuthVC dismissViewControllerAnimated:YES completion:nil];
       return [self.flickrEngine runAuthStepWithURL:url];
    }
    
    //dropbox
    NSLog(@"sourceApplication is %@", sourceApplication);
    if ([sourceApplication isEqualToString:@"com.getdropbox.Dropbox"]) {
        if ([[DBSession sharedSession] handleOpenURL:url]) {
            if ([[DBSession sharedSession] isLinked]){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DropboxAccountSucessfullyLinked" object:nil];
                if (!loggingToDropboxFromHelp) {
                    [self performSelector:@selector(presentUploadToDropboxVC)
                               withObject:nil
                               afterDelay:0.5];
                }
                else {
                    loggingToDropboxFromHelp = NO;
                }
            }
            
            
            return YES;
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error."
                                                            message:@"Couldn't connect to Dropbox account."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return NO;
        }
    }

    return YES;
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

    // Send token to server ...
    // PUSH request to /registerDevice.php
    // parameters:
    //     - token, encoded as base64
    //     - token2, (deviceID)
    //     - deviceType, (iphone/ipad)
    //     - appid, value of PB_APP_NAME
    //     - secondsFromGMT, value of [[NSTimeZone localTimeZone] secondsFromGMT]

    RDHTTPFormPost *postData = [[[RDHTTPFormPost alloc] init] autorelease];

    NSString *tokenBase64String = [deviceToken base64EncodedString];
    
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
  //  NSLog(@"content---%@", token);
  //  NSLog(@"tokenBase64String ---%@", tokenBase64String);
    
   /* UIAlertView *deviceTokenAlert = [[UIAlertView alloc] initWithTitle:@"Device Token"
                                                               message:tokenBase64String
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
    
    [deviceTokenAlert show];
    [deviceTokenAlert release];
    */
    [postData setPostValue:tokenBase64String forKey:@"token"];


    NSString *deviceIdentifier = [[PBConnectionManager sharedManager] deviceIndentifier];
    [postData setPostValue:deviceIdentifier forKey:@"token2"];


    NSString *deviceType =
        ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            ? @"ipad"
            : @"iphone";

    [postData setPostValue:deviceType forKey:@"deviceType"];

    
    [postData setPostValue:PB_APP_NAME forKey:@"appid"];


    NSInteger secondsFromGMT = [[NSTimeZone localTimeZone] secondsFromGMT];
    NSString *secondsFromGMTString = [NSString stringWithInteger:secondsFromGMT];
    [postData setPostValue:secondsFromGMTString forKey:@"secondsFromGMT"];

    
    NSString *URLString = @"http://sendp.com/registerDevice.php";
    RDHTTPRequest *request = [RDHTTPRequest postRequestWithURLString:URLString];
    [request setFormPost:postData];
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        NSLog(@"Did send token on server");
        NSLog(@"Responce string:%@", response.responseString);
        NSLog(@"Responce error:%@", response.error);
    }];
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {

    NSLog(@"Error in registration. Error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
   
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive) {
        NSString *message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
        if (![message isEqualToString:@""]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:PB_APP_NAME
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            [alertView release];
        }
    }
    
    if (![[[[userInfo valueForKey:@"user"] valueForKey:@"url"] valueForKey:@"iphone_link"] isEqualToString:@""]) {
        [self presentAdImageFromRemoteNotification:userInfo];
    }
}

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}
#endif


#pragma mark - Local Notifications

- (void)registerOnNotifications {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(showAuthentificationWebView:)
     name:@"ShowAuthentificationWebView"
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(presentUploadToFlickrVC)
     name:@"AuthentificationSuccessfullyFinished"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(finishedPhotosDelivery:)
        name:PBGetFileServletDidDeliverServletResponse
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(finishedPhotosDelivery:)
        name:PBAssetUploaderUploadDidFinishNotification
        object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loggingToDropboxFromHelp)
                                                 name:@"PBHelpViewControllerLoggingToDropbox"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loggingToFlickrFromHelp)
                                                 name:@"PBHelpViewControllerLoggingToFlickr"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loggingToGoogleFromHelp)
                                                 name:@"PBHelpViewControllerLoggingToGoogle"
                                               object:nil];
}
-(void)loggingToFlickrFromHelp {
    flickrAuthentificationFromHelp = YES;
}

-(void)loggingToDropboxFromHelp {
    loggingToDropboxFromHelp = YES;
}

-(void)loggingToGoogleFromHelp {
    loggingToGoogleFromHelp = YES;
}

- (void)scheduleWakeUpNotificationOnDate:(NSDate *)fireDate {
    [self cancelWakeUpNotification];

    NSString *message = [[self class] backgroundTaskNotificationMessage];
    NSString *buttonTitle = NSLocalizedString(@"Open", @"Open");

    _wakeUpNotification = [[UILocalNotification alloc] init];
    _wakeUpNotification.fireDate = fireDate;
    _wakeUpNotification.alertBody = message;
    _wakeUpNotification.alertAction = buttonTitle;

    [[UIApplication sharedApplication] scheduleLocalNotification:_wakeUpNotification];
}

- (void)cancelWakeUpNotification {
    if (nil != _wakeUpNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:_wakeUpNotification];
        _wakeUpNotification = nil;
    }
}


#pragma mark - Remote Notificatins

- (BOOL)shouldAskPersmissionsForRemoteNotifications {
    BOOL didRegister = [[NSUserDefaults standardUserDefaults]
        boolForKey:kDidRegisterForRemoteNotificationsKey];

    return (NO == didRegister);
}

- (void)setDidRegisterForRemoteNotifications:(BOOL)flag {
    [[NSUserDefaults standardUserDefaults] setBool:flag
        forKey:kDidRegisterForRemoteNotificationsKey];

    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (UIUserNotificationType)remoteNotificationsTypes {
    return (UIUserNotificationTypeBadge |
            UIUserNotificationTypeAlert |
            UIUserNotificationTypeSound);
}

- (void)registerForRemoteNotifications {
    if (![self shouldAskPersmissionsForRemoteNotifications]) {
        return;
    }
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        UIUserNotificationSettings *userNotifSettings = [UIUserNotificationSettings settingsForTypes:[self remoteNotificationsTypes]
                                                                                         categories:nil];
        if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
            [[UIApplication sharedApplication] registerUserNotificationSettings:userNotifSettings];
            return;
        }
    }

    // Check if permission should be asked, once
    // registerForRemoteNotificationTypes: method been called, never
    // present request permissions screen again



    NSInteger launchNumber = [self numberOfTimesApplicationBeenLaunched];
    BOOL shouldAskPermissions = ((launchNumber == 1) ||
                                 (launchNumber == 2) ||
                                 (launchNumber == 6) ||
                                 (launchNumber == 11) ||
                                 (launchNumber == 15));

    if (!shouldAskPermissions) {
        return;
    }

    [self presentRequestForRemoteNotificationsPermissionsViewController];
}

- (void)presentRequestForRemoteNotificationsPermissionsViewController {
    PBPermissionsRequestViewController *controller =
        [[PBPermissionsRequestViewController alloc]
            initWithNibName:@"PBPermissionsRequestViewController"
            bundle:nil];

    controller.delegate = self;
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.viewController presentViewController:controller
                                      animated:YES
                                    completion:^{

                                    }];
}


#pragma mark - PBPermissionsRequestViewControllerDelegate protocol

- (void)permissonsGrantedFromViewController:(UIViewController *)controller {
    [self setDidRegisterForRemoteNotifications:YES];

    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                                                                                                                                    categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }

}

- (void)dismissPermissionsRequestViewController:(UIViewController *)controller {
    [self.viewController dismissViewControllerAnimated:YES
                                            completion:^{

                                            }];
}


#pragma mark - Application launch counter

- (void)logNumberOfTimesApplicationWereLaunched {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger numberOfLaunches = [defaults integerForKey:kPBNumberOfTimesAppWereLaunched];
    numberOfLaunches++;

    [defaults setInteger:numberOfLaunches forKey:kPBNumberOfTimesAppWereLaunched];
    [defaults synchronize];

  //  NSLog(@"Number of times app were launched: %d", numberOfLaunches);
}

- (NSInteger)numberOfTimesApplicationBeenLaunched {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger counter = [defaults integerForKey:kPBNumberOfTimesAppWereLaunched];

    return counter;
}


#pragma mark - HTTP Server Management

- (void)prepareHttpServer {
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        PBCleanTemporaryDirectory();
        [self unarchiveWebClient];
    });
}

- (void)unarchiveWebClient {
    NSString *webPartName = PB_WEBPART_MOBILE_NAME;
    NSString *libraryDirectoryPath = PBApplicationLibraryDirectory();
    NSString *webClientPath = PBApplicationLibraryDirectoryAdd(webPartName);

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:webClientPath] == NO) {
        [fileManager createDirectoryAtPath:webClientPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];

        NSString *webPartZipPath = [[NSBundle mainBundle] pathForResource:webPartName ofType:@"zip"];
        ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:webPartZipPath mode:ZipFileModeUnzip];

        NSArray *infos = [unzipFile listFileInZipInfos];
        for (FileInZipInfo *info in infos) {
            NSLog(@"- %@ %@ %lu (%d)", info.name, info.date, (unsigned long)info.size, info.level);

            // Locate the file in the zip
            [unzipFile locateFileInZip:info.name];
 
            // Expand the file in memory
            ZipReadStream *read= [unzipFile readCurrentFileInZip];
            NSData *data = [read readDataOfLength:1024*1024];
            if (info.size > 0) {
                NSString *fname = [libraryDirectoryPath stringByAppendingPathComponent:info.name];
                NSLog(@"file extracted: %@", fname);
                NSString *parentFileDir = [fname stringByDeletingLastPathComponent];
                [fileManager createDirectoryAtPath:parentFileDir withIntermediateDirectories:YES attributes:nil error:nil];
                [fileManager createFileAtPath:fname contents:data attributes:nil];
            }
            [read finishedReading];
        }

        [unzipFile close];
        [unzipFile release];
        
        NSLog(@"WebClient unarchived");
    }
}

- (void)startHttpServer {
    if (_httpServer == nil) {
        int port = PB_HTTP_SERVER_START_PORT;

        NSLog(@"Starting HTTP server on port %d", port);
        self.httpServer = [[[PBMongooseServer alloc] initWithPort:port allowDirectoryListing:NO] autorelease];
        
        if (!self.httpServer) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unexpected network error.", @"")
                                                            message:NSLocalizedString(@"Please, check Help->Troubleshooting for possible solutions.", @"")
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:NSLocalizedString(@"Show Help", @""), nil];
            [alert show];
        }

        [_httpServer addServlet:[PBStatusServlet servlet] forPath:@"/status"];
        [_httpServer addServlet:[PBGetFileServlet servlet] forPath:@"/files/*"];
        [_httpServer addServlet:[PBBeginTransferServlet servlet] forPath:[@"/" stringByAppendingString:kBeginTransferPath]];
        [_httpServer addServlet:[PBFinishTransferServlet servlet] forPath:[@"/" stringByAppendingString:kFinishTransferPath]];
        [_httpServer addServlet:[PBCancelTransferServlet servlet] forPath:[@"/" stringByAppendingString:kCancelTransferPath]];

        PBUploadServlet *uploadServlet = [PBUploadServlet servlet];
        uploadServlet.notifyPostBodyProgressUpdates = YES;
        [_httpServer addServlet:uploadServlet forPath:@"/upload*"];

        [_httpServer addServlet:[PBRootServlet servlet] forPath:@"/"];
    } else {
        [_httpServer start];
    }
}

- (void)stopServer {
    if ((nil != _transferSession) && !_transferSession.isCanceled) {
        [_transferSession cancel];
    }

    NSLog(@"Stopping HTTP server");
    [_httpServer forceStop];
    [self setHttpServer:nil];
}

#pragma mark - AlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        [[PBRootViewController sharedController] presentHelpViewController];
    }
}

#pragma mark - ViewController presenting

- (void)presentConnectViewControllerInNavigationController:(UINavigationController *)navigationController {
    //debug
//    [self actionSheetDidSelectSendToDesktopComputer:navigationController];
//    [self actionSheetDidSelectSendToIosDevice:navigationController];
//    return;
    //
    
    //start preparing assets ZIP while user making his or her choice where to send images to
    [[PBAssetManager sharedManager] prepareAssetsToSendWithCompletion:nil];
    
    

    UIAlertController *actionSheet = [UIAlertController
                                      alertControllerWithTitle:NSLocalizedString(@"Where would you like to send photos to?", @"")
                                      message:nil
                                      preferredStyle:UIAlertControllerStyleActionSheet];
    //actionSheet.userInfo = navigationController;
    UIAlertAction *sendToIPhone = [UIAlertAction actionWithTitle:NSLocalizedString(@"Send to iPhone or iPad", @"")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self performSelector:@selector(actionSheetDidSelectSendToIosDevice:) withObject:nil];
                                                         }];
    [actionSheet addAction:sendToIPhone];

    UIAlertAction *sendToComputer = [UIAlertAction actionWithTitle:NSLocalizedString(@"Send to Computer", @"")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self performSelector:@selector(actionSheetDidSelectSendToDesktopComputer:) withObject:nil];
                                                         }];
    [actionSheet addAction:sendToComputer];
    UIAlertAction *sendToDropbox = [UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Send to %@", @""), @"Dropbox"]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self performSelector:@selector(actionSheetDidSelectSendToDropbox:) withObject:nil];
                                                         }];
    [actionSheet addAction:sendToDropbox];
    UIAlertAction *sendToGDrive = [UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Send to %@", @""), @"GoogleDrive"]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self performSelector:@selector(actionSheetDidSelectSendToGoogleDrive:) withObject:nil];
                                                         }];
    [actionSheet addAction:sendToGDrive];
    UIAlertAction *sendToFlickr = [UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Send to %@", @""), @"Flickr"]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self performSelector:@selector(actionSheetDidSelectSendToFlickr:) withObject:nil];
                                                         }];
    [actionSheet addAction:sendToFlickr];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [actionSheet addAction:cancel];


//    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
//        [PBActionSheet cancelAllActionSheets];
//        [actionSheet showFromBarButtonItem:navigationController.topViewController.navigationItem.rightBarButtonItem
//                                  animated:YES];
//    } else {
//        [actionSheet showInView:navigationController.view];
//    }
//
    [navigationController presentViewController:actionSheet animated:YES completion: nil];

                             
                             
    [actionSheet release];
}

- (void)actionSheetDidSelectSendToIosDevice:(id)userInfo {
    if (!PBGetLocalIP()) {
        //!no WiFi connection
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NoWIFiConnectionForSending" object:nil];
        return;
    }

    
    //cancel preparing ZIP
    [[PBAssetManager sharedManager] cancelPreparingAssets];

    
    PBNearbyDeviceListViewController *vc =
        [[[PBNearbyDeviceListViewController alloc]
            initWithNibName:@"PBNearbyDeviceListViewController"
            bundle:nil]
        autorelease];

    vc.hidesBottomBarWhenPushed = YES;
    UINib *cellNib = [UINib nibWithNibName:@"PBNearbyDeviceCellView" bundle:nil];
    vc.tableViewCellNib = cellNib;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        vc.title = NSLocalizedString(@"Send to iPhone or iPad", @"");
    }
    else {
        vc.title = NSLocalizedString(@"Send", @"");
    }

    UINavigationController *navigationController = userInfo;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [navigationController presentViewController:nc
                                           animated:YES
                                         completion:nil];
    } else {
        [navigationController pushViewController:vc animated:YES];
    }
}

- (void)actionSheetDidSelectSendToDesktopComputer:(id)userInfo {
    if (!PBGetLocalIP()) {
        //!no WiFi connection
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NoWIFiConnectionForSending" object:nil];
        return;
    }

    PBConnectViewController *vc = [[[PBConnectViewController alloc] init] autorelease];
    vc.sendAssetsUI = YES;

    UINavigationController *navigationController = userInfo;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [navigationController presentViewController:nc
                                           animated:YES
                                         completion:nil];
    } else {
        [navigationController pushViewController:vc animated:YES];
    }

}

#pragma mark - Dropbox
-(DBRestClient *)dbRestClient {
    if (!_dbRestClient) {
        _dbRestClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        [_dbRestClient setDelegate:self];
    }
    return _dbRestClient;
}

- (void)actionSheetDidSelectSendToDropbox:(id)userInfo {
    if ([[RSReachability RSReachabilityForInternetConnection] currentRSReachabilityStatus] == RSNotReachable) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NoInternetConnectionForSending" object:nil];
        return;
    }
    
    self.userInfo = userInfo;
    
    if ([[DBSession sharedSession] isLinked]) {
        [self.dbRestClient loadAccountInfo];
    }
    else {
        [[DBSession sharedSession] linkFromController:userInfo];
        
    }

}
#pragma mark - DBRestClientDelegate
- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error {
    if (error.code == 401) {
        [[DBSession sharedSession] unlinkAll];
        [[DBSession sharedSession] linkFromController:self.userInfo];
    }
}

-(void)restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info {
    [self presentUploadToDropboxVC];
}

-(void)presentUploadToDropboxVC{
    //cancel preparing ZIP
    [[PBAssetManager sharedManager] cancelPreparingAssets];
    
    PBCommonUploadToViewController *vc = [[[PBCommonUploadToViewController alloc] init] autorelease];
    vc.uploadingEngine = [[PBDropboxUploaingEngine alloc] init];
    
    UINavigationController *navigationController = self.userInfo;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        
        UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [navigationController presentViewController:nc
                                           animated:YES
                                         completion:nil];
    }
    else {
        navigationController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
        [navigationController presentViewController:vc
                                           animated:YES
                                         completion:nil];
    }
    
    
}

#pragma mark - Flickr

-(void)showAuthentificationWebView:(NSNotification *)notification {

    self.flickrAuthVC = [[[PBFlickrAuthentificationViewController alloc] init] autorelease];
    [self.flickrAuthVC loadAuthURL:[notification.userInfo objectForKey:@"authURL"]];
    
    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:self.flickrAuthVC] autorelease];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [((UINavigationController*)self.window.rootViewController) presentViewController:nc
                                                                            animated:YES
                                                                          completion:nil];
    
}


- (void)actionSheetDidSelectSendToFlickr:(id)userInfo {
    if ([[RSReachability RSReachabilityForInternetConnection] currentRSReachabilityStatus] == RSNotReachable) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NoInternetConnectionForSending" object:nil];
        return;
    }

    self.userInfo = userInfo;
    
    if (![self.flickrEngine isAuthorized]) {
        [self.flickrEngine startAuthentification];
    }
    else {
        [self presentUploadToFlickrVC];
    }
}


-(void)presentUploadToFlickrVC {
    if (flickrAuthentificationFromHelp) {
        flickrAuthentificationFromHelp = NO;
        return;
    }
    
    //cancel preparing ZIP
    [[PBAssetManager sharedManager] cancelPreparingAssets];
    
    PBCommonUploadToViewController *vc = [[[PBCommonUploadToViewController alloc] init] autorelease];
    vc.uploadingEngine = self.flickrEngine;
    
    UINavigationController *navigationController = self.userInfo;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        
        UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [navigationController presentViewController:nc
                                           animated:YES
                                         completion:nil];
    }
    else {
        navigationController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
        [navigationController presentViewController:vc
                                           animated:YES
                                         completion:nil];
    }
}


#pragma mark - GoogleDrive

// Creates the auth controller for authorizing access to Google Drive.
- (PBGoogleAuthViewController *)createAuthController {
    PBGoogleAuthViewController *authController = [[PBGoogleAuthViewController alloc] initWithScope:kGTLAuthScopeDriveFile
                                                                clientID:PB_GOOGLE_DRIVE_CLIENT_KEY
                                                            clientSecret:PB_GOOGLE_DRIVE_CLIENT_SECRET
                                                        keychainItemName:PB_GOOGLE_KEYCHAIN_ITEM_NAME
                                                                delegate:self
                                                        finishedSelector:@selector(googleDriveAuthController:finishedWithAuth:error:)];


    
    return authController;
}

// Handle completion of the authorization process, and updates the Drive service
// with the new credentials.
- (void)googleDriveAuthController:(PBGoogleAuthViewController *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    
    [viewController.presentingViewController dismissViewControllerAnimated:NO
                                                                completion:nil];
    
    if (error != nil) {
        [self.googleDriveEngine setAuthorizer:nil];
    }
    else {
        [self.googleDriveEngine setAuthorizer:authResult];
        [self presentUploadToGoogleDriveVC];
    }
}

-(void)actionSheetDidSelectSendToGoogleDrive:(id)userInfo {
    if ([[RSReachability RSReachabilityForInternetConnection] currentRSReachabilityStatus] == RSNotReachable) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NoInternetConnectionForSending" object:self];
        return;
    }
    
    self.userInfo = userInfo;
  
    self.googleDriveEngine = [[[PBGoogleDriveUploadingEngine alloc] init] autorelease];
    if (![self.googleDriveEngine isAuthorized]) {
        [self showGoogleAuthorizationController];
    }
    else {
        [self presentUploadToGoogleDriveVC];
    }
}


-(void)showGoogleAuthorizationController {
    if (!self.googleDriveEngine) {
        self.googleDriveEngine = [[[PBGoogleDriveUploadingEngine alloc] init] autorelease];
    }
    
    UINavigationController *navigationController = ((UINavigationController*)self.window.rootViewController);
    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:[self createAuthController]] autorelease];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [navigationController presentViewController:nc
                                       animated:YES
                                     completion:nil];
}

-(void)presentUploadToGoogleDriveVC {
    if (loggingToGoogleFromHelp) {
        loggingToGoogleFromHelp = NO;
        return;
    }
    
    //cancel preparing ZIP
    [[PBAssetManager sharedManager] cancelPreparingAssets];
    
    PBCommonUploadToViewController *vc = [[[PBCommonUploadToViewController alloc] init] autorelease];
    vc.uploadingEngine = self.googleDriveEngine;
    
    UINavigationController *navigationController = self.userInfo;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        
        UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [navigationController presentViewController:nc
                                           animated:YES
                                         completion:nil];
    }
    else {
        navigationController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
        [navigationController presentViewController:vc
                                           animated:YES
                                         completion:nil];
    }
}

#pragma mark - Support

- (NSString *)supportInformation {

    NSString *signString = @"\n\n\n\n – Don't delete this block, it's necessary for quality and operational support\n";
    NSString *applicationName = [NSString stringWithFormat:@"App: %@\n", PB_APP_NAME];
    signString = [signString stringByAppendingString:applicationName];

    NSString *versionString = @"Version: Plus\n";
    signString = [signString stringByAppendingString:versionString];

    NSString *systemVersion = [NSString stringWithFormat:@"iOS version: %@\n", [[UIDevice currentDevice] systemVersion]];
    signString = [signString stringByAppendingString:systemVersion];

    NSString *deviceVersion = [NSString stringWithFormat:@"Device: %@\n", RDDeviceModelSupportLogName()];
    signString = [signString stringByAppendingString:deviceVersion];

    NSString *userID = [[[PBConnectionManager sharedManager] permanentUrlString] lastPathComponent];
    NSString *userIDString = [NSString stringWithFormat:@"Unique_ID: %@\n", userID];
    signString = [signString stringByAppendingString:userIDString];


    return signString;
}

- (void)presentContactSupportEmailComposeViewControllerFromViewController:(UIViewController *)viewController {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mvc = [[MFMailComposeViewController new] autorelease];
        mvc.mailComposeDelegate = self;
        mvc.navigationBar.tintColor = [UIColor whiteColor];
        
#if PB_LITE
        NSString *subject = [PB_APP_NAME stringByAppendingString:[[[self class] sharedDelegate] isFullVersion] ? @" (Plus)" : @""];
#else
        NSString *subject = PB_APP_NAME;
#endif
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            subject = [subject stringByAppendingString:@", iPad"];
        }
        subject = [subject stringByAppendingFormat:@" v%@, iOS %@", PBGetAppVersion(), PBGetSystemMajorMinorVersionString()];
        
        
        [mvc setSubject:subject];
        [mvc setToRecipients: @[PB_SUPPORT_EMAIL_ADDRESS]];

        NSString *body = [self supportInformation];
        [mvc setMessageBody:body isHTML:NO];


        mvc.modalPresentationStyle = UIModalPresentationFormSheet;
        [viewController presentViewController:mvc
                                     animated:YES
                                   completion:nil];
        
    } else {
        PBAlertOK(NSLocalizedString(@"No email account", @""),
                  NSLocalizedString(@"There are no email accounts configured. You can add or create email account in the Settings app.", @""));
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {

    [controller.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Asset delivery handlers

- (void)finishedPhotosDelivery:(NSNotification *)notification {
    if (UIApplicationStateBackground == [[UIApplication sharedApplication] applicationState]) {
        [self endBackgroundTask];
    }

    PBAssetManager *assetManager = [PBAssetManager sharedManager];
    [assetManager cancelPreparingAssets];
    [assetManager removeAllAssets];

    PBRootViewController *rvc = (PBRootViewController *)self.viewController;
  //  [rvc presentStartCoverViewsAnimated:YES];
    UINavigationController *nc = (UINavigationController *)rvc.topViewController;
    [nc popToRootViewControllerAnimated:NO];
}


#pragma mark - Appearance

+ (void)setupAppearance {
    id labelAppearance = [UILabel appearance];
    [labelAppearance setTextColor:[UIColor colorWithRGB:0x505050]];
    [labelAppearance setShadowColor:[UIColor colorWithWhite:1 alpha:1]];
    [labelAppearance setShadowOffset:CGSizeMake(0, 1)];
    [labelAppearance setBackgroundColor:[UIColor clearColor]];

    id navbarAppearance = [UINavigationBar appearance];
    
    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [UIColor colorWithRGB:0xac4923];
    NSDictionary *titleAttributes = @{
        NSShadowAttributeName : shadow,
        NSForegroundColorAttributeName : [UIColor whiteColor]
    };
                        
    [navbarAppearance setTitleTextAttributes:titleAttributes];
    [navbarAppearance setBackgroundImage:[UIImage imageNamed:@"navbar_bg"]
                          forBarPosition:UIBarPositionTopAttached
                              barMetrics:UIBarMetricsDefault];

    id bbiAppearance = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationController class], nil];
    
    NSDictionary *bbiAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [UIColor whiteColor],
                                   NSForegroundColorAttributeName,
                                   [UIColor whiteColor],
                                   NSShadowAttributeName, nil];
    
    [bbiAppearance setTitleTextAttributes: bbiAttributes
                                 forState: UIControlStateNormal];



    UIImage *backImage = [[UIImage imageNamed:@"navbar_back_button_normal"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
    [bbiAppearance setBackButtonBackgroundImage:backImage
                                       forState:UIControlStateNormal
                                     barMetrics:UIBarMetricsDefault];

    UIImage *backPushedImage = [[UIImage imageNamed:@"navbar_back_button_pushed"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
    [bbiAppearance setBackButtonBackgroundImage:backPushedImage
                                       forState:UIControlStateHighlighted
                                     barMetrics:UIBarMetricsDefault];

    UIImage *normalImage = [[UIImage imageNamed:@"navbar_button_normal"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [bbiAppearance setBackgroundImage:normalImage
                             forState:UIControlStateNormal
                           barMetrics:UIBarMetricsDefault];

    UIImage *normalPushedImage = [[UIImage imageNamed:@"navbar_button_pushed"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [bbiAppearance setBackgroundImage:normalPushedImage
                             forState:UIControlStateHighlighted
                           barMetrics:UIBarMetricsDefault];
}


#pragma mark - Properties

- (BOOL)isFullVersion {
    return YES;
}

#pragma mark - Data from Apple Watch

-(NSDictionary *)numbers {
    return @{@"one":@1, @"two":@2, @"three":@3, @"four":@4, @"five":@5, @"six":@6, @"seven":@7, @"eight":@8, @"nine":@9, @"ten":@10, @"eleven":@11, @"twelve":@12, @"thirteen":@13, @"fourteen":@14, @"fifteen":@15, @"sixteen":@16, @"seventeen":@17, @"eighteen":@28, @"nineteen":@19, @"twenty":@20, @"thirty":@30, @"forty":@40, @"fifty":@50, @"sixty":@60, @"seventy":@70, @"eighty":@80, @"ninety":@90, @"hundred":@100};
}

-(void)parseString:(NSString *)sendString {
    NSMutableString *stringOfNumbers = [NSMutableString stringWithCapacity:sendString.length];
    
    NSScanner *scanner = [NSScanner scannerWithString:sendString];
    NSCharacterSet *numbersCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890"];
    
    while (![scanner isAtEnd]) {
        NSString *buf;
        if ([scanner scanCharactersFromSet:numbersCharacterSet intoString:&buf]) {
            [stringOfNumbers appendString:buf];
        }
        else {
            [scanner setScanLocation:scanner.scanLocation+1];
        }
        
    }
    NSLog(@"stringOfNumbers: %@", stringOfNumbers);
    
    if ([stringOfNumbers isEqualToString:@""]) { // try to find numbers in words
        NSArray *wordsArray = [sendString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,-"]];
    }
    
}

-(void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply {
    NSString *whatToSendString = [userInfo objectForKey:@"whatToSend"];
    NSNumber *whereToSendNum = [userInfo objectForKey:@"whereToSend"];
    
    reply(@{@"Start sending":whatToSendString, @"Where to send:":whereToSendNum});
    
    //parse string and start sending
    
    [self parseString:whatToSendString];
    
}

@end
