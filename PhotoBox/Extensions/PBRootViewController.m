//
//  PBRootViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 11/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBRootViewController.h"

#import "PBHomeScreenTopView.h"
#import "PBHomeScreenBottomView.h"
#import "PBNoWiFiView.h"
#import "PBAssetMultiselectionView.h"
#import "PBNoAssetsLibraryAccessView.h"

#import "PBAssetManager.h"
#import "RSReachability.h"
#import "PBMongooseServer.h"
#import "PBAssetUploader.h"

#import "PBTransferProgressViewController.h"
#import "PBHelpViewController.h"

#import "PBAssetsGroupListViewController.h"
#import "PBAssetListViewController.h"
#import "PBImportDidFailedViewController.h"

#import "PBNearbyDeviceListViewController.h"
#import "PBConnectViewController.h"
#import "PBCommonUploadToViewController.h"
#import "PBAppDelegate.h"

@interface PBRootViewController () <PBNoWiFiViewDelegate> {
    BOOL _topViewControllerIsActive;
    PBNoWiFiView *_noWiFiView;
    UIView *_noAssetsLibraryAccessView;
}

//@property (retain, nonatomic) ALAssetsGroup *assetsGroup;

@end

@implementation PBRootViewController

+ (id)sharedController {
    static id sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self class] new];
    });
    return sharedController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _topViewControllerIsActive = YES;
        _noWiFiView = nil;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_topView release];
    _topView = nil;

    [_bottomView release];
    _bottomView = nil;

    [super dealloc];
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.multipleTouchEnabled = NO;

    [self addChildViewController:_topViewController];
    [_topViewController didMoveToParentViewController:self];
    
    [self addChildViewController:_bottomViewController];
    [_bottomViewController didMoveToParentViewController:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view insertSubview:_topViewController.view atIndex:0];
    });
    
   // [self presentStartCoverViewsAnimated:NO];
    [self registerOnNotifications];

    //force UI update
    [self reachabilityStatusChanged:nil];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
}

- (void)updateZIndexes {
    [self.view bringSubviewToFront:_noWiFiView];
    [self.view bringSubviewToFront:_noAssetsLibraryAccessView];
    [self.view bringSubviewToFront:_topView];
    [self.view bringSubviewToFront:_bottomView];
}


