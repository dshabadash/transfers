//
//  PBTransferProgressViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBTransferProgressViewController.h"
#import "PBProgressIndicator.h"
#import "PBSubscribeViewController.h"

#import "PBMongooseServer.h"
#import "PBAssetUploader.h"
#import "PBAssetManager.h"
#import "TTTAttributedLabel.h"
#import <CoreText/CoreText.h>
#import "RDHTTP.h"
#import "PBServiceBrowser.h"

#import "RD2RateThisAppManager.h"

typedef enum {
    PBTransferProgressViewControllerStateDownloading = 0,
    PBTransferProgressViewControllerStateUploading,
    PBTransferProgressViewControllerStateImporting,
    PBTransferProgressViewControllerStateDownloadFinished,
    PBTransferProgressViewControllerStateUploadFinished,
    PBTransferProgressViewControllerStateCanceled
} PBTransferProgressViewControllerState;

@interface PBTransferProgressViewController () {
    PBTransferProgressViewControllerState _state;
    BOOL _shouldPresentSubscribeViewController;
    BOOL _shouldPresentRateViewController;
    NSUserDefaults *_defaults;
    SEL _okButtonAction;
}

@property (retain, nonatomic) IBOutlet UIButton *doneButton;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutletCollection(UILabel) NSArray *transferDirectionTitles;

@property (retain, nonatomic) IBOutlet UIView *contentContainerView;
@property (retain, nonatomic) IBOutlet PBProgressIndicator *progressIndicator;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (retain, nonatomic) IBOutlet UIImageView *transferAnimationImageView;
@property (retain, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (retain, nonatomic) IBOutlet UIView *finishedContentContainerView;
@property (retain, nonatomic) IBOutlet UIImageView *finishedImageView;
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *messageLabel;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *importingActivityIndicatorView;

@property (retain, nonatomic) IBOutlet UILabel *currentDeviceLabel;
@property (retain, nonatomic) IBOutlet UIImageView *currentDeviceImageView;

@property (retain, nonatomic) IBOutlet UILabel *otherDeviceLabel;
@property (retain, nonatomic) IBOutlet UIImageView *otherDeviceImageView;

@property (retain, nonatomic) IBOutlet UIButton *okButton;

@property (retain, nonatomic) IBOutlet UIImageView *transferCanceledImageView;
@end

@implementation PBTransferProgressViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _state = 0;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
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
                               selector:@selector(transferFinished:)
                                   name:PBMongooseServerPostBodyProgressDidFinishNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(transferFinished:)
                                   name:PBMongooseServerGetBodyProgressDidFinishNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(transferFinished:)
                                   name:PBAssetUploaderUploadDidFinishNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(transferWasCanceled:)
                                   name:PBTransferWasCanceledNotification
                                 object:nil];

    }
    return self;
}


#pragma mark - Properties

- (NSString *)deviceName {
    return (nil == _deviceName) ? @"" : _deviceName;
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _defaults = [NSUserDefaults standardUserDefaults];
    _shouldPresentSubscribeViewController = NO;
    _shouldPresentRateViewController = NO;
    
    [self updateDeviceLabels];
    
    _otherDeviceLabel.text = self.deviceType;

    _progressIndicator.backgroundImage = [UIImage imgNamed:@"progressbar_bg"];
    _progressIndicator.progressImage = [UIImage imgNamed:@"progressbar_uploaded"];
    _progressIndicator.progress = _initialProgress;
    
    _contentContainerView.backgroundColor = [UIColor clearColor];
    
    _finishedContentContainerView.hidden = YES;
    
    if ([[[[UIDevice currentDevice] model] lowercaseString] hasString:@"ipad"]) {
        _currentDeviceLabel.text = @"iPad";
        _currentDeviceImageView.image = [UIImage imgNamed:@"receive_screen_ipad_selected"];
    }

//
    [self startTransferAnimation];
    if (_transferDirection == PBTransferDirectionSend) {
        [self setState:PBTransferProgressViewControllerStateDownloading];
    } else {
        [self setState:PBTransferProgressViewControllerStateUploading];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self updateDirectionTitles];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}


