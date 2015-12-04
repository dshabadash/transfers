//
//  LSWebViewController.h
//  MyApp
//
//  Created by ameleshko on 6/7/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "LSViewController.h"

typedef void (^LSWebViewControllerDidFinishLoadBlock)(UIWebView *webView);
typedef BOOL (^LSWebViewControllerShouldStartLoadWithRequest)(UIWebView *webView,NSURLRequest *request,UIWebViewNavigationType navigationType);


@interface LSWebViewController : LSViewController

@property (nonatomic,copy)LSWebViewControllerDidFinishLoadBlock webViewDidFinishLoadBlock;
@property (nonatomic,copy)LSWebViewControllerShouldStartLoadWithRequest webViewShouldStartLoadBlock;
@property (nonatomic,readonly,strong)UIWebView *webView;
@property (nonatomic,readonly,strong)NSURLRequest *request;

@property (nonatomic,readonly,strong)NSString *htmlString;
@property (nonatomic,readonly,strong)NSURL *baseURL;

- (instancetype)initWithRequest:(NSURLRequest *)request;

- (instancetype)initWithHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL;

@end