#pragma mark - Cover Views
//
//- (void)presentStartCoverViewsAnimated:(BOOL)animated completion:(dispatch_block_t)completion {
//    [self disableGestureRecognizersInCoverView:self.topView];
//    [self disableGestureRecognizersInCoverView:self.bottomView];
//
//    CGRect bounds =  self.view.bounds;
//    CGSize size = bounds.size;
//    CGFloat width = size.width;
//    CGFloat height = size.height;
//
//    CGRect topViewFrame = CGRectMake(0, 0, width, self.view.bounds.size.height/2);//self.topView.bounds.size.height);
//    CGRect bottomViewFrame;
//
//    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
//        CGFloat hh = round(height / 2);
//        topViewFrame = CGRectMake(0, 0, width, hh);
//        bottomViewFrame = CGRectMake(0, hh, width, hh);
//    }
//    else {
//        CGFloat bottomViewHeight = self.view.bounds.size.height - topViewFrame.size.height; //self.topView.bounds.size.height;
//        bottomViewFrame = CGRectMake(0, topViewFrame.size.height, width, bottomViewHeight);
//    }
//
//    
//    if (animated) {
//        CGRect initialTopViewFrame = topViewFrame;
//        initialTopViewFrame.origin.y = -initialTopViewFrame.size.height;
//        
//        CGRect initialBottomViewFrame = bottomViewFrame;
//        initialBottomViewFrame.origin.y = height;
//        
//        _topView.frame = initialTopViewFrame;
//        _bottomView.frame = initialBottomViewFrame;
//    }
//
//    if (_topView.superview != self.view) {
//        [self.view addSubview:_topView];
//    }
//
//    if (_bottomView.superview != self.view) {
//        [self.view addSubview:_bottomView];
//    }
//
//    [_topView setHidden:NO];
//    [_bottomView setHidden:NO];
//
//    if (animated) {
//        [UIView animateWithDuration:animated ? 0.3 : 0
//                         animations:^{
//                             _topView.frame = topViewFrame;
//                             _bottomView.frame = bottomViewFrame;
//                         }
//                         completion:^(BOOL finished) {
//                             [self enableGestureRecognizersInCoverView:self.topView];
//                             [self enableGestureRecognizersInCoverView:self.bottomView];
//
//                             if (completion) {
//                                 completion();
//                             }
//                         }];
//    }
//    else {
//        _topView.frame = topViewFrame;
//        _bottomView.frame = bottomViewFrame;
//
//        [self enableGestureRecognizersInCoverView:self.topView];
//        [self enableGestureRecognizersInCoverView:self.bottomView];
//
//        if (completion) {
//            completion();
//        }
//    }
//}
//
//- (void)presentStartCoverViewsAnimated:(BOOL)animated {
//    [self presentStartCoverViewsAnimated:animated completion:nil];
//}
//
//- (void)dismissStartCoverViewsAnimated {
//    [self dismissStartCoverViewsAnimated:YES];
//}
//
//- (void)dismissStartCoverViewsAnimated:(BOOL)animated {
//    [self disableGestureRecognizersInCoverView:self.topView];
//    [self disableGestureRecognizersInCoverView:self.bottomView];
//
//    CGRect bounds = self.view.bounds;
//    CGSize size = bounds.size;
//    CGFloat width = size.width;
//    CGFloat height = size.height;
//    
//    CGRect topViewFrame = CGRectMake(0, 0, width, self.topView.bounds.size.height);
//    
//    CGFloat bottomViewHeight = self.view.bounds.size.height - self.topView.bounds.size.height;
//    CGRect bottomViewFrame = CGRectMake(0, self.topView.bounds.size.height, width, bottomViewHeight);
//    
//    CGRect finalTopViewFrame = topViewFrame;
//    finalTopViewFrame.origin.y = -finalTopViewFrame.size.height;
//    
//    CGRect finalBottomViewFrame = bottomViewFrame;
//    finalBottomViewFrame.origin.y = height;
//    
//    [UIView animateWithDuration:animated ? 0.3 : 0
//                     animations:^{
//                         _topView.frame = finalTopViewFrame;
//                         _bottomView.frame = finalBottomViewFrame;
//                     }
//                     completion:^(BOOL finished) {
//                         [_topView setHidden:YES];
//                         [_bottomView setHidden:YES];
//
//                         [self enableGestureRecognizersInCoverView:self.topView];
//                         [self enableGestureRecognizersInCoverView:self.bottomView];
//                     }];
//    
//}
//
//- (void)disableGestureRecognizersInCoverView:(UIView *)coverView {
//    [coverView setUserInteractionEnabled:NO];
//    for (UIGestureRecognizer *recognizer in coverView.gestureRecognizers) {
//        recognizer.enabled = NO;
//    }
//}
//
//- (void)enableGestureRecognizersInCoverView:(UIView *)coverView {
//    [coverView setUserInteractionEnabled:YES];
//    for (UIGestureRecognizer *recognizer in coverView.gestureRecognizers) {
//        recognizer.enabled = YES;
//    }
//}


#pragma mark - Delegate methods

- (void)topViewSelected {
    [self setTopViewControllerActive:YES animated:NO];
}

- (void)bottomViewSelected {
    [self setTopViewControllerActive:NO animated:NO];
}

- (void)toolbarToggleButtonTapped {
    [self toggleViewController];
}

//- (void)coverViewWillBeginDragging:(UIView *)coverView {
//    if (coverView == self.topView) {
//        [self disableGestureRecognizersInCoverView:self.bottomView];
//    }
//    else if (coverView == self.bottomView) {
//        [self disableGestureRecognizersInCoverView:self.topView];
//    }
//}


#pragma mark - Managing child view controllers

- (void)toggleViewController {
    [self setTopViewControllerActive:!_topViewControllerIsActive animated:YES];
}

