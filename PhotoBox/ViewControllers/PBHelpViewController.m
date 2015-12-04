//
//  PBHelpViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 20/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Social/Social.h>
#import <Twitter/Twitter.h>
#import "PBHelpViewController.h"
#import "PBWebViewController.h"
#import "PBSubscribeViewController.h"
#import "RD2RateThisAppManager.h"
#import <DropboxSDK/DropboxSDK.h>
//#import "PBGoogleDriveUploadingEngine.h"
#import "PBGoogleAuthViewController.h"
#import "GTLDrive.h"
#import "PBFlickrUploadingEngine.h"
#import "PBAppDelegate.h"
#import "RSReachability.h"

static NSString *kCellIdentifier = @"cellId";

@interface PBHelpViewController () {
    NSMutableArray *_sections;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
//@property (nonatomic, retain) PBGoogleDriveUploadingEngine *googleDriveUploadingEngine;
@end

@implementation PBHelpViewController

+ (NSString *)shareThisAppText {
    return NSLocalizedString(@"Image Transfer, the easiest and fastest way to send and receive photos on your iPhone", @"Text for emails and social networks post");
}

+ (UITableView *)tableViewWithFrame:(CGRect)frame {
    UITableView *tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped] autorelease];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.backgroundColor = [UIColor defaultBackgroundColor];
    tableView.backgroundView = [[UIView new] autorelease];
    tableView.backgroundView.backgroundColor = tableView.backgroundColor;
    tableView.separatorColor = [UIColor defaultTableViewSeparatorColor];

    return tableView;
}

+ (NSDictionary *)cellDictionaryWithTitle:(NSString *)title
                                    image:(UIImage *)image
                                   action:(SEL)action {

    if (!title || !image || !action) {
        return nil;
    }

    return @{
             kPBTitle : title,
             kPBImage : image,
             kPBAction : NSStringFromSelector(action)
             };
}

+ (NSArray *)tableViewCells {
    NSMutableArray *cells = [NSMutableArray arrayWithCapacity:0];

    //1st section
    {
        NSMutableArray *section = [NSMutableArray array];
        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Troubleshooting", @"")
                                                           image:[UIImage imageNamed:@"troubleshooting_icon"]
                                                          action:@selector(troubleshootingCellSelected)]];

        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Support", @"")
                                                           image:[UIImage imageNamed:@"support_icon"]
                                                          action:@selector(supportCellSelected)]];

#if PB_LITE
        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Restore purchases", @"")
                                                           image:[UIImage imageNamed:@"restore_icon"]
                                                          action:@selector(restorePurchasesCellSelected)]];
#endif

        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Register Image Transfer", @"")
                                                           image:[UIImage imageNamed:@"news_icon"]
                                                          action:@selector(subscribeToNewsCellSelected)]];
        


        [cells addObject:section];
    }

    //2nd section
    {
        NSMutableArray *section = [NSMutableArray array];
        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Rate This App", @"")
                                                           image:[UIImage imageNamed:@"rate_app_icon"]
                                                          action:@selector(rateThisAppCellSelected)]];

        if (PBGetSystemVersion() >= 6.0) {
            [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Share via Facebook", @"")
                                                               image:[UIImage imageNamed:@"fcebook_icon"]
                                                              action:@selector(shareFacebookCellSelected)]];
        }

        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Share via Twitter", @"")
                                                           image:[UIImage imageNamed:@"twitter_icon"]
                                                          action:@selector(shareTwitterCellSelected)]];

        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Share via Email", @"")
                                                           image:[UIImage imageNamed:@"mail_icon"]
                                                          action:@selector(shareEmailCellSelected)]];


        [cells addObject:section];
    }

    //3rd section
    {
        NSMutableArray *section = [NSMutableArray array];
        [section addObject:[[self class] cellDictionaryWithTitle:[[DBSession sharedSession] isLinked] ? [NSString stringWithFormat:NSLocalizedString(@"Logout from %@", @""), @"Dropbox"] : [NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"Dropbox"]
                                                           image:[UIImage imageNamed:@"icon_dropbox"]
                                                          action:@selector(dropboxLoggingStuff)]];
        [section addObject:[[self class] cellDictionaryWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"GoogleDrive"]
                                                           image:[UIImage imageNamed:@"icon_google"]
                                                          action:@selector(googleDriveLoggingStuff)]];
        
        BOOL hasAuthToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"FlickrOAuthToken"] && [[NSUserDefaults standardUserDefaults] objectForKey:@"FlickrOAuthTokenSecret"];
        [section addObject:[[self class] cellDictionaryWithTitle:hasAuthToken ? [NSString stringWithFormat:NSLocalizedString(@"Logout from %@", @""), @"Flickr"] : [NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"Flickr"]
                                                           image:[UIImage imageNamed:@"icon_flickr"]
                                                          action:@selector(flickrLoggingStuff)]];
        [cells addObject:section];
    }
    
    
    //4rd section
    {
        NSMutableArray *section = [NSMutableArray array];
        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Legal Notes", @"")
                                                           image:[UIImage imageNamed:@"legal_notes_icon"]
                                                          action:@selector(legalNotesCellSelected)]];
        [cells addObject:section];
    }

    //    //4th section
    //    {
    //        NSMutableArray *section = [NSMutableArray array];
    //        [section addObject:[self cellDictionaryWithTitle:<#(NSString *)#>
    //                                                   image:[UIImage imageNamed:<#(NSString *)#>]
    //                                                  action:@selector(<#selector#>)]];
    //        [_sections addObject:section];
    //    }
    
    return cells;
}