#pragma mark - Memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_progressIndicator release];
    [_contentContainerView release];
    [_titleLabel release];
    [_activityIndicator release];
    [_transferAnimationImageView release];
    [_okButton release];
    [_descriptionLabel release];
    [_messageLabel release];
    [_otherDeviceLabel release];
    [_otherDeviceImageView release];
    [_currentDeviceImageView release];
    [_currentDeviceLabel release];
    [_finishedContentContainerView release];
    [_finishedImageView release];
    [_importingActivityIndicatorView release];
    [_transferCanceledImageView release];
    [_transferDirectionTitles release];
    
    [super dealloc];
}


#pragma mark - UI

- (void)setState:(PBTransferProgressViewControllerState)state {
    _state = state;

    [self updateDeviceLabels];
    [self updateDirectionTitles];

    if (state == PBTransferProgressViewControllerStateDownloading) {
        _titleLabel.text = NSLocalizedString(@"Sending Photos", @"");
        _descriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Sending photos to %@. This might take up to few minutes.", @""),
                                  self.deviceName];
        _progressIndicator.hidden = NO;
        _activityIndicator.hidden = YES;
        [_activityIndicator stopAnimating];

        [self showCancelButton];
        
        _finishedContentContainerView.hidden = YES;
        [_importingActivityIndicatorView stopAnimating];

        _transferAnimationImageView.transform = CGAffineTransformIdentity;
        [self startTransferAnimation];
        _contentContainerView.hidden = NO;
    }
    else if (state == PBTransferProgressViewControllerStateUploading) {
        _titleLabel.text = NSLocalizedString(@"Receiving Photos", @"");
        _descriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Receiving photos from %@. This might take up to few minutes.", @""), self.deviceName];
        _progressIndicator.hidden = YES;
        _activityIndicator.hidden = NO;
        [_activityIndicator startAnimating];

        [self hideDoneButton];
        [self hideDismissButton];

        if ([self cancelButtonAvailable]) {
            [self showCancelButton];
        }
        else {
            [self hideCancelButton];
        }
        
        _finishedContentContainerView.hidden = YES;
        [_importingActivityIndicatorView stopAnimating];
        
        CGAffineTransform transform = CGAffineTransformMakeScale(-1, 1);
        _transferAnimationImageView.transform = transform;
        [self startTransferAnimation];
        
        _contentContainerView.hidden = NO;
    }
    else if (state == PBTransferProgressViewControllerStateImporting) {
        _titleLabel.text = NSLocalizedString(@"Receiving Photos", @"");
        _messageLabel.text = NSLocalizedString(@"Photos were successfully received. Importing...", @"");

        _finishedImageView.hidden = NO;
        _finishedImageView.image = [UIImage imgNamed:@"transfer_smile_iphone_tongue"];
        _progressIndicator.hidden = YES;
        _activityIndicator.hidden = YES;
        [_activityIndicator stopAnimating];

        [self hideDoneButton];
        [self hideCancelButton];
        [self hideDismissButton];

        _finishedContentContainerView.hidden = NO;
        _transferCanceledImageView.hidden = YES;
        
        [_importingActivityIndicatorView startAnimating];
        
        [self stopTransferAnimation];
        _contentContainerView.hidden = YES;
    }
    else if (state == PBTransferProgressViewControllerStateDownloadFinished) {
        _titleLabel.text = NSLocalizedString(@"Sending Photos", @"");
        _messageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photos were successfully sent to %@.", @""), self.deviceName];
        
        _finishedImageView.hidden = NO;
        _finishedImageView.image = [UIImage imgNamed:@"transfer_smile_iphone"];
        _progressIndicator.hidden = YES;
        _activityIndicator.hidden = YES;
        [_activityIndicator stopAnimating];

        [self showDoneButton];

        _finishedContentContainerView.hidden = NO;
        _transferCanceledImageView.hidden = YES;

        [_importingActivityIndicatorView stopAnimating];
        
        self.deviceType = nil;
        self.deviceName = nil;
        
        [self stopTransferAnimation];
        _contentContainerView.hidden = YES;
    }
    else if (state == PBTransferProgressViewControllerStateUploadFinished) {
        _titleLabel.text = NSLocalizedString(@"Receiving Photos", @"");
        ALAssetsGroup *assetGroup = [[PBAssetManager sharedManager] savedPhotosAssetsGroup];
        NSString *albumName = (NSString *)[assetGroup valueForProperty:ALAssetsGroupPropertyName];

        // The almumName variable is nil if there is no access to assets library.
        // It can cause crash after rangeOfString: method is being called inside [_messageLabel setText: ... block.
        // Temporary solution, this must be moved to model class.
        if (nil == albumName) {
            albumName = @"";
        }

        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Photos were successfully received from %@, and saved to %@ album.", @""), self.deviceName, albumName];
        [_messageLabel setText:message afterInheritingLabelAttributesAndConfiguringWithBlock:
            ^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                NSRange boldRange = [[mutableAttributedString string] rangeOfString:albumName];
                UIFont *boldFont = [UIFont boldSystemFontOfSize:_messageLabel.font.pointSize];
                CTFontRef font = CTFontCreateWithName((CFStringRef)boldFont.fontName, boldFont.pointSize, NULL);
                if (font) {
                    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName
                                                    value:(id)font
                                                    range:boldRange];

                    CFRelease(font);
                }

                return mutableAttributedString;
        }];

        _finishedImageView.hidden = NO;
        _finishedImageView.image = [UIImage imgNamed:@"transfer_smile_iphone_tongue"];
        _progressIndicator.hidden = YES;
        _activityIndicator.hidden = YES;
        [_activityIndicator stopAnimating];

        [self showDoneButton];

        _finishedContentContainerView.hidden = NO;
        _transferCanceledImageView.hidden = YES;
        [_importingActivityIndicatorView stopAnimating];

        self.deviceType = nil;
        self.deviceName = nil;
        [[PBAppDelegate sharedDelegate] setTransferSession:nil];
        
        [self stopTransferAnimation];
        _contentContainerView.hidden = YES;
    }
    else if (state == PBTransferProgressViewControllerStateCanceled) {
        _titleLabel.text = NSLocalizedString(@"Aw, Snap!", @"Aw, Snap!");
        NSString *messageFormat = NSLocalizedString(@"Transferring was canceled. %@ app must be running while transferring on both devices.", @"Transferring was canceled. %@ app must be running while transferring on both devices.");

        _messageLabel.text = [NSString stringWithFormat:messageFormat, PB_APP_NAME];
        
        _transferCanceledImageView.hidden = NO;
        _transferCanceledImageView.image = [UIImage imgNamed:@"sad_iphone_snap"];
        _progressIndicator.hidden = YES;
        _activityIndicator.hidden = YES;
        [_activityIndicator stopAnimating];

        [self showDismissButton];

        _finishedContentContainerView.hidden = NO;
        _finishedImageView.hidden = YES;
        
        [_importingActivityIndicatorView stopAnimating];

        self.deviceType = nil;
        self.deviceName = nil;

        [self stopTransferAnimation];
        _contentContainerView.hidden = YES;
    }
}

