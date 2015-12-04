//
//  PBUploadToDropboxViewController.m
//  PhotoBox
//
//  Created by Dara on 25.03.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import "PBCommonUploadToViewController.h"

#import "PBAssetManager.h"
#import "PBStretchableBackgroundButton.h"
#import "TTTAttributedLabel.h"
#import "PBAssetUploader.h"
#import <MessageUI/MessageUI.h>
#import "PBProgressIndicator.h"
#import "PBSubscribeViewController.h"
#import "RD2RateThisAppManager.h"

typedef enum {
    PBUploadToViewControllerStateUploading = 0,
    PBUploadToViewControllerStateUploadFinished,
    PBUploadToViewControllerStateCanceled
} PBUploadToViewControllerState;

@interface PBCommonUploadToViewController () <UIAlertViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
    SEL _okButtonAction;
    BOOL _shouldPresentSubscribeViewController;
    BOOL _shouldPresentRateViewController;
}
@property (retain, nonatomic) IBOutlet UIView *contentContainerView;
@property (retain, nonatomic) IBOutlet UILabel *transferringLabel;

@property (retain, nonatomic) IBOutlet UIView *finishedContentContainerView;
@property (nonatomic) PBUploadToViewControllerState currentState;
@property (retain, nonatomic) IBOutlet UIImageView *transferAnimationImageView;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *importingActivityIndicatorView;
@property (retain, nonatomic) IBOutlet UIImageView *finishedImageView;
@property (retain, nonatomic) IBOutlet UIImageView *transferCanceledImageView;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *okButton;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *doneButton;
@property (retain, nonatomic) IBOutlet UILabel *titleLable;
@property (retain, nonatomic) IBOutlet TTTAttributedLabel *messageLabel;

@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *copLinkButton;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *iMessageButton;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *eMailButton;
@property (retain, nonatomic) IBOutlet UILabel *sendToLabel;

@property (nonatomic, strong) NSMutableArray *assetURLs;
@property (nonatomic) NSInteger assetIndex;
@property (nonatomic, strong) NSString *assetFilePath;
@property (nonatomic, strong) NSString *destinationFolderName;

@property (retain, nonatomic) IBOutlet UIImageView *receiveImageV;
@property (retain, nonatomic) IBOutlet PBProgressIndicator *progressIndicator;

@end

@implementation PBCommonUploadToViewController


-(NSMutableArray *)assetURLs {
    if (!_assetURLs) {
        _assetURLs = [[NSMutableArray alloc] init];
    }
    return _assetURLs;
}

#pragma mark -
#pragma mark Uploading engine notifications selectors
#pragma mark -

-(void)uploadingFolderCreated {
    self.assetIndex = 0;
    [self sendNextAsset];
}

-(void)uploadProgressReceived {
    [self.progressIndicator setProgress:self.uploadingEngine.uploadingProgress animated:self.uploadingEngine.uploadingProgress > 0 ? YES:NO];
}

-(void)successfullyUploadedFile {
    self.assetIndex ++;
   /* CGFloat progressValue = (CGFloat)self.assetIndex/(CGFloat)[self.assetURLs count];
    [self.progressIndicator setProgress:progressValue
                               animated:progressValue > 0 ? YES : NO];*/
    [self sendNextAsset];
}

-(void)failedUploadingFile {
    UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unexpected network error.", @"")
                                                             message:NSLocalizedString(@"Please, check your internet connection and try again.", @"")
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
    [errorAlertView show];
}


