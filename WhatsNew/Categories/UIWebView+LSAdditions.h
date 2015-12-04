//
//  UIWebView+LSAdditions.h
//  MyApp
//
//  Created by Artem Meleshko on 12/29/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWebView (LSAdditions)

- (void)clearBackground;

+ (void)removeShadowFromWebView:(UIWebView *)webView;

@end
