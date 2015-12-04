//
//  Lite-PBAppDelegate.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 18/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "Lite_PBAppDelegate.h"
#import "PBPurchaseManager.h"
#import "PBPurchaseViewController.h"
#import "PBAssetManager.h"
#import "RDHTTP.h"
#import "PBConnectionManager.h"

@interface Lite_PBAppDelegate ()<PBPurchaseViewControllerDelegate, UIAlertViewDelegate>

@end

@implementation Lite_PBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL ok = [super application:application didFinishLaunchingWithOptions:launchOptions];

    // Start Purchase manager
    [PBPurchaseManager sharedManager];

    [self setTransferLimitations];

    if ([self plusVersionInstalled]) {
        [self showOpenPlusVersionAlertView];
    }

    if ([[PBPurchaseManager sharedManager] isFullVersionUnlocked]) {
        NSLog(@"=== BOUGHT PLUS VERSION ===");
    }
    else if ([[PBPurchaseManager sharedManager] isAdminFullVersionUnlocked]) {
        NSLog(@"=== ADMIN GRANTED PLUS VERSION ===");
    }
    else {
        NSLog(@"=== LITE VERSION ===");
        
        [self registerOnPurchaseManagerNotifications];
        
        //unarchive ad if needed
        [self performSelectorInBackground:@selector(unarchiveAd) withObject:nil];
    }

    
    return ok;
}

- (void)setTransferLimitations {
    PBPurchaseManager *purchaseManager = [PBPurchaseManager sharedManager];
    PBAssetManager *assetsManager = [PBAssetManager sharedManager];

    NSInteger maximumPhotosToSend = ([purchaseManager unlimitedPhotos])
        ? NSIntegerMax
        : PB_LITE_VERSION_MAX_PHOTOS_TO_SEND;

    [assetsManager setMaximumNumberOfPhotos:maximumPhotosToSend];

    
    NSInteger maximumVideosToSend = ([purchaseManager unlimitedVideos])
        ? NSIntegerMax
        : PB_LITE_VERSION_MAX_VIDEOS_TO_SEND;

    [assetsManager setMaximumNumberOfVideos:maximumVideosToSend];


    BOOL videoDurationUnlimited = (([purchaseManager fullVersion]) ||
                                   ([purchaseManager unlimitedVideos]));

    NSInteger maximumVideoDuration = (videoDurationUnlimited)
        ? 0
        : PB_LITE_VERSION_MAX_VIDEO_DURATION;

    [assetsManager setMaximumVideoDuration:maximumVideoDuration];
}


#pragma mark - Support

- (NSString *)supportInformation {

    NSString *signString = @"\n\n\n\n – Don't delete this block, it's necessary for quality and operational support\n";
    NSString *applicationName = [NSString stringWithFormat:@"App: %@\n", PB_APP_NAME];
    signString = [signString stringByAppendingString:applicationName];

    NSString *versionString = @"Version: Lite\n";
    signString = [signString stringByAppendingString:versionString];

    NSString *systemVersion = [NSString stringWithFormat:@"iOS version: %@\n", [[UIDevice currentDevice] systemVersion]];
    signString = [signString stringByAppendingString:systemVersion];

    NSString *deviceVersion = [NSString stringWithFormat:@"Device: %@\n", RDDeviceModelSupportLogName()];
    signString = [signString stringByAppendingString:deviceVersion];

    NSString *userID = [[[PBConnectionManager sharedManager] permanentUrlString] lastPathComponent];
    NSString *userIDString = [NSString stringWithFormat:@"Unique_ID: %@\n", userID];
    signString = [signString stringByAppendingString:userIDString];

    NSString *bundles = @"";
    PBPurchaseManager *purchaseManager = [PBPurchaseManager sharedManager];
    if ([purchaseManager fullVersion]) {
        bundles = @"NL";
    }
    else if ([purchaseManager unlimitedPhotos]) {
        bundles = @"UP";
    }
    else if ([purchaseManager unlimitedVideos]) {
        bundles = @"UV";
    }

    NSString *bundlesString = [NSString stringWithFormat:@"Bundles: %@", bundles];
    signString = [signString stringByAppendingString:bundlesString];

    return signString;
}


