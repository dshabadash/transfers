//
//  PBVideoAppDelegate.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/3/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBVideoAppDelegate.h"
#import "PBNavigationController.h"
#import "PBVideoAssetsGroupListViewController.h"
#import "PBVideoAssetListViewControllerIpad.h"
#import "PBVideoAssetListViewController.h"
#import "PBVideoPhotoBar.h"
#import "PBAssetManager.h"
#import "PBReceiveViewController.h"
#import "PBButtonToolbar.h"
#import "PBVideoHomeScreenTopView.h"
#import "PBHomeScreenBottomView.h"
#import "PBVideoModalControllerFormSheetView.h"
#import "PBVideoConnectViewController.h"
#import "PBNearbyDeviceListViewController.h"

@implementation PBVideoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [super application:application didFinishLaunchingWithOptions:launchOptions];


    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque
                                                animated:NO];

    return YES;
}

+ (PBNavigationController *)topViewController {
    PBNavigationController *sendNavigationController =
        [[[PBNavigationController alloc]
            initWithNavigationBarClass:nil
            toolbarClass:[PBButtonToolbar class]]
        autorelease];

    PBButtonToolbar *toolbar = (PBButtonToolbar *)sendNavigationController.toolbar;
    NSString *buttonTitle = NSLocalizedString(@"Receive video", @"Receive video, bottom toolbar title");
    [toolbar.button setTitle:buttonTitle forState:UIControlStateNormal];

    UIImage *backgroundImage = (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad))
        ? [UIImage imageNamed:@"send_bottom_bar_bg"]
        : [UIImage imageNamed:@"receive_bottom_bar_bg"];

    [toolbar.button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [toolbar.button setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];

    [self setupToolbarAppearence:toolbar];


    BOOL isIphone = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone);
    
    //photoBar
    CGFloat photoBarHeight = isIphone ? 60 : 100;
    PBVideoPhotoBar *photoBar = [[[PBVideoPhotoBar alloc] initWithFrame:CGRectMake(0, 0, 100, photoBarHeight)] autorelease];
    photoBar.alpha = 0;
    sendNavigationController.topToolBar = photoBar;
    
    if (isIphone) {
        PBVideoAssetsGroupListViewController *vc = [[PBVideoAssetsGroupListViewController new] autorelease];
        [sendNavigationController pushViewController:vc animated:NO];
        sendNavigationController.assetsListViewControllerClass = [PBVideoAssetListViewController class];
    }
    else {
        __block PBVideoAssetListViewControllerIpad *vc = [[[PBVideoAssetListViewControllerIpad alloc] initWithAssetsGroup:nil] autorelease];
        [sendNavigationController pushViewController:vc animated:NO];
        
        PBAssetManager *assetManager = [PBAssetManager sharedManager];
        [assetManager savedPhotosAssetsGroupCompletionBlock:^(ALAssetsGroup *assetGroup) {
            [vc setAssetsGroupUrl:[assetGroup valueForProperty:ALAssetsGroupPropertyURL]];
        }];
    }

    return sendNavigationController;
}

