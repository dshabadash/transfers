//
//  RD2RateThisAppManager.m
//  rgCalendar
//
//  Created by Viktor Gedzenko on 2/14/13.
//
//

#import "RD2RateThisAppManager.h"
#import "RD2RateThisAppModel.h"
#import "RSReachability.h"
#import "CBAnalyticsManager.h"

#define CUSTOM_MODE YES

@interface RD2RateThisAppManager() {
    RD2RateThisAppModel *model;
    BOOL debugMode;
}

@end

@implementation RD2RateThisAppManager

+ (RD2RateThisAppManager *)sharedManager {
	static RD2RateThisAppManager *instance = nil;
	if (!instance) {
		instance = [RD2RateThisAppManager new];
	}
	return instance;
}

- (id)init {
	if ((self = [super init])) {
        model = [RD2RateThisAppModel new];
        NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];

        // it is revision number in calendar
        // if you have version like 3.5.9, 3.5.10 then conert it correctly
        model.currentVersion = [currentVersion integerValue];
    }
	return self;
}

- (void)dealloc {
    [model release];
    [super dealloc];
}

- (void)registerLaunch {
    model.currentDate = [NSDate date];
    [model registerLaunch];
}

- (void)registerBecomeActive {
    model.currentDate = [NSDate date];
    [model registerBecomeActive];
}

- (BOOL)askForRate {
    debugMode = NO;
    
    if ([[RSReachability RSReachabilityForInternetConnection] currentRSReachabilityStatus] == RSNotReachable) {
        return NO;
    }
    
    model.currentDate = [NSDate date];
    if ([model shouldAskForRate]) {
        [self presentAskForRateController];
        return YES;
	}

    return NO;
}

- (void)debugShowCustomRTAScreen {
    debugMode = YES;
    
    RD2RateThisAppCustomViewController *rtaVC = [[[RD2RateThisAppCustomViewController alloc]
        initWithNibName:@"RD2RateThisAppCustomViewController" bundle:nil] autorelease];

    rtaVC.delegate = self;
    [self presentViewController:rtaVC];
}

- (void)didAnswerWithResult:(RTARequestResult)result {
    [model setAnswer:result];
    
	if (result == RTARequestYes) {
		NSString *appstoreString = [NSString stringWithFormat:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&pageNumber=0&sortOrdering=1&type=Purple+Software&mt=8",
									self.applicationITunesID];
		
		NSURL *appstoreURL = [NSURL URLWithString:appstoreString];
		[[UIApplication sharedApplication] openURL:appstoreURL];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPBUserRatedApp];
        [[NSUserDefaults standardUserDefaults] synchronize];
	}

    NSNumber *resultNumber = [NSNumber numberWithInteger:result];
    [[CBAnalyticsManager sharedManager] rateThisAppAnswer:resultNumber];
}


#pragma mark - ViewController presentation

- (void)presentViewController:(UIViewController *)controller {
    UIViewController *parentController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (nil != parentController.presentedViewController) {
        parentController = parentController.presentedViewController;
    }

    [self presentViewController:controller
               parentController:parentController];
}

- (void)presentViewController:(UIViewController *)controller parentController:(UIViewController *)parentController {
    [parentController addChildViewController:controller];
    
    controller.view.frame = parentController.view.bounds;
    controller.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleHeight);

    controller.view.alpha = 0.0;
    [parentController.view addSubview:controller.view];

    [UIView animateWithDuration:0.3 animations:^{
        controller.view.alpha = 1.0;
    }];
}

- (void)presentAskForRateController {
    if (CUSTOM_MODE) {
        RD2RateThisAppCustomViewController *rtaVC = [[[RD2RateThisAppCustomViewController alloc]
            initWithNibName:@"RD2RateThisAppCustomViewController" bundle:nil] autorelease];

        rtaVC.delegate = self;
        [self presentViewController:rtaVC];
    }
    else {
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Please help us improve %@ by rating it on the App Store",@"alert"),
                         self.appName];

        UIAlertView *alert =
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Like This App?",@"alert view title")
                message:msg
                delegate:self
                cancelButtonTitle:NSLocalizedString(@"No Thanks",@"button title")
                otherButtonTitles:NSLocalizedString(@"Rate It Now",@"button title"),
                NSLocalizedString(@"Remind Me Later",@"button title"), nil]
             autorelease];

        [alert show];
    }

    [[CBAnalyticsManager sharedManager] rateThisAppWasOpened];
}


#pragma mark -
#pragma mark UIAlertViewDelegate
#pragma mark -

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	RTARequestResult askedForRating = RTARequestNo;
    
	if (buttonIndex == [alertView cancelButtonIndex]) {
		askedForRating = RTARequestNo;
	} else if (buttonIndex == 1) {
		askedForRating = RTARequestYes;
	} else if (buttonIndex == 2) {
		askedForRating = RTARequestRemind;
	} else {
        NSAssert(NO, @"WTF!!!");
    }
    
    [self didAnswerWithResult:askedForRating];
}


#pragma mark -
#pragma mark SPCustomRateThisAppViewControllerDelegate
#pragma mark -

- (void)rateThisAppViewController:(RD2RateThisAppCustomViewController *)rtaViewController didFinishedWithResult:(RTARequestResult)result {
    if (!debugMode) {
        [self didAnswerWithResult:result];
    }

    [UIView animateWithDuration:0.3 animations:^{
        rtaViewController.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [rtaViewController.view removeFromSuperview];
        [rtaViewController removeFromParentViewController];
    }];
}

@end
