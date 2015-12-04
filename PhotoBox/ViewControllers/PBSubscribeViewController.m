//
//  PBSubscribeViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 30/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBSubscribeViewController.h"
#import "PBStretchableBackgroundButton.h"
#import "RDHTTP.h"

@interface PBSubscribeViewController () <UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UITextField *textField;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *subscribeButton;
@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *skipButton;

@end

@implementation PBSubscribeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Register Image Transfer", @"");
    }
    return self;
}

- (void)dealloc {
    [_scrollView release];
    _scrollView = nil;

    [_textField release];
    _textField = nil;

    [_activityIndicator release];
    _activityIndicator = nil;

    [_subscribeButton release];
    _subscribeButton = nil;

    [_skipButton release];
    _skipButton = nil;

    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *emailRegistered = [[NSUserDefaults standardUserDefaults] valueForKey:kPBEmailRegistered];
    if (emailRegistered) {
        _textField.text = emailRegistered;
    }

    //close button
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIBarButtonItem *closeButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(dismiss)] autorelease];

        self.navigationItem.rightBarButtonItem = closeButton;
        if (self.navigationController == nil) {
            _skipButton.hidden = NO;
        }
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self updateScrollView];
}

- (void)enableControls:(BOOL)enabled {
    _subscribeButton.enabled = enabled;
    _skipButton.enabled = enabled;
    _textField.enabled = enabled;
    
    if (enabled) {
        [_activityIndicator stopAnimating];
    } else {
        [_activityIndicator startAnimating];
    }
}

- (void)dismiss {
    // TODO: Get rid of it!!! Parent controller must dismiss child

    if ((nil != self.navigationController) &&
        (nil != self.navigationController.parentViewController)) {
        
        [self.navigationController.parentViewController
            dismissViewControllerAnimated:YES
            completion:nil];
    }
    else if (nil != self.parentViewController) {
        [self.parentViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - Actions

- (IBAction)registerButtonTapped:(id)sender {
    NSString *email = _textField.text;
    if ([email isValidEmail] == NO) {
        PBAlertOK(NSLocalizedString(@"This email is not valid", @""), nil);
        return;
    }
    
    [self enableControls:NO];

    // Values: free/paid/plus
    NSString *applicationPrice;

#if PB_LITE
    applicationPrice = ([[PBAppDelegate sharedDelegate] isFullVersion])
        ? @"plus"
        : @"free";
#else
    applicationPrice = @"paid";
#endif

    // Values: iphone/ipad
    NSString *deviceType = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        ? @"ipad"
        : @"iphone";

    NSString *applicationName = PB_APP_NAME;

    NSString *requestFormat = @"http://sendp.com/subscribe.php?email=%@&app_price=%@&device=%@&app_name=%@";
    NSString *requestAddress = [NSString stringWithFormat:requestFormat, email, applicationPrice, deviceType, applicationName];
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURLString:requestAddress];
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil && response.statusCode == 200) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setValue:email forKey:kPBEmailRegistered];
            [defaults synchronize];
            
            
            //analytics
            NSInteger numberOfTimesPhotosWereSent = [defaults integerForKey:kPBNumberOfTimesPhotosWereSent];
            NSInteger numberOfTimesAppWereLaunched = [defaults integerForKey:kPBNumberOfTimesAppWereLaunched];
            NSDictionary *parameters = @{
                @"numberOfTimesPhotosWereSent" : [NSString stringWithInteger:numberOfTimesPhotosWereSent],
                @"numberOfTimesAppWereLaunched": [NSString stringWithInteger:numberOfTimesAppWereLaunched]
            };
            [[CBAnalyticsManager sharedManager] logEvent:@"emailRegistered"
                                          withParameters:parameters];
            
            
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            PBAlertOK(NSLocalizedString(@"Oops!", @""),
                      NSLocalizedString(@"Failed to register: something went wrong.", @""));
            NSLog(@"Failed to register email: %@", response.error);
        }
        
        [self enableControls:YES];
    }];
}

- (IBAction)skipButtonTapped:(id)sender {
    [self dismiss];
}


#pragma mark - TextField Delegate

- (void)updateScrollView {
    CGRect bounds = self.view.bounds;
    CGSize size = bounds.size;
    CGFloat width = size.width;
    CGFloat height = size.height;

    if (_textField.isFirstResponder) {
        CGFloat keyboardHeight = 210;
        CGFloat h = height + keyboardHeight;
        
        _scrollView.contentSize = CGSizeMake(width, h);
        
        [_scrollView scrollRectToVisible:CGRectMake(0, 0, width, h-60) animated:YES];
    } else {
        CGRect bounds = self.view.bounds;
        CGSize size = bounds.size;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             _scrollView.contentSize = size;
                         }];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self updateScrollView];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateScrollView];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return NO;
}

@end
