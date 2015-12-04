//
//  Lite-PBAppDelegate.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 18/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBAppDelegate.h"

@class PBPurchaseViewController;
@protocol PBPurchaseViewControllerDelegate;

@interface Lite_PBAppDelegate : PBAppDelegate {
    BOOL _actionSheetDidSelectSendToIosDevice;
    id _actionSheetUserInfo;
}

// Returns nil if there is no need to present Purchase screen
+ (PBPurchaseViewController *)purchaseViewControllerWithDelegate:(id<PBPurchaseViewControllerDelegate>)delegate;
+ (BOOL)shouldProceedAfterOfferPurchase;
- (void)showOpenPlusVersionAlertView;
- (void)proceedAction;
- (void)setTransferLimitations;

@end