+ (UINib *)tableViewCellNib {
    UINib *nib = [UINib nibWithNibName:@"PBHelpTableViewCell" bundle:nil];
    return nib;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Help", @"");
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"DropboxAccountSucessfullyLinked"
                                                  object:nil];
    [_sections removeAllObjects];
    [_sections release];

    _sections = nil;

    [_tableView release];
    _tableView = nil;
    
    [super dealloc];
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem =
        [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
            style:UIBarButtonItemStylePlain
            target:self
            action:@selector(closeButtonTapped:)]
        autorelease];

    self.navigationItem.backBarButtonItem =
        [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
            style:UIBarButtonItemStylePlain
            target:nil
            action:nil]
        autorelease];


    _sections = [NSMutableArray new];
    [_sections addObjectsFromArray:[[self class] tableViewCells]];

    if (nil == self.tableView) {
        self.tableView = [[self class] tableViewWithFrame:self.view.bounds];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self.view addSubview:self.tableView];
    }

    UINib *cellNib = [[self class] tableViewCellNib];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kCellIdentifier];
}


#pragma mark - Actions

-(void)postNotificationNoConnection {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NoInternetConnectionForSending" object:nil];
    
}

-(void)flickrLoggingStuff {
    if ([[RSReachability RSReachabilityForInternetConnection] currentRSReachabilityStatus] == RSNotReachable) {
        [self performSelector:@selector(postNotificationNoConnection) withObject:self afterDelay:0.2];
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    
    UITableViewCell *dropboxCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2]];
    
    PBAppDelegate *appDelegate = (PBAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (![appDelegate.flickrEngine isAuthorized]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PBHelpViewControllerLoggingToFlickr"
                                                            object:nil];
        [appDelegate.flickrEngine startAuthentification];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    else { //logout
        [appDelegate.flickrEngine setAndStoreFlickrAuthToken:nil secret:nil];
        
        PBAlertOK([NSString stringWithFormat:NSLocalizedString(@"Logout from %@", @""), @"Flickr"],
                  [NSString stringWithFormat:NSLocalizedString(@"You have sucessfully logged out from %@ account.", @""), @"Flickr"]);
        dropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"Flickr"];
        
    }
}

 - (void)dropboxLoggingStuff {
     if ([[RSReachability RSReachabilityForInternetConnection] currentRSReachabilityStatus] == RSNotReachable) {
         [self performSelector:@selector(postNotificationNoConnection) withObject:self afterDelay:0.2];
         [self dismissViewControllerAnimated:NO completion:nil];
         return;
     }
     
    UITableViewCell *dropboxCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    
    if (![[DBSession sharedSession] isLinked]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PBHelpViewControllerLoggingToDropbox"
                                                            object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dropboxLoginSuccessfully)
                                                     name:@"DropboxAccountSucessfullyLinked"
                                                   object:nil];
        
        [[DBSession sharedSession] linkFromController:self];
        
    }
    else {
        [[DBSession sharedSession] unlinkAll];
        
        PBAlertOK([NSString stringWithFormat:NSLocalizedString(@"Logout from %@", @""), @"Dropbox"],
              [NSString stringWithFormat:NSLocalizedString(@"You have sucessfully logged out from %@ account.", @""), @"Dropbox"]);
        dropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"Dropbox"];
        
    }
}

