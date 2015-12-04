//
//  LSWebViewController.m
//  MyApp
//
//  Created by ameleshko on 6/7/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "LSWebViewController.h"
#import "NSObject+LSAdditions.h"



@interface LSWebViewController ()<UIWebViewDelegate>

@property (nonatomic,strong)UIWebView *webView;
@property (nonatomic,strong)NSURLRequest *request;
@property (nonatomic,strong)NSString *htmlString;
@property (nonatomic,strong)NSURL *baseURL;

@end

@implementation LSWebViewController

- (instancetype)initWithRequest:(NSURLRequest *)request{
    self =[super init];
    if(self){
        [self internalInit];
        self.request = request;
    }
    return self;
}

- (instancetype)initWithHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL{
    self =[super init];
    if(self){
        [self internalInit];
        self.htmlString = htmlString;
        self.baseURL = baseURL;
    }
    return self;
}

- (void)internalInit{
    
}

- (void)loadView{
    [super loadView];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.contentView.bounds];
    webView.delegate = self;
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:webView];
    self.webView = webView;
}

- (void)viewDidUnload {
    self.webView = nil;
    [super viewDidUnload];
}

- (void)reloadData:(BOOL)animated{
    if(self.request){
        [self.webView loadRequest:self.request];
    }
    else if(self.htmlString){
        [self.webView loadHTMLString:self.htmlString baseURL:self.baseURL];
    }
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    if(self.webViewShouldStartLoadBlock){
        return self.webViewShouldStartLoadBlock(webView,request,navigationType);
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [self performBlockOnMainThreadSync:^{
        if(self.webViewDidFinishLoadBlock){
            self.webViewDidFinishLoadBlock(webView);
        }
    }];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
}

@end
