//
//  PBPurchaseManager.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 18/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PBPurchaseManager.h"
#import "RSReachability.h"

#define kPBPurchaseManagerItemIsPurchased @"ItemIsPurchased"
#define kPBPurchaseManagerItemIsGrantedByAdmin @"ItemIsGrantedByAdmin"

NSString * const PBPurchaseManagerDidUnlockProduct = @"PBPurchaseManagerDidUnlockProduct";
NSString * const PBPurchaseManagerDidRestorePurchase = @"PBPurchaseManagerDidRestorePurchase";
NSString * const PBPurchaseManagerDidFailToUnlockProduct = @"PBPurchaseManagerDidFailToUnlockProduct";
NSString * const PBPurchaseManagerErorDomain = @"PBPurchaseManagerErorDomain";

@interface PBPurchaseManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    NSMutableDictionary *_availableProducts;
}

@property (retain, nonatomic) SKProductsRequest *productsRequest;

@end

@implementation PBPurchaseManager

+ (id)sharedManager {
    static id sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
    });

    return sharedManager;
}

- (BOOL)canMakePayments {
    return [SKPaymentQueue canMakePayments];
}

- (id)init {
    self = [super init];

    if (nil != self) {
        [self logLiteVersionLaunchedEvent];

        _availableProducts = [[NSMutableDictionary dictionaryWithCapacity:0] retain];

        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [self requestProducts];

        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(reachabilityChanged:)
            name:kRSReachabilityChangedNotification
            object:nil];

        NSLog(@"Reachability enabled");
    }

    return self;
}


#pragma mark - Notifications

- (void)reachabilityChanged:(NSNotification *)notification {
    RSReachability *reachability = notification.object;
    BOOL reachable = (reachability.currentRSReachabilityStatus == RSReachableViaWiFi);

    if (reachable &&
        (0 == [_availableProducts count]) &&
        (nil == _productsRequest))
    {
        [self requestProducts];
        NSLog(@"Got connection, requesting product");
    }
}

- (void)sendDidUnlockProductNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBPurchaseManagerDidUnlockProduct
            object:nil];
    });
}

- (void)sendDidRestorePurchaseNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBPurchaseManagerDidRestorePurchase
            object:nil];
    });

}

- (void)sendDidFailToUnlockProductNotificationError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:PBPurchaseManagerDidFailToUnlockProduct
            object:error];
    });
}


#pragma mark - Statistics

- (void)logPurchasedPlusEvent {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //analytics
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger numberOfTimesPhotosWereSent = [defaults integerForKey:kPBNumberOfTimesPhotosWereSent];
        NSInteger numberOfTimesAppWereLaunched = [defaults integerForKey:kPBNumberOfTimesAppWereLaunched];
        NSDictionary *parameters = @{
            @"numberOfTimesPhotosWereSent" : [NSString stringWithInteger:numberOfTimesPhotosWereSent],
            @"numberOfTimesAppWereLaunched": [NSString stringWithInteger:numberOfTimesAppWereLaunched]
        };

        [[CBAnalyticsManager sharedManager] logEvent:@"purchasedPlus" withParameters:parameters];
    }];
}

- (void)logLiteVersionLaunchedEvent {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //analytics
        NSString *liteVersion = @"free";

        if ([self isFullVersionUnlocked]) {
            liteVersion = @"plusInApp";
        }
        else if ([self isAdminFullVersionUnlocked]) {
            liteVersion = @"plusGrantedByAdmin";
        }

        NSDictionary *params = @{@"liteVersion" : liteVersion};

        [[CBAnalyticsManager sharedManager] logEvent:@"liteLaunched" withParameters:params];
    }];
}


#pragma mark - Products Request

