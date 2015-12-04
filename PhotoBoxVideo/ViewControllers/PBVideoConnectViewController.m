//
//  PBVideoConnectViewController.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/30/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBVideoConnectViewController.h"

@implementation PBVideoConnectViewController

- (void)viewDidLoadInterfaceUpdate {
    // Do nothing, all interface changes must be done in view or in nib
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.view.superview.layer.masksToBounds = YES;
        self.view.superview.layer.cornerRadius = 8.0;
    }
}

@end