- (void)startTransferAnimation {
    UIImage *frame0 = [UIImage imgNamed:@"transfer_animation_wifi_clean"];
    UIImage *frame1 = [UIImage imgNamed:@"transfer_animation_wifi_1"];
    UIImage *frame2 = [UIImage imgNamed:@"transfer_animation_wifi_2"];
    UIImage *frame3 = [UIImage imgNamed:@"transfer_animation_wifi_3"];

    _transferAnimationImageView.animationImages = @[frame0, frame1, frame2, frame3];
    _transferAnimationImageView.animationDuration = 1.0;
    [_transferAnimationImageView startAnimating];
}

- (void)stopTransferAnimation {
    _transferAnimationImageView.animationImages = nil;
    _transferAnimationImageView.image = [UIImage imgNamed:@"transfer_animation_wifi_all"];
}

- (BOOL)cancelButtonAvailable {
    PBTransferSession *session = [PBAppDelegate sharedDelegate].transferSession;

    if (nil == session) {
        return NO;
    }

    NSString *deviceName = [PBAppDelegate sharedDelegate].transferSession.deviceName;
    if (nil == deviceName || [deviceName length] == 0) {
        return NO;
    }

    return YES;
}

- (void)updateDeviceLabels {
    if (_deviceName == nil) {
        self.deviceName = NSLocalizedString(@"computer", @"");
    }
    if (_deviceType == nil) {
        self.deviceType = NSLocalizedString(@"Computer", @"");
    }
    
    NSString *otherDeviceImageName = nil;
    NSString *deviceType = [_deviceType lowercaseString];
    if ([deviceType hasString:@"ipad"]) {
        otherDeviceImageName = @"receive_screen_ipad_selected";
    } else if ([deviceType hasString:@"iphone"]) {
        otherDeviceImageName = @"receive_screen_iphone_selected";
    } else {
        otherDeviceImageName = @"receive_screen_mac_or_pc_selected";
    }
    
    _otherDeviceImageView.image = [UIImage imgNamed:otherDeviceImageName];
    _otherDeviceLabel.text = self.deviceType;
}

