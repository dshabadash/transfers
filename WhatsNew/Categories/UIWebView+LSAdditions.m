//
//  UIWebView+LSAdditions.m
//  MyApp
//
//  Created by Artem Meleshko on 12/29/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "UIWebView+LSAdditions.h"

@implementation UIWebView (LSAdditions)

- (void)clearBackground{
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    [UIWebView removeShadowFromWebView:self];
}

+ (void)removeShadowFromWebView:(UIWebView *)webView{
    for( UIView *view in [webView subviews] ) {
        if( [view isKindOfClass:[UIScrollView class]] ) {
            for( UIView *innerView in [view subviews] ) {
                if( [innerView isKindOfClass:[UIImageView class]] ) {
                    innerView.hidden = YES;
                }
            }
        }
    }
}

@end
