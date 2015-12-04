//
//  PBPermissionsRequestViewController.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 7/15/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBPermissionsRequestViewController.h"

@implementation PBPermissionsRequestViewController


#pragma mark - View

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - Events handling

- (IBAction)didTapAllowButton:(id)sender {
    [_delegate permissonsGrantedFromViewController:self];
    [_delegate dismissPermissionsRequestViewController:self];
}

- (IBAction)didTapMaybeLaterButton:(id)sender {
    [_delegate dismissPermissionsRequestViewController:self];
}

@end
