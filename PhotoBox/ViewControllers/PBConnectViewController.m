//
//  PBConnectViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 21/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBConnectViewController.h"
#import "PBAssetManager.h"
#import "PBConnectionManager.h"

@interface PBConnectViewController () {
    CGFloat _illustrationViewInitialY;
}

@property (retain, nonatomic) IBOutlet UIView *instructionView;

@property (retain, nonatomic) IBOutlet UILabel *httpUrlLabel;
@property (retain, nonatomic) IBOutlet UILabel *secondHttpUrlLabel;


@property (retain, nonatomic) IBOutlet UIView *firstAddressView;
@property (retain, nonatomic) IBOutlet UIView *secondAddressView;
@property (retain, nonatomic) IBOutlet UIView *illustrationView;
@property (retain, nonatomic) IBOutlet UILabel *illustrationBrowserAddressLabel;


@property (retain, nonatomic) IBOutlet UIView *preparingView;
@property (retain, nonatomic) IBOutlet UIProgressView *preparingProgressIndicator;

@end

@implementation PBConnectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.showTopToolbar = YES;
    self.topBarShadowType = PBViewControllerTopBarShadowTypeNormal;
    self.topToolbarShowFreeToSendPhotosOnly = YES;
}


#pragma mark - Memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_httpUrlLabel release];
    [_preparingView release];
    [_preparingProgressIndicator release];

    //cancel preparing if user goes back
    if (_sendAssetsUI) {
        //it is safe to cancel even when not busy
        [[PBAssetManager sharedManager] cancelPreparingAssets];
    }

    [_firstAddressView release];
    [_secondAddressView release];
    [_illustrationView release];
    [_secondHttpUrlLabel release];
    [_instructionView release];
    [_illustrationBrowserAddressLabel release];

    [super dealloc];
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    [self viewDidLoadInterfaceUpdate];
    [self updateLocalAddressLabel];

    if (_sendAssetsUI) {
        _preparingProgressIndicator.progress = 0;
        [self updatePreparingView];
        [self registerOnNotifications];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)viewDidLoadInterfaceUpdate {
    UIColor *clearColor = [UIColor clearColor];
    _firstAddressView.backgroundColor = clearColor;
    _secondAddressView.backgroundColor = clearColor;
    _illustrationView.backgroundColor = clearColor;
    _preparingView.backgroundColor = self.view.backgroundColor;

    _illustrationViewInitialY = _illustrationView.frame.origin.y;
    _instructionView.center = self.view.center;
    _instructionView.backgroundColor = clearColor;

    if (_sendAssetsUI) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            self.title = NSLocalizedString(@"Send to Computer", @"");
        } else {
            self.title = NSLocalizedString(@"Send", @"");
        }
    }
    else {
        self.title = NSLocalizedString(@"Receive", @"Receive") ;
    }

    [self.navigationController setToolbarHidden:YES animated:YES];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIBarButtonItem *cancelButton =
            [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"")
                style:UIBarButtonItemStylePlain
                target:self
                action:@selector(cancelButtonTapped:)]
            autorelease];

        self.navigationItem.rightBarButtonItem = cancelButton;
    }
}

- (void)updatePreparingView {
    if ([[PBAssetManager sharedManager] isBusy]) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        _preparingView.alpha = 1;
    } else {
        _preparingView.alpha = 0;
    }
}

- (void)dismiss {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)updateLocalAddressLabel {
    NSString *localAddressString = nil;
    NSString *localUrlString = [[PBConnectionManager sharedManager] localUrlString];
    
    //if localURLString is nil, try to obtain it several times
    
    if (!localUrlString) {
        for (int i=0; i < 5; i++) {
            localUrlString = [[PBConnectionManager sharedManager] localUrlString];
            if (localUrlString)
                break;
        }
    }
    
    BOOL noWiFi = NO;
    
    if (localUrlString) {
        localAddressString = localUrlString;
    } else {
        localAddressString = NSLocalizedString(@"Not connected to Wi-Fi", @"Not connected to Wi-Fi");
        noWiFi = YES;
    }

    CGFloat illustrationY;
    CGFloat secondAddressViewAlpha;

    NSString *permanentUrlString = [[PBConnectionManager sharedManager] permanentUrlString];
    if (permanentUrlString && noWiFi == NO) {
        _httpUrlLabel.text = permanentUrlString;
        _secondHttpUrlLabel.text = localAddressString;

        illustrationY = _illustrationViewInitialY;
        secondAddressViewAlpha = 1;
    }
    else {
        _httpUrlLabel.text = localAddressString;
        _secondHttpUrlLabel.text = @"";

        illustrationY = _secondAddressView.frame.origin.y;
        secondAddressViewAlpha = 0;
    }

    _illustrationBrowserAddressLabel.text = _httpUrlLabel.text;

    CGRect illustrationFrame = _illustrationView.frame;
    illustrationFrame.origin.y = illustrationY;
    [UIView animateWithDuration:0.2
                     animations:^{
                         _illustrationView.frame = illustrationFrame;
                         _secondAddressView.alpha = secondAddressViewAlpha;
                     }];
}


#pragma mark - Events handling

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismiss];
}


#pragma mark - Notifications

- (void)registerOnNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(prepareAssetProgressChanged:)
                               name:PBAssetManagerPrepareAssetProgressDidChangeNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(prepareAssetFinished:)
                               name:PBAssetManagerPrepareAssetDidFinishNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(updateLocalAddressLabel)
                               name:PBConnectionManagerPermanentUrlDidChangeNotification
                             object:nil];
}

- (void)prepareAssetProgressChanged:(NSNotification *)notification {
    NSNumber *progress = notification.userInfo[kPBProgress];
    [_preparingProgressIndicator setProgress:[progress floatValue]*0.9 animated:YES];
}

- (void)prepareAssetFinished:(NSNotification *)notification {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [_preparingProgressIndicator setProgress:1.0 animated:YES];

    [UIView animateWithDuration:0.3
                     animations:^{
                         _preparingView.alpha = 0;
                     } completion:^(BOOL finished) {
                         _preparingProgressIndicator.progress = 0;
                     }];
}

@end
