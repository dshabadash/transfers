//
//  PBGoogleAuthViewController.m
//  PhotoBox
//
//  Created by Dara on 21.04.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import "PBGoogleAuthViewController.h"

@interface PBGoogleAuthViewController ()

@end

@implementation PBGoogleAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setUpNavigation {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(googleAuthCloseButtonTapped:)];
}

-(void)googleAuthCloseButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}


@end
