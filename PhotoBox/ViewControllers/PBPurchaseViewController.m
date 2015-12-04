//
//  PBPurchaseViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 18/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBPurchaseViewController.h"
#import "PBStretchableBackgroundButton.h"

@interface PBPurchaseViewController () {
    BOOL _buyFullVersionDisabled;
    BOOL _buyUnlimitedPhotosVersionDisabled;
    BOOL _buyUnlimitedVideosVersionDisabled;
    BOOL _maxPhotosHighlighted;
    BOOL _maxVideosHighlighted;
    BOOL _maxVideoDurationHighlighted;
}

@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *buyFullVersionButton;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *buyUnlimitedPhotosVersionButton;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *buyUnlimitedVideosVersionButton;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *restorePurchasedProductsButton;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *continueButton;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (retain, nonatomic) IBOutlet UILabel *messageLabel;
@property (retain, nonatomic) IBOutlet UILabel *proposalLabel;
@property (retain, nonatomic) IBOutlet UILabel *unlimitedPhotosPriceLabel;
@property (retain, nonatomic) IBOutlet UILabel *unlimitedVideosPriceLabel;
@property (retain, nonatomic) IBOutlet UILabel *fullVersionPriceLabel;
@property (retain, nonatomic) IBOutlet UILabel *maxPhotosLabel;
@property (retain, nonatomic) IBOutlet UILabel *maxVideosLabel;
@property (retain, nonatomic) IBOutlet UILabel *maxVideoDurationLabel;
@end

@implementation PBPurchaseViewController

+ (UIColor *)priceLabelTextColor {
    return [UIColor whiteColor];
}

+ (UIColor *)priceLabelShadowColor {
    return [UIColor darkGrayColor];
}


#pragma mark - Memory management