- (void)requestProducts {
    NSSet *productIdentifiers = [NSSet setWithArray:@[
                                    PB_PLUS_INAPP_ID,
                                    PB_UNLIMITED_PHOTOS_INAPP_ID,
                                    PB_UNLIMITED_VIDEOS_INAPP_ID]
                                 ];

    self.productsRequest = [[[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers] autorelease];
    _productsRequest.delegate = self;
    [_productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSLog(@"Products request OK");

    [_availableProducts removeAllObjects];

    for (SKProduct *product in [response products]) {
        [_availableProducts setObject:product forKey:product.productIdentifier];
        NSLog(@"Got product: %@", product);
    }

    self.productsRequest = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    self.productsRequest = nil;
    NSLog(@"Products request failed");
}


#pragma mark - Price string formating

- (NSString *)upgradePriceString {
    SKProduct *product = [_availableProducts objectForKey:PB_PLUS_INAPP_ID];
    if (nil == product) {
        return @"";
    }

    return [self priceStringForProduct:product];
}

- (NSString *)unlimitedPhotosVersionPriceString {
    SKProduct *product = [_availableProducts objectForKey:PB_UNLIMITED_PHOTOS_INAPP_ID];
    if (nil == product) {
        return @"";
    }

    return [self priceStringForProduct:product];
}

- (NSString *)unlimitedVideosVersionPriceString {
    SKProduct *product = [_availableProducts objectForKey:PB_UNLIMITED_VIDEOS_INAPP_ID];
    if (nil == product) {
        return @"";
    }

    return [self priceStringForProduct:product];
}

- (NSString *)priceStringForProduct:(SKProduct *)product {
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:product.price];

    return formattedString;
}


#pragma mark - Payment Observer

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        SKPaymentTransactionState state = transaction.transactionState;

        if (state == SKPaymentTransactionStatePurchasing) {
            NSLog(@"Purchasing...");
        } else if (state == SKPaymentTransactionStatePurchased) {
            NSLog(@"Purchased");
            [self purchaseTransaction:transaction];
        } else if (state == SKPaymentTransactionStateRestored) {
            NSLog(@"Restored");
            [self restoreTransaction:transaction];
        } else if (state == SKPaymentTransactionStateFailed) {
            NSLog(@"Failed with error: %@", transaction.error);
            [self failedTransaction:transaction];
        } else {
            NSLog(@"Unknown transaction state");
        }
    }
}

