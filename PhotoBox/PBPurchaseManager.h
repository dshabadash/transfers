//
//  PBPurchaseManager.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 18/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PBPurchaseManagerDidUnlockProduct;
extern NSString * const PBPurchaseManagerDidRestorePurchase;
extern NSString * const PBPurchaseManagerDidFailToUnlockProduct;
extern NSString * const PBPurchaseManagerErorDomain;

@interface PBPurchaseManager : NSObject
+ (id)sharedManager;

- (BOOL)canMakePayments;

- (NSString *)upgradePriceString;
- (NSString *)unlimitedPhotosVersionPriceString;
- (NSString *)unlimitedVideosVersionPriceString;

- (void)buyFullVersion;
- (void)buyUnlimitedPhotosVersion;
- (void)buyUnlimitedVideosVersion;
- (void)restorePurchasedProducts;

- (BOOL)isFullVersionUnlocked; //YES if user have bought 'Upgrade to Plus' In-Ap
- (BOOL)isUnlimitedPhotosVersionPurchased;
- (BOOL)isUnlimitedVideosVersionPurchased;

- (void)unlockAdminFullVersion; //DANGER: do not unlock full version accidentally or you wouldn't make money :)
- (void)deactivateAdminFullVersion; //This clears full version saved value. However user always may restore In-App purchase
- (BOOL)isAdminFullVersionUnlocked; //YES if admin has granted full version

- (void)unlockAdminUnlimitedPhotosVersion;
- (void)deactivateAdminUnlimitedPhotosVersion;
- (BOOL)isAdminUnlimitedPhotosUnlocked;

- (void)unlockAdminUnlimitedVideosVersion;
- (void)deactivateAdminUnlimitedVideosVersion;
- (BOOL)isAdminUnlimitedVideosUnlocked;

- (void)deactivateAllPurchasedProducts;

- (BOOL)fullVersion;
- (BOOL)unlimitedPhotos;
- (BOOL)unlimitedVideos;

@end
