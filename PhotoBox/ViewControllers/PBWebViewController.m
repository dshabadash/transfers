//
//  PBWebViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 28/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBWebViewController.h"

@interface PBWebViewController () <UIWebViewDelegate> {
    UIWebView *_webView;
}

@property (retain, nonatomic) NSURL *documentUrl;

@end

@implementation PBWebViewController

- (id)initWithTitle:(NSString *)title htmlName:(NSString *)htmlName
{
    NSURL *resourceUrl = nil;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        resourceUrl = [[NSBundle mainBundle] URLForResource:[htmlName stringByAppendingString:@"-ipad"]
                                              withExtension:@"html"];
    }
    
    if (resourceUrl == nil) {
        resourceUrl = [[NSBundle mainBundle] URLForResource:htmlName withExtension:@"html"];
    }
    
    self = [self initWithTitle:title documentUrl:resourceUrl];
    return self;
}

- (id)initWithTitle:(NSString *)title documentUrl:(NSURL *)url
{
    self = [super init];
    if (self) {
        if (title == nil) {
            title = NSLocalizedString(@"Help", @"");
        }
        self.title = title;

        self.documentUrl = url;
    }
    return self;
}

- (void)dealloc
{
    _webView.delegate = nil;
    self.documentUrl = nil;

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] autorelease];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.dataDetectorTypes = UIDataDetectorTypeNone;
    _webView.delegate = self;
    [self.view addSubview:_webView];

    if (_documentUrl) {
        [_webView loadRequest:[NSURLRequest requestWithURL:_documentUrl]];
    } else {
        [_webView loadHTMLString:@"Resource not found" baseURL:nil];
    }

    if (_showCloseButton) {
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(dismiss)];
        self.navigationItem.rightBarButtonItem = [closeButtonItem autorelease];
        
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    _webView.delegate = nil;
    _webView = nil;
}

- (void)dismiss
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if ([url.scheme isEqualToString:@"mailto"]) {
        [[PBAppDelegate sharedDelegate] presentContactSupportEmailComposeViewControllerFromViewController:self];
        return NO;
    }
    return YES;
}

@end