- (void)purchaseTransaction:(SKPaymentTransaction *)transaction {
    NSString *productKey = transaction.payment.productIdentifier;
    [self unlockProductWithKey:productKey];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    [self sendDidUnlockProductNotification];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    [self unlockProductWithKey:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [self sendDidRestorePurchaseNotification];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    [self sendDidFailToUnlockProductNotificationError:transaction.error];
}


#pragma mark - Application version

- (BOOL)fullVersion {
    return ([self isFullVersionUnlocked] ||
            [self isAdminFullVersionUnlocked]);
}

- (BOOL)unlimitedPhotos {
    return ([self isUnlimitedPhotosVersionPurchased] ||
            [self isAdminUnlimitedPhotosUnlocked]);
}

- (BOOL)unlimitedVideos {
    return ([self isUnlimitedVideosVersionPurchased] ||
            [self isAdminUnlimitedVideosUnlocked]);
}


#pragma mark - Product granted by In-App purchase

- (BOOL)itemIsPurchased:(NSString *)itemKey {
    NSString *storedValue = [self storedStringForKey:itemKey];
    if ([storedValue isEqualToString:kPBPurchaseManagerItemIsPurchased]) {
        return YES;
    }

    return NO;
}

- (void)unlockProductWithKey:(NSString *)productKey {
    [self storeString:kPBPurchaseManagerItemIsPurchased
               forKey:productKey];

    if ([productKey isEqualToString:PB_PLUS_INAPP_ID]) {
        [self logPurchasedPlusEvent];
    }
}

- (void)deactivateProductWithKey:(NSString *)productKey {
    [self removeStoredString:kPBPurchaseManagerItemIsPurchased
                      forKey:productKey];
}


#pragma mark - Full Version granted by In-App purchase

- (void)deactivateFullVersion {
    [self removeStoredString:kPBPurchaseManagerItemIsPurchased
                      forKey:PB_PLUS_INAPP_ID];
}

- (BOOL)isFullVersionUnlocked {
    static BOOL _isFullVersionUnlocked = NO;
    
    if (NO == _isFullVersionUnlocked) {
        _isFullVersionUnlocked = [self itemIsPurchased:PB_PLUS_INAPP_ID];

        if (_isFullVersionUnlocked) {
            NSLog(@"Plus version is unlocked");
        }
    }

    return _isFullVersionUnlocked;
}

- (BOOL)isUnlimitedPhotosVersionPurchased {
    static BOOL _isUnlimitedPhotosVersionUnlocked = NO;

    if (NO == _isUnlimitedPhotosVersionUnlocked) {
        _isUnlimitedPhotosVersionUnlocked = [self itemIsPurchased:PB_UNLIMITED_PHOTOS_INAPP_ID];

        if (_isUnlimitedPhotosVersionUnlocked) {
            NSLog(@"UnlimitedPhotos version is unlocked");
        }
    }

    return _isUnlimitedPhotosVersionUnlocked;
}

- (BOOL)isUnlimitedVideosVersionPurchased {
    static BOOL _isUnlimitedVideosVersionUnlocked = NO;

    if (NO == _isUnlimitedVideosVersionUnlocked) {
        _isUnlimitedVideosVersionUnlocked = [self itemIsPurchased:PB_UNLIMITED_VIDEOS_INAPP_ID];

        if (_isUnlimitedVideosVersionUnlocked) {
            NSLog(@"UnlimitedVideos version is unlocked");
        }
    }

    return _isUnlimitedVideosVersionUnlocked;
}


#pragma mark - Product granted by CapableBits

- (BOOL)itemGrantedByAdmin:(NSString *)itemKey {
    NSString *storedValue = [self storedStringForKey:itemKey];
    if ([storedValue isEqualToString:kPBPurchaseManagerItemIsGrantedByAdmin]) {
        return YES;
    }

    return NO;
}

- (void)unlockByAdminProductWithKey:(NSString *)productKey {
    [self storeString:kPBPurchaseManagerItemIsGrantedByAdmin
               forKey:productKey];
}

- (void)deactivateByAdminProductWithKey:(NSString *)productKey {
    [self removeStoredString:kPBPurchaseManagerItemIsGrantedByAdmin
                      forKey:productKey];
}


#pragma mark - Full version granted by CapableBits

- (BOOL)isAdminFullVersionUnlocked {
    static BOOL _isAdminFullVersionUnlocked = NO;

    if (NO == _isAdminFullVersionUnlocked) {
        _isAdminFullVersionUnlocked = [self itemGrantedByAdmin:PB_PLUS_INAPP_ID];

        if (_isAdminFullVersionUnlocked) {
            NSLog(@"Plus version is unlocked by Admin");
        }
    }

    return _isAdminFullVersionUnlocked;
}

- (void)unlockAdminFullVersion {
    [self unlockByAdminProductWithKey:PB_PLUS_INAPP_ID];
}

- (void)deactivateAdminFullVersion {
    [self deactivateByAdminProductWithKey:PB_PLUS_INAPP_ID];

    //also clear in-app purchase
    [self deactivateFullVersion];
    
    PBAlertOKWithCompletion(@"App deactivated successfully", @"Will exit now.", ^{
        exit(0);
    });
}


#pragma mark - UnlimitedPhotos version granted by CapableBits

- (BOOL)isAdminUnlimitedPhotosUnlocked {
    static BOOL _isAdminUnlimitedPhotosVersionUnlocked = NO;

    if (NO == _isAdminUnlimitedPhotosVersionUnlocked) {
        _isAdminUnlimitedPhotosVersionUnlocked = [self itemGrantedByAdmin:PB_UNLIMITED_PHOTOS_INAPP_ID];

        if (_isAdminUnlimitedPhotosVersionUnlocked) {
            NSLog(@"UnlimitedPhotos version is unlocked by Admin");
        }
    }

    return _isAdminUnlimitedPhotosVersionUnlocked;
}

- (void)unlockAdminUnlimitedPhotosVersion {
    [self unlockByAdminProductWithKey:PB_UNLIMITED_PHOTOS_INAPP_ID];
}

- (void)deactivateAdminUnlimitedPhotosVersion {
    [self deactivateByAdminProductWithKey:PB_UNLIMITED_PHOTOS_INAPP_ID];
}


#pragma mark - UnlimitedVideos version granted by CapableBits

- (BOOL)isAdminUnlimitedVideosUnlocked {
    static BOOL _isAdminUnlimitedVideosVersionUnlocked = NO;

    if (NO == _isAdminUnlimitedVideosVersionUnlocked) {
        _isAdminUnlimitedVideosVersionUnlocked = [self itemGrantedByAdmin:PB_UNLIMITED_VIDEOS_INAPP_ID];

        if (_isAdminUnlimitedVideosVersionUnlocked) {
            NSLog(@"UnlimitedVideos version is unlocked by Admin");
        }
    }

    return _isAdminUnlimitedVideosVersionUnlocked;
}

- (void)unlockAdminUnlimitedVideosVersion {
    [self unlockByAdminProductWithKey:PB_UNLIMITED_VIDEOS_INAPP_ID];
}

- (void)deactivateAdminUnlimitedVideosVersion {
    [self deactivateByAdminProductWithKey:PB_UNLIMITED_VIDEOS_INAPP_ID];
}


#pragma mark - Keychain access

- (NSString *)storedStringForKey:(NSString *)keyString {
    NSMutableDictionary* query = [NSMutableDictionary dictionary];

    [query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [query setObject:keyString forKey:(id)kSecAttrService];
    [query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];

    NSData *itemData = nil;
    OSStatus result = SecItemCopyMatching ((CFDictionaryRef)query, (CFTypeRef*)&itemData);

    if ((result != errSecSuccess) || (nil == itemData)) {
        return @"";
    }

    NSString *storedString =
        [[[NSString alloc] initWithData:itemData
                               encoding:NSUTF8StringEncoding] autorelease];

    return storedString;
}

- (void)storeString:(NSString *)valueToStore forKey:(NSString *)keyString {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSData *itemIsPurchasedData = [valueToStore dataUsingEncoding:NSUTF8StringEncoding];

    [dict setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [dict setObject:keyString  forKey:(id)kSecAttrService];
    [dict setObject:itemIsPurchasedData forKey:(id)kSecValueData];

    SecItemAdd((CFDictionaryRef)dict, NULL);
}

- (void)removeStoredString:(NSString *)storedValue forKey:(NSString *)keyString {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];

    NSData *itemIsPurchasedData = [storedValue dataUsingEncoding:NSUTF8StringEncoding];

    [dict setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [dict setObject:keyString  forKey:(id)kSecAttrService];
    [dict setObject:itemIsPurchasedData forKey:(id)kSecValueData];

    SecItemDelete((CFDictionaryRef)dict);
}


#pragma mark - Purchase methods

- (void)restorePurchasedProducts {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)buyProduct:(SKProduct *)product {
    if (product == nil) {
        NSLog(@"Going to buy product, but it is <nil>");

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey : NSLocalizedString(@"Cannot connect to iTunes Store", @"")
            };
            
            NSError *error = [NSError errorWithDomain:PBPurchaseManagerErorDomain
                                                 code:13
                                             userInfo:userInfo];

            [[NSNotificationCenter defaultCenter]
                postNotificationName:PBPurchaseManagerDidFailToUnlockProduct
                object:error];
        });

        return;
    }

    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)buyFullVersion {
    NSLog(@"Going to buy full version");

    SKProduct *product = [_availableProducts objectForKey:PB_PLUS_INAPP_ID];
    [self buyProduct:product];
}

- (void)buyUnlimitedPhotosVersion {
    NSLog(@"Going to buy unlimited photos version");
    
    SKProduct *product = [_availableProducts objectForKey:PB_UNLIMITED_PHOTOS_INAPP_ID];
    [self buyProduct:product];
}

- (void)buyUnlimitedVideosVersion {
    NSLog(@"Going to buy unlimited videos version");
    
    SKProduct *product = [_availableProducts objectForKey:PB_UNLIMITED_VIDEOS_INAPP_ID];
    [self buyProduct:product];
}

- (void)deactivateAllPurchasedProducts {
    [self deactivateProductWithKey:PB_PLUS_INAPP_ID];
    [self deactivateProductWithKey:PB_UNLIMITED_PHOTOS_INAPP_ID];
    [self deactivateProductWithKey:PB_UNLIMITED_VIDEOS_INAPP_ID];

    [self deactivateByAdminProductWithKey:PB_PLUS_INAPP_ID];
    [self deactivateByAdminProductWithKey:PB_UNLIMITED_PHOTOS_INAPP_ID];
    [self deactivateByAdminProductWithKey:PB_UNLIMITED_VIDEOS_INAPP_ID];
}

@end