- (void)dealloc {
    [_buyFullVersionButton release];
    _buyFullVersionButton = nil;

    [_buyUnlimitedPhotosVersionButton release];
    _buyUnlimitedPhotosVersionButton = nil;

    [_buyUnlimitedVideosVersionButton release];
    _buyUnlimitedVideosVersionButton = nil;

    [_restorePurchasedProductsButton release];
    _restorePurchasedProductsButton = nil;

    [_continueButton release];
    _continueButton = nil;

    [_activityIndicator release];
    _activityIndicator = nil;

    [_fullVersionPriceString release];
    _fullVersionPriceString = nil;

    [_unlimitedPhotosVersionPriceString release];
    _unlimitedPhotosVersionPriceString = nil;

    [_unlimitedVideosVersionPriceString release];
    _unlimitedVideosVersionPriceString = nil;

    [_continueButtonTitle release];
    _continueButtonTitle = nil;

    [_messageLabel release];
    _messageLabel = nil;

    [_message release];
    _message = nil;

    [_proposalLabel release];
    _proposalLabel = nil;

    [_proposal release];
    _proposal = nil;
    
    [super dealloc];
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    

    if (nil != self.continueButtonTitle) {
        [_continueButton setTitle:_continueButtonTitle
                         forState:UIControlStateNormal];
    }

    if (nil != _message) {
        _messageLabel.text = _message;
    }

    if (nil != _proposal) {
        _proposalLabel.attributedText = _proposal;
    }

    UIColor *priceLabelTextColor = [[self class] priceLabelTextColor];
    [_unlimitedPhotosPriceLabel setTextColor:priceLabelTextColor];
    [_unlimitedVideosPriceLabel setTextColor:priceLabelTextColor];
    [_fullVersionPriceLabel setTextColor:priceLabelTextColor];

    UIColor *priceLabelShadowColor = [[self class] priceLabelShadowColor];
    [_unlimitedPhotosPriceLabel setShadowColor:priceLabelShadowColor];
    [_unlimitedVideosPriceLabel setShadowColor:priceLabelShadowColor];
    [_fullVersionPriceLabel setShadowColor:priceLabelShadowColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.fullVersionPriceLabel.text = self.fullVersionPriceString;
    self.unlimitedPhotosPriceLabel.text = self.unlimitedPhotosVersionPriceString;
    self.unlimitedVideosPriceLabel.text = self.unlimitedVideosVersionPriceString;

    [self setMaxPhotosHiglighted:_maxPhotosHighlighted];
    [self setMaxVideosHiglighted:_maxVideosHighlighted];
    [self setMaxVideoDurationHiglighted:_maxVideoDurationHighlighted];

    [self enableButtons];
}

- (void)disableBuyFullVersionButton {
    _buyFullVersionDisabled = YES;
    self.buyFullVersionButton.enabled = NO;
}

- (void)disableBuyUnlimitedPhotosButton {
    _buyUnlimitedPhotosVersionDisabled = YES;
    self.buyUnlimitedPhotosVersionButton.enabled = NO;
}

- (void)disableBuyUnlimitedVideosButton {
    _buyUnlimitedVideosVersionDisabled = YES;
    self.buyUnlimitedVideosVersionButton.enabled = NO;
}

- (void)disableButtons {
    self.buyFullVersionButton.enabled = NO;
    self.buyUnlimitedPhotosVersionButton.enabled = NO;
    self.buyUnlimitedVideosVersionButton.enabled = NO;
    self.continueButton.enabled = NO;

    [_activityIndicator startAnimating];
}

- (void)enableButtons {
    self.buyFullVersionButton.enabled = !_buyFullVersionDisabled;
    self.buyUnlimitedPhotosVersionButton.enabled = !_buyUnlimitedPhotosVersionDisabled;
    self.buyUnlimitedVideosVersionButton.enabled = !_buyUnlimitedVideosVersionDisabled;
    self.continueButton.enabled = YES;
    [_activityIndicator stopAnimating];
}

- (void)setMaxPhotosHiglighted:(BOOL)highlighted {
    _maxPhotosHighlighted = highlighted;
    [self.maxPhotosLabel setHighlighted:highlighted];
}

- (void)setMaxVideosHiglighted:(BOOL)highlighted {
    _maxVideosHighlighted = highlighted;
    [self.maxVideosLabel setHighlighted:highlighted];
}

- (void)setMaxVideoDurationHiglighted:(BOOL)highlighted {
    _maxVideoDurationHighlighted = highlighted;
    [self.maxVideoDurationLabel setHighlighted:highlighted];
}


#pragma mark - Price labels

- (void)setFullVersionPriceString:(NSString *)fullVersionPriceString {
    [_fullVersionPriceString autorelease];
    _fullVersionPriceString = nil;

    _fullVersionPriceString = [fullVersionPriceString copy];

    self.fullVersionPriceLabel.text = fullVersionPriceString;
}

- (void)setUnlimitedPhotosVersionPriceString:(NSString *)unlimitedPhotosVersionPriceString {
    [_unlimitedPhotosVersionPriceString autorelease];
    _unlimitedPhotosVersionPriceString = nil;

    _unlimitedPhotosVersionPriceString = [unlimitedPhotosVersionPriceString copy];

    self.unlimitedPhotosPriceLabel.text = unlimitedPhotosVersionPriceString;
}

- (void)setUnlimitedVideosVersionPriceString:(NSString *)unlimitedVideosVersionPriceString {
    [_unlimitedVideosVersionPriceString autorelease];
    _unlimitedVideosVersionPriceString = nil;

    _unlimitedVideosVersionPriceString = [unlimitedVideosVersionPriceString copy];

    self.unlimitedVideosPriceLabel.text = unlimitedVideosVersionPriceString;
}


#pragma mark - Actions

- (IBAction)restorePurchasedProductsButtonTapped:(id)sender {
    [self disableButtons];
    [_delegate checkAndPerformSelector:@selector(purchaseViewControllerDidTapRestorePurchasedProductsButton:)
                            withObject:self];
}

- (IBAction)buyFullVersionButtonTapped:(id)sender {
    [self disableButtons];
    [_delegate checkAndPerformSelector:@selector(purchaseViewControllerDidTapBuyFullVersionButton:)
                            withObject:self];
}

- (IBAction)buyUnlimitedPhotosVersionButtonTapped:(id)sender {
    [self disableButtons];
    [_delegate checkAndPerformSelector:@selector(purchaseViewControllerDidTapBuyUnlimitedPhotosVersionButton:)
                            withObject:self];
}

- (IBAction)buyUnlimitedVideosVersionButtonTapped:(id)sender {
    [self disableButtons];
    [_delegate checkAndPerformSelector:@selector(purchaseViewControllerDidTapBuyUnlimitedVideosVersionButton:)
                            withObject:self];
}

- (IBAction)continueButtonTapped:(id)sender {

    //analytics

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger numberOfTimesPhotosWereSent = [defaults integerForKey:kPBNumberOfTimesPhotosWereSent];
    NSInteger numberOfTimesAppWereLaunched = [defaults integerForKey:kPBNumberOfTimesAppWereLaunched];
    NSDictionary *parameters = @{
        @"numberOfTimesPhotosWereSent" : [NSString stringWithInteger:numberOfTimesPhotosWereSent],
        @"numberOfTimesAppWereLaunched": [NSString stringWithInteger:numberOfTimesAppWereLaunched]
    };

    [[CBAnalyticsManager sharedManager]
        logEvent:@"send5PhotosForFreeSelected"
        withParameters:parameters];
    
    [_delegate checkAndPerformSelector:@selector(purchaseViewControllerDidTapContinueButton:)
                            withObject:self];
}

@end
