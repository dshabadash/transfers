//
//  PBPurchaseViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 18/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PBPurchaseViewControllerDelegate;

@interface PBPurchaseViewController : PBViewController

@property (assign, nonatomic) NSObject<PBPurchaseViewControllerDelegate> *delegate;

@property (copy, nonatomic) NSString *fullVersionPriceString;
@property (copy, nonatomic) NSString *unlimitedPhotosVersionPriceString;
@property (copy, nonatomic) NSString *unlimitedVideosVersionPriceString;
@property (copy, nonatomic) NSString *continueButtonTitle;
@property (copy, nonatomic) NSString *message;
@property (copy, nonatomic) NSAttributedString *proposal;

+ (UIColor *)priceLabelTextColor;
- (void)disableBuyFullVersionButton;
- (void)disableBuyUnlimitedPhotosButton;
- (void)disableBuyUnlimitedVideosButton;
- (void)disableButtons;
- (void)enableButtons;
- (void)setMaxPhotosHiglighted:(BOOL)highlighted;
- (void)setMaxVideosHiglighted:(BOOL)highlighted;
- (void)setMaxVideoDurationHiglighted:(BOOL)highlighted;

- (IBAction)buyFullVersionButtonTapped:(id)sender;
- (IBAction)buyUnlimitedPhotosVersionButtonTapped:(id)sender;
- (IBAction)buyUnlimitedVideosVersionButtonTapped:(id)sender;
- (IBAction)continueButtonTapped:(id)sender;

@end

@protocol PBPurchaseViewControllerDelegate <NSObject>
- (void)purchaseViewControllerDidTapRestorePurchasedProductsButton:(UIViewController *)viewController;
- (void)purchaseViewControllerDidTapBuyFullVersionButton:(UIViewController *)viewController;
- (void)purchaseViewControllerDidTapBuyUnlimitedPhotosVersionButton:(UIViewController *)viewController;
- (void)purchaseViewControllerDidTapBuyUnlimitedVideosVersionButton:(UIViewController *)viewController;
- (void)purchaseViewControllerDidTapContinueButton:(UIViewController *)viewController;
//- (void)purchaseViewController:(PBPurchaseViewController *)viewController;
@end
