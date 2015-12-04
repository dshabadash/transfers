//
//  PBFlickrAuthentificationViewController.m
//  PhotoBox
//
//  Created by Dara on 09.04.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import "PBFlickrAuthentificationViewController.h"

@interface PBFlickrAuthentificationViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *authWebView;
@property (nonatomic, strong) NSURL *authURL;
@property (nonatomic, strong) UIActivityIndicatorView *loadingAV;

@end

@implementation PBFlickrAuthentificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem =
    [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
                                      style:UIBarButtonItemStylePlain
                                     target:self
                                     action:@selector(closeButtonTapped:)]
     autorelease];
    
    //add WebView
    
    self.loadingAV = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];

    
    
    self.authWebView = [[[UIWebView alloc] initWithFrame:self.view.bounds] autorelease];
    self.authWebView.delegate = self;
    self.authWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
 
    self.authWebView.scalesPageToFit = YES;
    self.authWebView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.authWebView];
    [self.view addSubview:self.loadingAV];
    
    if (self.authURL) {
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [storage cookies]) {
            [storage deleteCookie:cookie];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.authWebView loadRequest:[NSURLRequest requestWithURL:self.authURL
                                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                   timeoutInterval:60.0]];
    }
}


-(void)loadAuthURL:(NSURL *)authURL {
    self.authURL = authURL;   
}

- (void)closeButtonTapped:(id)sender {
    //user cancelled authorization
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FlickrUserCancelledAuthentification" object:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark UIWebView Delegate
#pragma mark -

-(void)webViewDidStartLoad:(UIWebView *)webView {
    self.loadingAV.center = CGPointMake(self.view.bounds.size.width/2.0, self.view.bounds.size.height/2.0);

    [self.loadingAV startAnimating];
    [self.loadingAV setHidden:NO];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.loadingAV stopAnimating];
    [self.loadingAV setHidden:YES];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    NSLog(@"Did start loading: %@ ", [[request URL] absoluteString]);
    
    if (([[[request URL] absoluteString] containsString:@"iosauthlogout"]) || ([[[request URL] absoluteString] containsString:@"https://m.flickr.com/#/home"])) {
        //post notification about logout;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UserWasSignenOut" object:nil];
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
    }

    return YES;
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection;
{
    return NO;
}


@end