#pragma mark - Switch to Plus version

- (BOOL)plusVersionInstalled {
    NSURL *URLToOpen = [NSURL URLWithString:PB_APP_URL_SCHEME];
    return [[UIApplication sharedApplication] canOpenURL:URLToOpen];
}

- (void)openPlusVersion {
    NSURL *URLToOpen = [NSURL URLWithString:PB_APP_URL_SCHEME];
    if ([self plusVersionInstalled]) {
        [[UIApplication sharedApplication] openURL:URLToOpen];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }

    [self openPlusVersion];
}


#pragma mark - Ad

- (void)unarchiveAd {
    @autoreleasepool {
        NSString *adFilename = PB_LITE_VERSION_AD_FILENAME;
        NSString *adFilePath = PBApplicationLibraryDirectoryAdd(adFilename);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:adFilePath] == NO) {
            NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"lite_ad" ofType:@"blob"];
            if (resourcePath) {
                [fileManager copyItemAtPath:resourcePath
                                     toPath:adFilePath
                                      error:nil];
                
                NSLog(@"Extracted Lite Promo");
            }
        }
        
        [self requestNewAdVersion];
    }
}

- (void)requestNewAdVersion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    RDHTTPRequest *versionRequest = [RDHTTPRequest getRequestWithURLString:PB_LITE_VERSION_AD_VERSION_URL];
    [versionRequest startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.statusCode == 200) {
            NSString *remoteVerstionString = response.responseString;
            NSInteger remoteVersion = [remoteVerstionString integerValue];
            NSInteger localVersion = [defaults integerForKey:kPBLiteAdVersion];
            
            if (localVersion < remoteVersion) {
                NSLog(@"Remote ad updated. Going to download");
                RDHTTPRequest *adRequest = [RDHTTPRequest getRequestWithURLString:PB_LITE_VERSION_AD_IMAGE_URL];
                [adRequest startWithCompletionHandler:^(RDHTTPResponse *response) {
                    if (response.statusCode == 200 && response.responseData.length > 0) {
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSString *adFilePath = PBApplicationLibraryDirectoryAdd(PB_LITE_VERSION_AD_FILENAME);
                        [fileManager removeItemAtPath:adFilePath error:nil];
                        [fileManager createFileAtPath:adFilePath
                                             contents:response.responseData
                                           attributes:nil];
                        
                        [defaults setInteger:remoteVersion forKey:kPBLiteAdVersion];
                        [defaults synchronize];
                        
                        NSLog(@"Ad image were successfully updated");
                    } else {
                        NSLog(@"Failed to get ad file: %@, %@, statusCode: %d", response.error, response.httpError, response.statusCode);
                    }
                }];
            } else {
                NSLog(@"Local ad is the latest version");
            }
        } else {
            NSLog(@"Failed to get new ad version: %@, %@, statusCode: %d", response.error, response.httpError, response.statusCode);
        }
    }];
}


#pragma mark - In-App

- (BOOL)isFullVersion {
    return ([[PBPurchaseManager sharedManager] fullVersion]);
}


#pragma mark - Presenting Send UI

- (void)offerPurchaseIfNeeded {
    if ([self isFullVersion]) {
        [self proceedAction];
        return;
    }
    
    UIViewController *controller = [[self class] purchaseViewControllerWithDelegate:self];
    if (nil == controller) {
        [self proceedAction];
        return;
    }

    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.viewController presentViewController:controller
                                      animated:YES
                                    completion:^{

                                    }];
}

- (void)actionSheetDidSelectSendToIosDevice:(id)userInfo {
    _actionSheetDidSelectSendToIosDevice = YES;
    _actionSheetUserInfo = userInfo;

    [self offerPurchaseIfNeeded];
}

- (void)actionSheetDidSelectSendToDesktopComputer:(id)userInfo {
    _actionSheetDidSelectSendToIosDevice = NO;
    _actionSheetUserInfo = userInfo;

    [self offerPurchaseIfNeeded];
}

