//
//  PBWebViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 28/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBWebViewController : PBViewController

- (id)initWithTitle:(NSString *)title htmlName:(NSString *)htmlName;
- (id)initWithTitle:(NSString *)title documentUrl:(NSURL *)url;

@property (assign, nonatomic) BOOL showCloseButton;

@end