#pragma mark -

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *imageName = @"receive_screen_mac_or_pc_selected";
    if ([self.uploadingEngine.engineName isEqualToString:@"Flickr"]) {
        imageName = @"receive_flickr";
    }
    else if ([self.uploadingEngine.engineName isEqualToString:@"Dropbox"]) {
        imageName = @"receive_dropbox";
    }
    else if ([self.uploadingEngine.engineName isEqualToString:@"GoogleDrive"]) {
        imageName = @"receive_google";
    }
    
    self.receiveImageV.image = [UIImage imageNamed:imageName];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadingFolderCreated)
                                                 name:@"FolderCreatedByUploadingEngine"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadProgressReceived)
                                                 name:@"UploadProgressReceivedByUploadingEngine"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(successfullyUploadedFile)
                                                 name:@"SuccessfullyUploadedFileByUploadingEngine"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(failedUploadingFile)
                                                 name:@"FailedUploadingFileByUploadingEngine"
                                               object:nil];
    
    
    NSRange range = [PB_APP_NAME rangeOfString:@"ImageTransfer" options:NSCaseInsensitiveSearch];

    if (range.location == NSNotFound) {
        [self.doneButton setBackgroundImage:[UIImage imageNamed:@"upgrade_button.png"] forState:UIControlStateNormal];
        [self.okButton setBackgroundImage:[UIImage imageNamed:@"cancel_button_pressed.png"] forState:UIControlStateNormal];
        [self.copLinkButton setBackgroundImage:[UIImage imageNamed:@"cancel_button_pressed.png"] forState:UIControlStateNormal];
        [self.iMessageButton setBackgroundImage:[UIImage imageNamed:@"cancel_button_pressed.png"] forState:UIControlStateNormal];
        [self.eMailButton setBackgroundImage:[UIImage imageNamed:@"cancel_button_pressed.png"] forState:UIControlStateNormal];
        
    }
    
    self.showTopToolbar = NO;
    
    self.uploadingEngine.sharableLinkOnFolder = @"";
    self.destinationFolderName = @"";
    
    self.progressIndicator.backgroundImage = [UIImage imgNamed:@"progressbar_bg"];
    self.progressIndicator.progressImage = [UIImage imgNamed:@"progressbar_uploaded"];
    [self.progressIndicator setProgress:0.0 animated:NO];
    
    self.contentContainerView.backgroundColor = [UIColor clearColor];
    
    self.finishedContentContainerView.hidden = YES;
    
    if ([self.uploadingEngine isAuthorized]) {
        [self prepareForUploading];
    }

}

#pragma mark - uploading to DropBox

-(void)prepareForUploading {
    NSArray *assets = [[PBAssetManager sharedManager] assetExportList];
    [self.assetURLs removeAllObjects];
    [self.assetURLs addObjectsFromArray:assets];
    
    if ([self.assetURLs count] > 0) {
        [self startTransferAnimation];
        [self setState:PBUploadToViewControllerStateUploading];
        
        NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
        self.destinationFolderName = [dateFormatter stringFromDate:[NSDate date]];

        [self.uploadingEngine createFolderForUploading:self.destinationFolderName];
    }
  
}


-(void)sendNextAsset {
    NSError *error = nil;
    if (self.assetFilePath) {
        if (![[NSFileManager defaultManager] removeItemAtPath:self.assetFilePath error:&error]) {
            NSLog(@"Failed to remove item at path %@; error == %@", self.assetFilePath, error.description);
        }
    }
  
    if (self.currentState != PBUploadToViewControllerStateUploading) {
        return;
    }
    
    if (self.assetIndex > [self.assetURLs count]-1) {
        [self finishUploadind];
        return;
    }
    
    [self.progressIndicator setProgress:0.0 animated:NO];
    
    NSURL *assetURLToSend = self.assetURLs[self.assetIndex];
    ALAsset *asset = [[PBAssetManager sharedManager] assetForUrl:assetURLToSend];
    NSString *assetFilename = asset.defaultRepresentation.filename;
    
    NSLog(@"Uploading to %@ file %@", self.uploadingEngine.engineName, assetFilename);
    
    self.assetFilePath = [[PBAssetManager sharedManager] writeAssetToTempFile:asset progressHandler:nil];
    if (self.assetFilePath) {
        // Upload file
        NSString *destDir = [NSString stringWithFormat:@"/%@", self.destinationFolderName];
        
        [self.uploadingEngine uploadFile:assetFilename toPath:destDir fromPath:self.assetFilePath];
    }
    else {
        NSLog(@"Error creating temp file for %@", assetFilename);
    }
}

-(void)finishUploadind {
    [self.progressIndicator setProgress:1.0 animated:YES];
    [self performSelector:@selector(finishUploadingUI)
               withObject:nil
               afterDelay:0.7];

}

-(void)finishUploadingUI {
    [self setState:PBUploadToViewControllerStateUploadFinished];
}