- (void)proceedAction {
    if (_actionSheetDidSelectSendToIosDevice) {
        [super actionSheetDidSelectSendToIosDevice:_actionSheetUserInfo];
    } else {
        [super actionSheetDidSelectSendToDesktopComputer:_actionSheetUserInfo];
    }

    _actionSheetUserInfo = nil;
}

// Returns nil if there is no need to present Purchase screen
+ (PBPurchaseViewController *)purchaseViewControllerWithDelegate:(id<PBPurchaseViewControllerDelegate>)delegate {
    if ([[PBPurchaseManager sharedManager] fullVersion]) {
        return nil;
    }

    if ([[PBPurchaseManager sharedManager] unlimitedPhotos] &&
        [[PBPurchaseManager sharedManager] unlimitedVideos])
    {
        return nil;
    }


    NSArray *selectedAssets = [[PBAssetManager sharedManager] assetUrlList];
    ContentType checkResult = [[PBAssetManager sharedManager] contentTypeForPhotoURLs:selectedAssets];

    BOOL photosAccepted = !(checkResult & PHOTOS_MORE_THAN_MAXIMUM);
    BOOL videosAccepted = !(checkResult & VIDEOS_MORE_THAN_MAXIMUM);
    BOOL videosDurationAccepted = !(checkResult & VIDEOS_DURATION_MORE_THAN_MAXIMUM);

    if (photosAccepted && videosAccepted && videosDurationAccepted) {
        return nil;
    }


    PBPurchaseViewController *controller = [[PBPurchaseViewController new] autorelease];
    controller.delegate = delegate;

    if ((checkResult & VIDEOS_MORE_THAN_MAXIMUM) &&
        [[PBAssetManager sharedManager] selectedPhotosNumber] <= 0) {
        
        controller.continueButtonTitle =
            NSLocalizedString(@"Cancel", @"Title for cancel button on Purchase screen");
    }

    controller.fullVersionPriceString = [[PBPurchaseManager sharedManager] upgradePriceString];

    if ([[PBPurchaseManager sharedManager] isUnlimitedPhotosVersionPurchased]) {
        controller.unlimitedPhotosVersionPriceString = NSLocalizedString(@"Purchased", @"Title for buy button");
        [controller disableBuyUnlimitedPhotosButton];
    }
    else {
        controller.unlimitedPhotosVersionPriceString = [[PBPurchaseManager sharedManager] unlimitedPhotosVersionPriceString];
    }

    if ([[PBPurchaseManager sharedManager] isUnlimitedVideosVersionPurchased]) {
        controller.unlimitedVideosVersionPriceString = NSLocalizedString(@"Purchased", @"Title for buy button");
        [controller disableBuyUnlimitedVideosButton];
    }
    else {
        controller.unlimitedVideosVersionPriceString = [[PBPurchaseManager sharedManager] unlimitedVideosVersionPriceString];
    }

    if (![[PBPurchaseManager sharedManager] canMakePayments]) {
        [controller disableBuyFullVersionButton];
        [controller disableBuyUnlimitedPhotosButton];
        [controller disableBuyUnlimitedVideosButton];
    }

    if (checkResult & PHOTOS_MORE_THAN_MAXIMUM) {
        [controller setMaxPhotosHiglighted:YES];
    }

    if (checkResult & VIDEOS_MORE_THAN_MAXIMUM) {
        [controller setMaxVideosHiglighted:YES];
    }

    if (checkResult & VIDEOS_DURATION_MORE_THAN_MAXIMUM) {
        [controller setMaxVideoDurationHiglighted:YES];
    }


    return controller;
}

+ (BOOL)shouldProceedAfterOfferPurchase {
    BOOL shouldProceed = YES;

    // Allow user to send few photos for free

    NSArray *selectedPhotos = [[PBAssetManager sharedManager] assetUrlList];
    NSUInteger checkResult = [[PBAssetManager sharedManager] contentTypeForPhotoURLs:selectedPhotos];

    if ((checkResult & VIDEOS_MORE_THAN_MAXIMUM) &&
        [[PBAssetManager sharedManager] selectedPhotosNumber] <= 0) {
        
        shouldProceed = NO;
    }

    return shouldProceed;
}