- (void)setTopViewControllerActive:(BOOL)active animated:(BOOL)animated {
    if (self.view.userInteractionEnabled == NO) {
        //avoid selecting both top and bottom cover views
        return;
    }

    _topViewControllerIsActive = active;

    UIViewController *fromViewController;
    UIViewController *toViewController;

    CGRect bounds = self.view.bounds;
    CGSize size = bounds.size;
    //    CGFloat width = size.width;
    CGFloat height = size.height;

    CGRect initialFromFrame = bounds;
    CGRect initialToFrame = bounds;
    CGRect finalFromFrame = bounds;
    CGRect finalToFrame = bounds;

    if (_topViewControllerIsActive) {
        fromViewController = _bottomViewController;
        toViewController = _topViewController;
    } else {
        fromViewController = _topViewController;
        toViewController = _bottomViewController;
    }

    initialToFrame.origin.y = height;
    finalFromFrame.origin.y = -height;

    fromViewController.view.frame = initialFromFrame;
    toViewController.view.frame = initialToFrame;

    [self updateZIndexes];

    //avoid selecting both top and bottom cover views
    self.view.userInteractionEnabled = NO;

    [self transitionFromViewController:fromViewController
                      toViewController:toViewController
                              duration:animated ? 0.3 : 0.0
                               options:UIViewAnimationOptionCurveEaseInOut
                            animations:^{
                                fromViewController.view.frame = finalFromFrame;
                                toViewController.view.frame = finalToFrame;
                            }
                            completion:^(BOOL finished) {
                                [self updateZIndexes];

                                //avoid selecting both top and bottom cover views
                                self.view.userInteractionEnabled = YES;
                            }];
    
    [self updateZIndexes];
    
}

- (void)presentMultiselectionTipView {
    PBAssetMultiselectionView *hintView = [PBAssetMultiselectionView view];
    hintView.frame = self.view.bounds;
    hintView.alpha = 0;
    [self.view addSubview:hintView];

    [UIView animateWithDuration:0.3
                     animations:^{
                         hintView.alpha = 1;
                     }];
}

- (void)presentHelpViewController {
    PBHelpViewController *defaultHelpViewController = [[[PBHelpViewController alloc] init] autorelease];
    [self presentHelpViewController:defaultHelpViewController animated:YES];
}

- (void)presentHelpViewController:(UIViewController *)helpViewController animated:(BOOL)animated {
    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:helpViewController] autorelease];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nc
                       animated:animated
                     completion:nil];
}

- (void)dismissNoWifiView {
    [UIView animateWithDuration:0.3
                     animations:^{
                         _noWiFiView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [_noWiFiView removeFromSuperview];
                         _noWiFiView = nil;
                     }];
}

- (void)noWifiViewDidTapOkButton:(PBNoWiFiView *)noWifiView {
    if ([[PBAssetManager sharedManager] assetCount]) {
        [self dismissNoWifiView];
    } else {
       // [self presentStartCoverViewsAnimated:YES];
    }
}

- (void)presentNoAssetsLibraryAccessView {
    if (_noAssetsLibraryAccessView == nil) {
        _noAssetsLibraryAccessView = [PBNoAssetsLibraryAccessView view];
        _noAssetsLibraryAccessView.frame = self.view.bounds;
        [self.view addSubview:_noAssetsLibraryAccessView];

        [self updateZIndexes];
    }
}

- (void)dismissNoAssetsLibraryAccessView {
    if (_noAssetsLibraryAccessView) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             _noAssetsLibraryAccessView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             [_noAssetsLibraryAccessView removeFromSuperview];
                             _noAssetsLibraryAccessView = nil;
                         }];
    }
}

- (void)presentImportFailedViewController {

    void (^presentingBlock)(void) = ^{
        PBImportDidFailedViewController *controller =
            [[PBImportDidFailedViewController alloc] initWithNibName:@"PBImportDidFailedViewController"
                                                              bundle:nil];

        [controller addTarget:self
            cancelAction:@selector(dismissImportFailedViewController)];

        controller.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:controller
                           animated:YES
                         completion:^{}];
    };


    if (nil != self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:^{
            presentingBlock();
        }];
    }
    else {
        presentingBlock();
    }
}

- (void)dismissImportFailedViewController {
    if (nil != self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:^{}];
    }
}


#pragma mark - Notifications

- (void)registerOnNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(reachabilityStatusChanged:)
                               name:kRSReachabilityChangedNotification
                             object:nil];


    [notificationCenter addObserver:self
                           selector:@selector(progressUpdated:)
                               name:PBMongooseServerPostBodyProgressDidUpdateNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(progressUpdated:)
                               name:PBMongooseServerGetBodyProgressDidUpdateNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(progressUpdated:)
                               name:PBAssetUploaderUploadProgressDidUpdateNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(presentNoAssetsLibraryAccessView)
                               name:PBAssetManagerFailedToGetAccessToAssetsLibraryNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(dismissNoAssetsLibraryAccessView)
                               name:PBAssetManagerDidGetAccessToAssetsLibraryNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(presentImportFailedViewController)
                               name:PBAssetManagerDidFailedToImportAssetToLibrary
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(finishedNotificationReceived)
                               name:PBMongooseServerGetBodyProgressDidFinishNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(noWiFiView)
                               name:@"NoWIFiConnectionForSending"
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(noInternetView)
                               name:@"NoInternetConnectionForSending"
                             object:nil];
    

}