-(void)cancelUploading {
    [self.uploadingEngine cancelUploading];
    
    [self setState:PBUploadToViewControllerStateCanceled];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self cancelUploading];
       [[NSNotificationCenter defaultCenter] postNotificationName:@"NoInternetConnectionForSending" object:nil];
        // [self performSelector:@selector(postNotificationNoConnection) withObject:self afterDelay:0.2];
    }
}

#pragma mark -
- (void)setState:(PBUploadToViewControllerState)state {

    self.currentState = state;
    
    if (state == PBUploadToViewControllerStateUploading) {

        self.transferringLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Transferring photos to %@. This might take up to few minutes.", @""), self.uploadingEngine.engineName];
        self.titleLable.text = NSLocalizedString(@"Sending Photos", @"");
        self.sendToLabel.text = self.uploadingEngine.engineName;
        self.progressIndicator.hidden = NO;
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
        
        [self.copLinkButton setHidden:YES];
        [self.iMessageButton setHidden:YES];
        [self.eMailButton setHidden:YES];
        
        [self showCancelButton];
        
        self.finishedContentContainerView.hidden = YES;
        [self.importingActivityIndicatorView stopAnimating];
        
        self.transferAnimationImageView.transform = CGAffineTransformIdentity;
        [self startTransferAnimation];
        self.contentContainerView.hidden = NO;
    }
    else if (state == PBUploadToViewControllerStateUploadFinished) {
        self.titleLable.text = NSLocalizedString(@"Sending Photos", @"");
        self.messageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photos were successfully sent to %@. You can share link to uploaded folder.", @""), self.uploadingEngine.engineName];
        
        self.finishedImageView.hidden = NO;
        NSString *imageName = @"transfer_smile_iphone";
        if ([self.uploadingEngine.engineName isEqualToString:@"Flickr"]) {
            imageName = @"flickr_big";
        }
        else if ([self.uploadingEngine.engineName isEqualToString:@"Dropbox"]) {
            imageName = @"dropbox_big";
        }
        else if ([self.uploadingEngine.engineName isEqualToString:@"GoogleDrive"]) {
            imageName = @"google_big";
        }
        self.finishedImageView.image = [UIImage imageNamed:imageName];
        
        self.progressIndicator.hidden = YES;
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
        
        if(self.uploadingEngine.sharableLinkOnFolder && ![self.uploadingEngine.sharableLinkOnFolder isEqualToString:@""]) {
            
            [self.copLinkButton setTitle:NSLocalizedString(@"Copy to Clipboard", @"") forState:UIControlStateNormal];
            [self.eMailButton setTitle:NSLocalizedString(@"Send e-mail", @"") forState:UIControlStateNormal];
            [self.iMessageButton setTitle:NSLocalizedString(@"Send iMessage", @"") forState:UIControlStateNormal];
            
            
            [self.copLinkButton setHidden:NO];
            [self.iMessageButton setHidden:NO];
            [self.eMailButton setHidden:NO];
        }
        
        //check if registration or rate is needed
        [self checkIfRegistrationOrRTAIsNeeded];
 
        
        [self showDoneButton];
        
        self.finishedContentContainerView.hidden = NO;
        self.transferCanceledImageView.hidden = YES;
        
        [self.importingActivityIndicatorView stopAnimating];

        [self stopTransferAnimation];
        self.contentContainerView.hidden = YES;
    }
    else if (state == PBUploadToViewControllerStateCanceled) {
        self.titleLable.text = NSLocalizedString(@"Aw, Snap!", @"Aw, Snap!");
        
        self.messageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Uploading to %@ was canceled.", @""), self.uploadingEngine.engineName];
        
        self.transferCanceledImageView.hidden = NO;
        self.transferCanceledImageView.image = [UIImage imgNamed:@"sad_iphone_snap"];
        self.progressIndicator.hidden = YES;
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
        
        [self showDismissButton];
        
        self.finishedContentContainerView.hidden = NO;
        self.finishedImageView.hidden = YES;
        
        [self.importingActivityIndicatorView stopAnimating];
        
        [self stopTransferAnimation];
        self.contentContainerView.hidden = YES;
    }
}

- (void)checkIfRegistrationOrRTAIsNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults valueForKey:kPBEmailRegistered] == nil) {
        NSInteger numberOfTimesPhotosWereSent = [defaults integerForKey:kPBNumberOfTimesPhotosWereSent];
        numberOfTimesPhotosWereSent++;
        [defaults setInteger:numberOfTimesPhotosWereSent forKey:kPBNumberOfTimesPhotosWereSent];
        [defaults synchronize];
        
        if ((numberOfTimesPhotosWereSent == 1) ||
            (numberOfTimesPhotosWereSent == 2) ||
            (numberOfTimesPhotosWereSent == 10) ||
            (numberOfTimesPhotosWereSent == 25)) {
            
            _shouldPresentSubscribeViewController = YES;
        }
    }
    
    if (![defaults boolForKey:kPBUserRatedApp]) {
        NSInteger numberOfDownloads = [defaults integerForKey:kPBNumberOfTimesPhotosWereSentForRate];
        numberOfDownloads++;
        [defaults setInteger:numberOfDownloads forKey:kPBNumberOfTimesPhotosWereSentForRate];
        [defaults synchronize];
        
        //check number of sendings
        if ((numberOfDownloads == 3) || (numberOfDownloads == 5) || (numberOfDownloads == 15) || (numberOfDownloads == 26)) {
            NSDate *lastShownDate = [defaults valueForKey:kPBLastDateRateWasShown];
            if (lastShownDate == nil || [lastShownDate isEqual:[NSNull null]] || [[NSDate date] timeIntervalSinceDate:lastShownDate] >= 24*60*60) {
                _shouldPresentRateViewController = YES;
                
                [defaults setValue:[NSDate date] forKey:kPBLastDateRateWasShown];
                [defaults synchronize];
            }
        }
    }

    
}

- (void)showCancelButton {
    [self hideDoneButton];
    [self hideDismissButton];
    
    _okButtonAction = @selector(cancelUploading);
    
    NSString *title = NSLocalizedString(@"Cancel", @"Cancel");
    [self.okButton setTitle:title forState:UIControlStateNormal];
    self.okButton.selected = NO;
    [self.okButton setHidden:NO];
}
- (void)hideCancelButton {
    [self.okButton setHidden:YES];
}

- (void)showDoneButton {
    [self hideCancelButton];
    [self hideDismissButton];
    
    _okButtonAction = @selector(dismiss);
    
    NSString *title = NSLocalizedString(@"Done", @"Done");
    [self.doneButton setTitle:title forState:UIControlStateNormal];
    [self.okButton setTitle:title forState:UIControlStateNormal];
    self.okButton.selected = YES;

    [self.doneButton setHidden:NO];
}

- (void)hideDoneButton {
    [_doneButton setHidden:YES];
}

- (void)showDismissButton {
    [self hideCancelButton];
    [self hideDoneButton];
    
    NSString *title = NSLocalizedString(@"Done", @"Done");
    [self.okButton setTitle:title forState:UIControlStateNormal];
    self.okButton.selected = YES;
    _okButtonAction = @selector(dismiss);

    [self.doneButton setHidden:NO];
}
- (IBAction)okButtonTapped:(id)sender {
    [self performSelector:_okButtonAction];
}
- (IBAction)copyLinkTappde:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.uploadingEngine.sharableLinkOnFolder;
    
    PBAlertOK(NSLocalizedString(@"Copy to clipboard", @""), [NSString stringWithFormat:NSLocalizedString(@"Shared link on upload %@ folder successfully copied to clipboard.", @""), self.uploadingEngine.engineName]);
}

- (void)hideDismissButton {
    [self.doneButton setHidden:YES];
}
- (IBAction)iMessageTapped:(id)sender {
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *mesVC = [[MFMessageComposeViewController new] autorelease];
        mesVC.messageComposeDelegate = self;
        
        NSShadow *shadow = [NSShadow new];
        [shadow setShadowColor: [UIColor clearColor]];
        
        NSDictionary *titleAttributes = @{
                                          NSShadowAttributeName : shadow,
                                          NSForegroundColorAttributeName : [UIColor defaultTextColor]
                                          };
        [[mesVC navigationBar] setTitleTextAttributes:titleAttributes];
        
        [mesVC.navigationBar setTintColor:[PB_APP_NAME containsString:@"Image"] ? [UIColor orangeColor]:[UIColor redColor]];
        
        [mesVC setSubject:[NSString stringWithFormat:NSLocalizedString(@"%@ shared link", @""), self.uploadingEngine.engineName]];
        
        NSString *advString = [NSString stringWithFormat:@"%@, %@", PB_APP_NAME, NSLocalizedString(@"the easiest and fastest way to send and receive photos on your iPhone", @"")];
        NSString *body = [NSString stringWithFormat:@"%@\n\n%@\n\n%@", self.uploadingEngine.sharableLinkOnFolder, advString, PBAppstoreAppUrl()];
        [mesVC setBody:body];
        
        mesVC.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:mesVC
                           animated:YES
                         completion:nil];
    } else {
        PBAlertOK(@"",
                  NSLocalizedString(@"You can't send iMessages", @""));
    }
}