- (void)showOpenPlusVersionAlertView {
    NSString *title = NSLocalizedString(@"You have ImageTrasnfer Plus installed.", @"You have ImageTrasnfer Plus installed.");
    NSString *message = NSLocalizedString(@"Do you want to launch it?", @"Do you want to launch it?");
    NSString *cancelButtonTitle = NSLocalizedString(@"No, Thanks", @"No, Thanks");
    NSString *openButtonTitle = NSLocalizedString(@"Launch Now", @"Launch Now");

    UIAlertView *alert =
        [[[UIAlertView alloc]
            initWithTitle:title
            message:message
            delegate:self cancelButtonTitle:cancelButtonTitle
            otherButtonTitles:openButtonTitle, nil]
        autorelease];
    
    [alert show];
}


#pragma mark - Purchase ViewController Delegate

- (void)purchaseViewControllerDidTapRestorePurchasedProductsButton:(UIViewController *)viewController {
    [[PBPurchaseManager sharedManager] restorePurchasedProducts];
}

- (void)purchaseViewControllerDidTapBuyFullVersionButton:(UIViewController *)viewController {
    [[PBPurchaseManager sharedManager] buyFullVersion];
}

- (void)purchaseViewControllerDidTapBuyUnlimitedPhotosVersionButton:(UIViewController *)viewController {
    [[PBPurchaseManager sharedManager] buyUnlimitedPhotosVersion];
}

- (void)purchaseViewControllerDidTapBuyUnlimitedVideosVersionButton:(UIViewController *)viewController {
    [[PBPurchaseManager sharedManager] buyUnlimitedVideosVersion];
}

- (void)purchaseViewControllerDidTapContinueButton:(UIViewController *)viewController {
    [self.viewController dismissViewControllerAnimated:YES
                                            completion:^{
                                                if ([[self class] shouldProceedAfterOfferPurchase]) {
                                                    [self proceedAction];
                                                }
                                            }];
}


#pragma mark - PurchaseManager notifications

- (void)registerOnPurchaseManagerNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(purchaseManagerDidUnlockProduct:)
                               name:PBPurchaseManagerDidUnlockProduct
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(purchaseManagerDidRestorePurchase:)
                               name:PBPurchaseManagerDidRestorePurchase
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(purchaseManagerDidFailToUnlockProduct:)
                               name:PBPurchaseManagerDidFailToUnlockProduct
                             object:nil];
}

- (void)purchaseManagerDidUnlockProduct:(NSNotification *)notification {
    [self setTransferLimitations];
    [[PBAssetManager sharedManager] restartPreparingAssets];
    [self.viewController dismissViewControllerAnimated:YES
                                            completion:^{
                                                [self proceedAction];
                                            }];
}

- (void)purchaseManagerDidRestorePurchase:(NSNotification *)notification {
    [self setTransferLimitations];
    [[PBAssetManager sharedManager] restartPreparingAssets];

    //show the "You've already bought the full version" alert to make user happy.
    
    [self.viewController dismissViewControllerAnimated:YES
                                            completion:^{
                                                [self proceedAction];
                                            }];
}

- (void)purchaseManagerDidFailToUnlockProduct:(NSNotification *)notification {
    BOOL userCancelled = NO;
    
    NSError *error = notification.object;
    if ([error.domain isEqualToString:SKErrorDomain]) {
        userCancelled = error.code == SKErrorPaymentCancelled;
    }
    
    if (!userCancelled) {
        PBAlertOK(nil, [error localizedDescription]);
    }
    
    
    if ([self.viewController.presentedViewController respondsToSelector:@selector(enableButtons)]) {
        [self.viewController.presentedViewController performSelector:@selector(enableButtons)];
    }
    
    NSLog(@"Some crap has happened");
}

@end
