//
//  PBConnectViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 21/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBConnectViewController : PBViewController
@property (assign, nonatomic) BOOL sendAssetsUI;
- (IBAction)cancelButtonTapped:(id)sender;
- (void)initialize;
- (void)viewDidLoadInterfaceUpdate;
- (void)updatePreparingView;
- (void)registerOnNotifications;
@end