- (void)updateDirectionTitles {
    NSString *textFormat = (self.transferDirection == PBTransferDirectionSend)
        ? NSLocalizedString(@"Sending photos to %@", @"Template for string Sending photos to iphone/ipad/computer")
        : NSLocalizedString(@"Receiving photos from %@", @"Template for string Receiving photos from iphone/ipad/computer");

    NSString *text = [NSString stringWithFormat:textFormat, self.deviceName];

    for (UILabel *titleLabel in self.transferDirectionTitles) {
        titleLabel.text = text;
    }
}

- (void)showCancelButton {
    [self hideDoneButton];
    [self hideDismissButton];

    _okButtonAction = @selector(cancelTransfer);

    NSString *title = NSLocalizedString(@"Cancel", @"Cancel");
    [_okButton setTitle:title forState:UIControlStateNormal];
    _okButton.selected = NO;
    [_okButton setHidden:NO];
}

- (void)hideCancelButton {
    [_okButton setHidden:YES];
}

- (void)showDoneButton {
    [self hideCancelButton];
    [self hideDismissButton];

    _okButtonAction = @selector(finishTransfer);

    NSString *title = NSLocalizedString(@"Done", @"Done");
    [_okButton setTitle:title forState:UIControlStateNormal];
    _okButton.selected = YES;

    //[_okButton setHidden:NO];
    [_doneButton setHidden:NO];
}

- (void)hideDoneButton {
    //[_okButton setHidden:YES];
    [_doneButton setHidden:YES];
}

- (void)showDismissButton {
    [self hideCancelButton];
    [self hideDoneButton];

    NSString *title = NSLocalizedString(@"Done", @"Done");
    [_okButton setTitle:title forState:UIControlStateNormal];
    _okButton.selected = YES;
    _okButtonAction = @selector(dismiss);

    //[_okButton setHidden:NO];
    [_doneButton setHidden:NO];
}

- (void)hideDismissButton {
    //[_okButton setHidden:YES];
    [_doneButton setHidden:YES];
}


#pragma mark - Notifications

- (void)transferWasCanceled:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self setState:PBTransferProgressViewControllerStateCanceled];
}

- (void)progressUpdated:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(transferFinishedDelayedUIUpdate)
                                               object:nil];

    if ((nil == [PBAppDelegate sharedDelegate].transferSession) ||
        [PBAppDelegate sharedDelegate].transferSession.isCanceled) {
        return;
    }

    NSDictionary *userInfo = notification.userInfo;
    if (userInfo[kPBDeviceType]) {
        self.deviceType = userInfo[kPBDeviceType];
        self.deviceName = userInfo[kPBDeviceName];
        [self updateDeviceLabels];
    }
    
    PBTransferProgressViewControllerState newState = _state;
    NSString *notificationName = notification.name;
    if ([notificationName isEqualToString:PBMongooseServerGetBodyProgressDidUpdateNotification]) {
        newState = PBTransferProgressViewControllerStateDownloading;
    } else if ([notificationName isEqualToString:PBMongooseServerPostBodyProgressDidUpdateNotification]) {
        newState = PBTransferProgressViewControllerStateUploading;
    } else if ([notificationName isEqualToString:PBAssetUploaderUploadProgressDidUpdateNotification]) {
        newState = PBTransferProgressViewControllerStateDownloading;
    }
    if (_state != newState) {
        [self setState:newState];
    }
    
    NSNumber *progressNum = userInfo[kPBProgress];
    CGFloat progress = [progressNum floatValue];
    [_progressIndicator setProgress:progress animated:YES];
}

- (void)checkIfFinishedNotificationReceived {
    if (_state < 3) {
        [self transferFinished:nil];
    }
}

