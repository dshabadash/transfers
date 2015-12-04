//
//  PBPermissionsRequestViewController.h
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 7/15/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PBPermissionsRequestViewControllerDelegate;

@interface PBPermissionsRequestViewController : UIViewController
@property (assign, nonatomic) id<PBPermissionsRequestViewControllerDelegate> delegate;
- (IBAction)didTapAllowButton:(id)sender;
- (IBAction)didTapMaybeLaterButton:(id)sender;
@end

@protocol PBPermissionsRequestViewControllerDelegate<NSObject>
- (void)permissonsGrantedFromViewController:(UIViewController *)controller;
- (void)dismissPermissionsRequestViewController:(UIViewController *)controller;
@end