+ (PBNavigationController *)bottomViewController {
    PBNavigationController *receiveNavigationController =
        [[[PBNavigationController alloc]
            initWithNavigationBarClass:nil
            toolbarClass:[PBButtonToolbar class]]
         autorelease];

    PBButtonToolbar *toolbar = (PBButtonToolbar *)receiveNavigationController.toolbar;
    NSString *buttonTitle = NSLocalizedString(@"Send video", @"Send video, button title");
    [toolbar.button setTitle:buttonTitle forState:UIControlStateNormal];


    UIImage *backgroundImage = (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad))
        ? [UIImage imageNamed:@"send_bottom_bar_bg"]
        : [UIImage imageNamed:@"receive_bottom_bar_bg"];

    [toolbar.button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [toolbar.button setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];

    [self setupToolbarAppearence:toolbar];

    
    if (!([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
//        [receiveNavigationController.view.layer setMasksToBounds:YES];
//        [receiveNavigationController.view.layer setCornerRadius:4.0];
    }

    PBReceiveViewController *receiveController = [[PBReceiveViewController new] autorelease];
    receiveController.title = NSLocalizedString(@"Receive Video", @"Title for screen ReceiveVideo");
    [receiveNavigationController pushViewController:receiveController animated:NO];
    
    UIImage *cancelButtonImage = [UIImage imageNamed:@"navbar_cancel_icon"];
    UIBarButtonItem *cancelReceiveButton =
        [[[UIBarButtonItem alloc] initWithImage:cancelButtonImage
            style:UIBarButtonItemStyleBordered
            target:receiveController
            action:@selector(cancelButtonTapped:)]
        autorelease];
    
    [receiveController.navigationItem setLeftBarButtonItem:cancelReceiveButton];
    
    return receiveNavigationController;
}

+ (id)rootViewController {
    PBRootViewController *rootVC = [PBRootViewController sharedController];

    PBNavigationController *sendNavigationController = [self topViewController];
    rootVC.topViewController = sendNavigationController;

    PBNavigationController *receiveNavigationController = [self bottomViewController];
    rootVC.bottomViewController = receiveNavigationController;


    NSString *bottomViewNibName = (PBDeviceIs4InchPhone())
        ? @"PBHomeScreenBottomView-568phone"
        : @"PBHomeScreenBottomView";

    PBHomeScreenBottomView *bottomView = [[[NSBundle mainBundle] loadNibNamed:bottomViewNibName] lastObject];
    bottomView.delegate = rootVC;
    rootVC.bottomView = bottomView;

    
    NSString *topViewNibName = (PBDeviceIs4InchPhone())
        ? @"PBHomeScreenTopView-568phone"
        : @"PBHomeScreenTopView";

    PBVideoHomeScreenTopView *topView = [[[NSBundle mainBundle] loadNibNamed:topViewNibName] lastObject];
    topView.delegate = rootVC;
    rootVC.topView = topView;


    return rootVC;
}

+ (void)setupToolbarAppearence:(id)toolbarToConfigure {
    PBButtonToolbar *toolbar = (PBButtonToolbar *)toolbarToConfigure;


    // Switch button
    [toolbar.button addTarget:[PBRootViewController sharedController]
        action:@selector(toolbarToggleButtonTapped)
        forControlEvents:UIControlEventTouchDown];

    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    [toolbar.button.titleLabel setFont:font];

    UIColor *color = [UIColor colorWithRGB:0x636363];
    [toolbar.button setTitleColor:color forState:UIControlStateNormal];
    [toolbar.button setTitleColor:color forState:UIControlStateHighlighted];

    [toolbar.button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [toolbar.button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

    CGSize shadowSize = (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad))
        ? CGSizeZero
        : CGSizeMake(0, 1);

    [toolbar.button.titleLabel setShadowOffset:shadowSize];
}

+ (void)setupAppearance {
    id labelAppearance = [UILabel appearance];
    [labelAppearance setBackgroundColor:[UIColor clearColor]];

    id navbarAppearance = [UINavigationBar appearance];
    [navbarAppearance setBackgroundImage:[UIImage imageNamed:@"navbar_bg"]
                          forBarPosition:UIBarPositionTopAttached
                              barMetrics:UIBarMetricsDefault];
    [navbarAppearance setTintColor:[UIColor whiteColor]];

    NSDictionary *titleAttributes = @{
        UITextAttributeTextShadowColor : [UIColor colorWithRGB:0x862214],
        UITextAttributeTextShadowOffset : [NSValue valueWithCGSize:CGSizeMake(0, 1)],
        UITextAttributeTextColor : [UIColor colorWithRGB:0xffffff],
        UITextAttributeFont : [UIFont fontWithName:@"HelveticaNeue-Bold" size:18]
    };

    [navbarAppearance setTitleTextAttributes:titleAttributes];

    [[PBVideoModalViewNavigationBar appearance] setTintColor:[PBVideoModalViewNavigationBar tintColor]];
    [[PBVideoModalViewNavigationBar appearance] setBackgroundImage:[PBVideoModalViewNavigationBar backgroundImage]
                                                     forBarMetrics:UIBarMetricsDefault];
    
    [[PBVideoModalViewNavigationBar appearance] setTitleTextAttributes:[PBVideoModalViewNavigationBar titleAttributes]];
    [[PBVideoModalViewNavigationBar appearance] setBackgroundImage:nil
                                                     forBarMetrics:UIBarMetricsDefault];

    id bbiAppearance = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationController class], nil];
    NSDictionary *bbiAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [UIColor whiteColor],
                                   UITextAttributeTextColor,
                                   [UIColor whiteColor],
                                   UITextAttributeTextShadowColor, nil];
    
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

+ (NSString *)backgroundTaskNotificationMessage {
    return NSLocalizedString(@"Hury up! Go back to Video Transfer to continue data transfer!", @"Push notification text");
}


#pragma mark - ViewController presenting

- (void)actionSheetDidSelectSendToIosDevice:(id)userInfo {
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

- (void)actionSheetDidSelectSendToDesktopComputer:(id)userInfo {
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

@end
