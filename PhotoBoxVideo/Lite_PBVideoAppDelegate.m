//
//  Lite_PBVideoAppDelegate.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/16/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "Lite_PBVideoAppDelegate.h"
#import "PBVideoAppDelegate.h"
#import "PBPurchaseManager.h"
#import "PBPurchaseViewController.h"
#import "PBAssetManager.h"
#import "PBVideoConnectViewController.h"
#import "PBNearbyDeviceListViewController.h"
#import "AppMessages.h"

@implementation Lite_PBVideoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [super application:application didFinishLaunchingWithOptions:launchOptions];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque
                                                animated:NO];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
        APPMESS_SDK_APP_ID, @"amApplicationCode",
        APPMESS_SDK_APP_KEY, @"amSecretKey",
        AM_SERVER_URL, @"amServerUrl",
        [NSNumber numberWithBool:YES], @"showAutomatically",
        nil];

    [AppMessages invokeWithParams:params];


    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [super applicationWillEnterForeground:application];

    [AppMessages restoreFromBackground];
}

+ (id)rootViewController {
    return [PBVideoAppDelegate rootViewController];
}

+ (void)setupToolbarAppearence:(id)toolbarToConfigure {
    [PBVideoAppDelegate setupToolbarAppearence:toolbarToConfigure];
}

+ (void)setupAppearance {
    [PBVideoAppDelegate setupAppearance];
}

+ (NSString *)backgroundTaskNotificationMessage {
    return NSLocalizedString(@"Hury up! Go back to Video Transfer to continue data transfer!", @"Push notification text");
}

+ (PBPurchaseViewController *)purchaseViewControllerWithDelegate:(id<PBPurchaseViewControllerDelegate>)delegate {
    PBPurchaseViewController *controller = [super purchaseViewControllerWithDelegate:delegate];

    if (nil == controller) {
        return nil;
    }

    controller.continueButtonTitle =
        NSLocalizedString(@"Limited transfer", @"Title for continue button on Purchase screen");
    
    return controller;
}

+ (BOOL)shouldProceedAfterOfferPurchase {
    return YES;
}

- (void)showOpenPlusVersionAlertView {
    NSString *title = NSLocalizedString(@"You have VideoTrasnfer Plus installed.", @"AlertView title");
    NSString *message = NSLocalizedString(@"Do you want to launch it?", @"AlertView message, propose lauch full version of application");
    NSString *cancelButtonTitle = NSLocalizedString(@"No, Thanks", @"Declain button title");
    NSString *openButtonTitle = NSLocalizedString(@"Launch Now", @"Launch button title");

    UIAlertView *alert =
        [[[UIAlertView alloc]
            initWithTitle:title
            message:message
            delegate:self cancelButtonTitle:cancelButtonTitle
            otherButtonTitles:openButtonTitle, nil]
        autorelease];

    [alert show];
}


#pragma mark - Presenting Send UI

- (void)proceedAction {
    if (_actionSheetDidSelectSendToIosDevice) {
        [self presentNearbyDevicesListViewController:_actionSheetUserInfo];
    }
    else {
        [self presentDesktopConnectViewController:_actionSheetUserInfo];
    }

    _actionSheetUserInfo = nil;
}


#pragma mark - ViewController presenting

- (void)presentDesktopConnectViewController:(id)userInfo {
    UINavigationController *navigationController = userInfo;

    // TODO: Get rid of it!!! This is caused by PBViewController
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        PBVideoConnectViewController *vc =
            [[[PBVideoConnectViewController alloc]
                initWithNibName:@"PBVideoConnectViewController"
                bundle:nil]
            autorelease];

        vc.sendAssetsUI = YES;

        vc.modalPresentationStyle = UIModalPresentationFormSheet;
        [navigationController presentViewController:vc
                                           animated:YES
                                         completion:nil];
    }
    else {
        PBConnectViewController *vc =
            [[[PBConnectViewController alloc]
                initWithNibName:@"PBConnectViewController"
                bundle:nil]
            autorelease];

        vc.sendAssetsUI = YES;
        
        [navigationController pushViewController:vc animated:YES];
    }
}

- (void)presentNearbyDevicesListViewController:(id)userInfo {
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


    UINavigationController *navigationController = userInfo;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
        [navigationController presentViewController:vc
                                           animated:YES
                                         completion:^{
                                             vc.view.superview.layer.masksToBounds = YES;
                                             vc.view.superview.layer.cornerRadius = 8.0;
                                         }];
    }
    else {
        [navigationController pushViewController:vc animated:YES];
    }
}


@end
