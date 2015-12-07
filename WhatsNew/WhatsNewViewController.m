//
//  WhatsNewViewController.m
//  MyApp
//
//  Created by Artem Meleshko on 12/29/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "WhatsNewViewController.h"
#import "UIColor+LSAdditions.h"
#import "UIImage+LSAdditions.h"
#import "LSWebViewController.h"
#import "Appirater.h"
#import "UIWebView+LSAdditions.h"
#import "UIViewController+ModalPresenting.h"
#import "LSConstants.h"



NSString * const kRateTitle = @"kRateTitle";
NSString * const kRateButtonTitle = @"kRateButtonTitle";
NSString * const kRateButtonURL = @"lsapp://action.rate";


@interface WhatsNewViewController ()

@property (nonatomic,copy)NSString *titleText;
@property (nonatomic,copy)NSString *detailText;
@property (nonatomic,strong)NSDictionary *rateInfo;
@property (nonatomic,copy)WhatsNewViewControllerCompletionBlock completion;

@end

@implementation WhatsNewViewController


- (instancetype)initWithTitle:(NSString *)titleText
                       detail:(NSString *)detailText
                     rateInfo:(NSDictionary *)rateInfo
                   completion:(WhatsNewViewControllerCompletionBlock)completion{
    self = [super initWithNavigationBarClass:nil toolbarClass:nil];
    if(self){
        
        detailText = [detailText stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
        
        self.titleText = titleText;
        self.detailText = detailText;
        self.rateInfo = rateInfo;
        self.completion = completion;
        
        NSString *htmlString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"whats_new" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];

        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"BODY_TITLE_TEXT" withString:self.titleText?:@""];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"BODY_DETAIL_TEXT" withString:self.detailText?:@""];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"RATE_TITLE_TEXT" withString:[self.rateInfo objectForKey:kRateTitle]?:@""];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"RATE_URL" withString:kRateButtonURL];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"RATE_BUTTON_TITLE" withString:[self.rateInfo objectForKey:kRateButtonTitle]?:@""];
        
        NSURL *baseURL = [[NSBundle mainBundle] resourceURL];
        LSWebViewController *vc = [[LSWebViewController alloc] initWithHTMLString:htmlString baseURL:baseURL];

        __weak typeof (vc) weakVC = vc;
        [vc setViewDidLoadBlock:^(LSViewController *controller){
            weakVC.contentView.backgroundColor = [UIColor colorWithRGB:0xf1f9ff];
            [weakVC.webView clearBackground];
            weakVC.view.tintColor = [UIColor ios7DarkBlueColor];
        }];
        
        __weak typeof (self) weakSelf = self;
        vc.webViewShouldStartLoadBlock = ^(UIWebView *webView,NSURLRequest *request,UIWebViewNavigationType navigationType){
            if([request.URL.absoluteString isEqualToString:kRateButtonURL]){
                [Appirater rateApp]; //Rate this app
                [weakSelf hide:NO];
                return NO;
            }
            return YES;
        };
        
        vc.title = NSLocalizedString(@"What's New", @"");
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(actionClose:)];
        vc.navigationItem.leftBarButtonItem = item;
        [vc reloadData];
        
        [self setViewControllers:@[vc]];
    }
    return self;
}

- (CGSize)preferredContentSize{
    return CGSizeMake(450.0, 470.0);
}

+ (NSDictionary *)rateInfoWithMessage:(NSString *)titleText
                    title:(NSString *)rateTitle{
    
    return @{kRateTitle:titleText,
             kRateButtonTitle:rateTitle};
}

- (UIViewController *)rootPresentingController{
    UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    if(vc.presentedViewController){
        vc = vc.presentedViewController;
    }
    return vc;
}

- (void)show:(BOOL)animated{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self rootPresentingController] presentModalViewController:self animated:animated completion:nil];
    });
}

- (void)hide:(BOOL)animated{
    [[self rootPresentingController] dismissViewControllerAnimated:animated completion:^{
        if(self.completion){
            self.completion();
        }
    }];
}

- (void)actionClose:(id)sender{
    [self hide:YES];
}

- (void)loadView{
    [super loadView];
    self.view.tintColor = [UIColor ios7DarkBlueColor];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

#pragma mark - Autorotate

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if(DEVICE_IS_IPAD()){
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return (NSUInteger)UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
}

@end