-(void)noWiFiView {
    [self showNoWiFiView:YES];
    
}
-(void)noInternetView {
    [self showNoWiFiView:NO];
    
}


-(void)finishedNotificationReceived {
    [self performSelector:@selector(checkIfFinishedNotificationReceived)
               withObject:nil
               afterDelay:5.0];
}

-(void)checkIfFinishedNotificationReceived {
    if (self.presentedViewController && [self.presentedViewController isKindOfClass:[PBTransferProgressViewController class]]) {
        [(PBTransferProgressViewController *)self.presentedViewController checkIfFinishedNotificationReceived];
    }
    
}


- (void)progressUpdated:(NSNotification *)notification {
    
    void (^showProgressViewControllerAnimated)(BOOL);
    showProgressViewControllerAnimated = ^(BOOL animated){
        NSNumber *progressNum = notification.userInfo[kPBProgress];
        CGFloat progress = [progressNum floatValue];
        
        
        PBTransferProgressViewController *vc = [[PBTransferProgressViewController new] autorelease];
        vc.initialProgress = progress;
        
        NSLog(@"%@", notification.userInfo[kPBDeviceName]);
        vc.deviceName = notification.userInfo[kPBDeviceName];
        vc.deviceType = notification.userInfo[kPBDeviceType];
        
        if ([notification.name isEqualToString:PBMongooseServerPostBodyProgressDidUpdateNotification]) {
            vc.transferDirection = PBTransferDirectionReceive;
        } else {
            vc.transferDirection = PBTransferDirectionSend;
        }
        
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:vc
                           animated:animated
                         completion:nil];
    };
    
    UIViewController *presentedViewController = self.presentedViewController;
    if (self.presentedViewController == nil) {
        showProgressViewControllerAnimated(YES);
    } else {
        if ([presentedViewController isKindOfClass:[PBTransferProgressViewController class]] == NO) {
            [self dismissViewControllerAnimated:NO
                                     completion:^{
                                         showProgressViewControllerAnimated(NO);
                                     }];
        }
    }

}

- (void)reachabilityStatusChanged:(NSNotification *)notification {
    if (PBGetLocalIP() || ([[RSReachability RSReachabilityForInternetConnection] currentRSReachabilityStatus] != RSNotReachable)) {
        [self dismissNoWifiView];
    }
    else {
        UINavigationController *presentedViewController = (UINavigationController *)self.topViewController;
        
       // NSString *className = NSStringFromClass([presentedViewController.topViewController class]);
        
        if (([presentedViewController.topViewController isKindOfClass:[PBTransferProgressViewController class]]) || ([presentedViewController.topViewController isKindOfClass:[PBNearbyDeviceListViewController class]]) || ([presentedViewController.topViewController isKindOfClass:[PBConnectViewController class]])) {

            [self showNoWiFiView:YES];
        }
        /*     else if ([[RSReachability RSReachabilityForInternetConnection] currentRSReachabilityStatus] == RSNotReachable) {
            PBAppDelegate *appDelegate = (PBAppDelegate *)[[UIApplication sharedApplication] delegate];
            if ([appDelegate isWorkingWithCloud]) {
                [self showNoWiFiView:NO];
            }
        }*/
    }
}

-(void)showNoWiFiView:(BOOL)showWiFiAnimation {
    if (_noWiFiView == nil) {
        _noWiFiView = [PBNoWiFiView view];
        _noWiFiView.frame = self.view.bounds;
        _noWiFiView.delegate = self;
        [_noWiFiView setNoWiFiAnimation:showWiFiAnimation];
        [self.view addSubview:_noWiFiView];
        
        [self updateZIndexes];
        
        if (_topViewControllerIsActive) {
            UINavigationController *nc = (UINavigationController *)_topViewController;
            BOOL albumList = [nc.topViewController isKindOfClass:[PBAssetsGroupListViewController class]];
            BOOL assetList = [nc.topViewController isKindOfClass:[PBAssetListViewController class]];
          /*  if (!albumList && !assetList) {
                _noWiFiView.okButton.hidden = YES;
            }*/
        }
    }
    
}


@end