- (void)transferFinished:(NSNotification *)notification {
    if (_state == PBTransferProgressViewControllerStateCanceled) {
        return;
    }

    if ((nil != [PBAppDelegate sharedDelegate].transferSession) &&
        ![PBAppDelegate sharedDelegate].transferSession.isCanceled)
    {
        return;
    }

    [_progressIndicator setProgress:1 animated:YES];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(transferFinishedDelayedUIUpdate)
                                               object:nil];
    
    [self performSelector:@selector(transferFinishedDelayedUIUpdate)
               withObject:nil
               afterDelay:4.0];
}

- (void)transferFinishedDelayedUIUpdate {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(transferFinishedDelayedUIUpdate)
                                               object:nil];
    
    if ([[PBAssetManager sharedManager] isImportAssetInProgress]) {
        [self setState:PBTransferProgressViewControllerStateImporting];
        [self transferFinished:nil];
        return;
    }

    PBTransferProgressViewControllerState newState;
    if (_state == PBTransferProgressViewControllerStateDownloading) {
        newState = PBTransferProgressViewControllerStateDownloadFinished;
        
        if ([_defaults valueForKey:kPBEmailRegistered] == nil) {
            NSInteger numberOfTimesPhotosWereSent = [_defaults integerForKey:kPBNumberOfTimesPhotosWereSent];
            numberOfTimesPhotosWereSent++;
            [_defaults setInteger:numberOfTimesPhotosWereSent forKey:kPBNumberOfTimesPhotosWereSent];
            [_defaults synchronize];
            
            if ((numberOfTimesPhotosWereSent == 1) ||
                (numberOfTimesPhotosWereSent == 2) ||
                (numberOfTimesPhotosWereSent == 10) ||
                (numberOfTimesPhotosWereSent == 25)) {
                
                _shouldPresentSubscribeViewController = YES;
            }
        }
        if (![_defaults boolForKey:kPBUserRatedApp]) {
            NSInteger numberOfDownloads = [_defaults integerForKey:kPBNumberOfTimesPhotosWereSentForRate];
            numberOfDownloads++;
            [_defaults setInteger:numberOfDownloads forKey:kPBNumberOfTimesPhotosWereSentForRate];
            [_defaults synchronize];
            
            //check number of sendings
            if ((numberOfDownloads == 3) || (numberOfDownloads == 5) || (numberOfDownloads == 15) || (numberOfDownloads == 26)) {
                NSDate *lastShownDate = [_defaults valueForKey:kPBLastDateRateWasShown];
                if (lastShownDate == nil || [lastShownDate isEqual:[NSNull null]] || [[NSDate date] timeIntervalSinceDate:lastShownDate] >= 24*60*60) {
                    _shouldPresentRateViewController = YES;
                    
                    [_defaults setValue:[NSDate date] forKey:kPBLastDateRateWasShown];
                    [_defaults synchronize];
                }
            }
        }
    }
    else {
        newState = PBTransferProgressViewControllerStateUploadFinished;
    }
    
    [self setState:newState];

    // If uploud was initiated from browser (without transfer session)
    // and application is in background - here server could be stoped
    if ((nil == [PBAppDelegate sharedDelegate].transferSession)) {
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            [[PBAppDelegate sharedDelegate] endBackgroundTask];
        }
    }
}


#pragma mark - Actions

- (IBAction)okButtonTapped:(id)sender {
    [self performSelector:_okButtonAction];
}

- (void)cancelTransfer {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self setState:PBTransferProgressViewControllerStateCanceled];

    // Cancel transfer
    PBTransferSession *session = [PBAppDelegate sharedDelegate].transferSession;
    [session cancel];
}

- (void)finishTransfer {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kPBImportAssetsFinishedNotification
        object:nil];

    [self dismiss];
}

- (void)dismiss {
    UIViewController *presentingVC = self.presentingViewController;
    [presentingVC dismissViewControllerAnimated:YES
         completion:^{
             if (_shouldPresentSubscribeViewController) {
                 PBSubscribeViewController *vc = [[PBSubscribeViewController new] autorelease];
                 vc.modalPresentationStyle = UIModalPresentationFormSheet;
                 [presentingVC presentViewController:vc
                                            animated:YES
                                          completion:nil];
             }
             else if (_shouldPresentRateViewController) {
                 RD2RateThisAppManager *rateManager = [RD2RateThisAppManager sharedManager];
                 [rateManager setApplicationITunesID:PB_APPSTORE_ID];
                 [rateManager setAppName:PB_APP_NAME];
                 [rateManager presentAskForRateController];
             }
         }];
}

@end