- (void)dropboxLoginSuccessfully {
    UITableViewCell *dropboxCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    dropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Logout from %@", @""), @"Dropbox"];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"DropboxAccountSucessfullyLinked"
                                                  object:nil];
}

-(void)googleDriveLoggingStuff {
    if ([[RSReachability RSReachabilityForInternetConnection] currentRSReachabilityStatus] == RSNotReachable) {
        [self performSelector:@selector(postNotificationNoConnection) withObject:self afterDelay:0.2];
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    
    UITableViewCell *dropboxCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
    PBAppDelegate *appDelegate = (PBAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (![appDelegate.googleDriveEngine isAuthorized]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PBHelpViewControllerLoggingToGoogle"
                                                            object:nil];
        [self performSelector:@selector(showGoogleAuthorizationController)
                   withObject:nil
                   afterDelay:0.2];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    else {
        [PBGoogleAuthViewController removeAuthFromKeychainForName:PB_GOOGLE_KEYCHAIN_ITEM_NAME];
        [appDelegate.googleDriveEngine setAuthorizer:nil];
        
        PBAlertOK([NSString stringWithFormat:NSLocalizedString(@"Logout from %@", @""), @"GoogleDrive"],
                  [NSString stringWithFormat:NSLocalizedString(@"You have sucessfully logged out from %@ account.", @""), @"GoogleDrive"]);
        dropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"GoogleDrive"];
    }
}

-(void)showGoogleAuthorizationController {
    PBAppDelegate *appDelegate = (PBAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showGoogleAuthorizationController];
}

#pragma mark -

- (void)closeButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)troubleshootingCellSelected {
    PBWebViewController *wvc = [[[PBWebViewController alloc] initWithTitle:nil htmlName:@"troubleshooting"] autorelease];
    [self.navigationController pushViewController:wvc animated:YES];
    
    //analytics
    NSDictionary *params = @{ @"item" : @"troubleshooting"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}

- (void)supportCellSelected {
    [[PBAppDelegate sharedDelegate] presentContactSupportEmailComposeViewControllerFromViewController:self];
    
    //analytics
    NSDictionary *params = @{ @"item" : @"contactSupport"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}

- (void)legalNotesCellSelected {
    PBWebViewController *wvc = [[[PBWebViewController alloc] initWithTitle:@"Legal Notes" htmlName:@"legal"] autorelease];
    [self.navigationController pushViewController:wvc animated:YES];
    
    //analytics
    NSDictionary *params = @{@"item" : @"legalNotes"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}

- (void)rateThisAppCellSelected {
    RD2RateThisAppManager *rateManager = [RD2RateThisAppManager sharedManager];
    [rateManager setApplicationITunesID:PB_APPSTORE_ID];
    [rateManager setAppName:PB_APP_NAME];
    [rateManager presentAskForRateController];


    //analytics
    NSDictionary *params = @{@"item" : @"rateThisApp"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}

- (void)shareFacebookCellSelected {
    if (PBGetSystemVersion() >= 6.0) {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];

            NSString *textToShare = [[self class] shareThisAppText];
            [composeVC setInitialText:textToShare];
            [composeVC addURL:PBAppstoreAppUrl()];
            [composeVC addImage:[UIImage imageNamed:@"application_icon_114x114"]];
            
            [self presentViewController:composeVC
                               animated:YES
                             completion:nil];
        } else {
            PBAlertOK(NSLocalizedString(@"No Facebook account", @""),
                      NSLocalizedString(@"There are no Facebook accounts configured. You can add or create a Facebook account in the Settings app.", @""));
        }
    }
    
    //analytics
    NSDictionary *params = @{ @"item" : @"shareViaFacebook", @"shareService" : @"facebook"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}

- (void)shareTwitterCellSelected {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];

        NSString *textToShare = [[self class] shareThisAppText];
        [composeVC setInitialText:textToShare];
        [composeVC addURL:PBAppstoreAppUrl()];
        
        [self presentViewController:composeVC
                           animated:YES
                         completion:nil];
    } else {
        PBAlertOK(NSLocalizedString(@"No Twitter account", @""),
                  NSLocalizedString(@"There are no Twitter accounts configured. You can add or create a Twitter account in the Settings app.", @""));
    }
    
    //analytics
    NSDictionary *params = @{ @"item" : @"shareViaTwitter", @"shareService" : @"twitter"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
    
}

- (void)shareEmailCellSelected {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mvc = [[MFMailComposeViewController new] autorelease];
        mvc.mailComposeDelegate = self;

        NSString *textToShare = [[self class] shareThisAppText];
        [mvc setSubject:textToShare];
        
        NSString *body = [NSString stringWithFormat:@"%@\n\n%@", textToShare, PBAppstoreAppUrl()];
        [mvc setMessageBody:body isHTML:NO];
        
        mvc.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:mvc
                           animated:YES
                         completion:nil];
    } else {
        PBAlertOK(NSLocalizedString(@"No email account", @""),
                  NSLocalizedString(@"There are no email accounts configured. You can add or create email account in the Settings app.", @""));
    }
    
    //analytics
    NSDictionary *params = @{ @"item" : @"shareViaEmail", @"shareService" : @"email"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}

- (void)subscribeToNewsCellSelected {
    PBSubscribeViewController *vc = [[PBSubscribeViewController new] autorelease];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
        [self presentChildViewController:nc];
    } else {
        [self presentViewController:vc
                           animated:YES
                         completion:nil];
    }
    
    //analytics
    NSDictionary *params = @{ @"item" : @"registerApp"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}

- (void)restorePurchasesCellSelected {
#if PB_LITE
    [[PBPurchaseManager sharedManager] restorePurchasedProducts];
#endif
}


#pragma mark - 

- (void)presentChildViewController:(UIViewController *)controller {
    [self presentChildViewController:controller hideNavigationBar:YES];
}

- (void)presentChildViewController:(UIViewController *)controller hideNavigationBar:(BOOL)hideNavigationBar {
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];

    CGRect targetFrame = (hideNavigationBar) ? self.view.bounds : self.tableView.frame;
    CGRect initialFrame =  targetFrame;
    initialFrame.origin.y = initialFrame.size.height;

    [controller.view setFrame:initialFrame];
    [self.view addSubview:controller.view];

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         [controller.view setFrame:targetFrame];
                     }
                     completion:^(BOOL finished) {
                         if ((nil != self.navigationController) && hideNavigationBar) {
                             [self.navigationController setNavigationBarHidden:YES animated:NO];
                         }
                     }];
}