- (IBAction)emailButtonTapped:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mvc = [[MFMailComposeViewController new] autorelease];
        mvc.mailComposeDelegate = self;
        
        NSShadow *shadow = [NSShadow new];
        [shadow setShadowColor: [UIColor clearColor]];
        
        NSDictionary *titleAttributes = @{
                                          NSShadowAttributeName : shadow,
                                          NSForegroundColorAttributeName : [UIColor defaultTextColor]
                                          };
        [[mvc navigationBar] setTitleTextAttributes:titleAttributes];
        [mvc.navigationBar setTintColor:[PB_APP_NAME containsString:@"Image"] ? [UIColor orangeColor]:[UIColor redColor]];
        
        [mvc setSubject:[NSString stringWithFormat:NSLocalizedString(@"%@ shared link", @""), self.uploadingEngine.engineName]];
        
        NSString *advString = [NSString stringWithFormat:@"%@, %@", PB_APP_NAME, NSLocalizedString(@"the easiest and fastest way to send and receive photos on your iPhone", @"")];
        NSString *body = [NSString stringWithFormat:@"%@\n\n%@\n\n%@", self.uploadingEngine.sharableLinkOnFolder, advString, PBAppstoreAppUrl()];
        [mvc setMessageBody:body isHTML:NO];
        
        mvc.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:mvc
                           animated:YES
                         completion:nil];
    } else {
        PBAlertOK(NSLocalizedString(@"No email account", @""),
                  NSLocalizedString(@"There are no email accounts configured. You can add or create email account in the Settings app.", @""));
    }
}

- (void)dismiss {
    if (self.currentState == PBUploadToViewControllerStateUploadFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PBAssetUploaderUploadDidFinishNotification
                                                            object:nil
                                                          userInfo:nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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

- (void)startTransferAnimation {
    UIImage *frame0 = [UIImage imgNamed:@"transfer_animation_wifi_clean"];
    UIImage *frame1 = [UIImage imgNamed:@"transfer_animation_wifi_1"];
    UIImage *frame2 = [UIImage imgNamed:@"transfer_animation_wifi_2"];
    UIImage *frame3 = [UIImage imgNamed:@"transfer_animation_wifi_3"];
    
    self.transferAnimationImageView.animationImages = @[frame0, frame1, frame2, frame3];
    self.transferAnimationImageView.animationDuration = 1.0;
    [self.transferAnimationImageView startAnimating];
}

- (void)stopTransferAnimation {
    self.transferAnimationImageView.animationImages = nil;
    self.transferAnimationImageView.image = [UIImage imgNamed:@"transfer_animation_wifi_all"];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc {
    [self.uploadingEngine release];
    [self.assetURLs release];
    [self.progressIndicator release];
    [self.contentContainerView release];
    [self.finishedContentContainerView release];
    [self.transferAnimationImageView release];
    [self.activityIndicator release];
    [self.importingActivityIndicatorView release];
    [self.finishedImageView release];
    [self.transferCanceledImageView release];
    [_okButton release];
    [_doneButton release];
    [_titleLable release];
    [_messageLabel release];
    [_iMessageButton release];
    [_eMailButton release];
    [_copLinkButton release];
    [_transferringLabel release];
    [_sendToLabel release];
    [_receiveImageV release];
    [super dealloc];
}

#pragma mark - MFMailComposeViewControllerDelegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 
                             }];
}

#pragma mark - MFMessageComposeViewControllerDelegate protocol

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 
                             }];
}

@end