- (void)dismissPresentedViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    UIViewController *childController = [self.childViewControllers lastObject];

    if (nil == childController) {
        [super dismissViewControllerAnimated:flag completion:completion];
    }
    else {
        if (nil != self.navigationController) {
            [self.navigationController setNavigationBarHidden:NO animated:NO];
        }

        CGRect targetFrame = self.view.bounds;
        targetFrame.origin.y = targetFrame.size.height;
        
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionLayoutSubviews
                         animations:^{
                             [childController.view setFrame:targetFrame];
                         }
                         completion:^(BOOL finished) {
                             [childController.view removeFromSuperview];
                             [childController removeFromParentViewController];
                         }];
    }
}


#pragma mark - UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_sections[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];

    NSDictionary *cellDictionary = _sections[indexPath.section][indexPath.row];
    if ((indexPath.section == 2) && (indexPath.row == 1)) {
        PBAppDelegate *appDelegate = (PBAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        cell.textLabel.text = [appDelegate.googleDriveEngine isAuthorized] ? [NSString stringWithFormat:NSLocalizedString(@"Logout from %@", @""), @"GoogleDrive"] : [NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"GoogleDrive"];
    }
    else {
        cell.textLabel.text = cellDictionary[kPBTitle];
    }
    cell.imageView.image = cellDictionary[kPBImage];
    
    return cell;
}


#pragma mark - UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *cellDictionary = _sections[indexPath.section][indexPath.row];
    SEL action = NSSelectorFromString(cellDictionary[kPBAction]);
    [self checkAndPerformSelector:action];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (section == 0) {
            return NSLocalizedString(@"Support", @"");
        } else if (section == 1) {
            return NSLocalizedString(@"Share This App", @"");
        } else if (section == 2) {
            return NSLocalizedString(@"Legal Notes", @"");
        }
    }
    
    return nil;
}


#pragma mark - MFMailComposeViewControllerDelegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {

    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 
                             }];
}

@end
