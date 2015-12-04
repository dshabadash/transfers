//
//  PBImportDidFailedViewController.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 9/12/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBImportDidFailedViewController.h"

@interface PBImportDidFailedViewController ()
@property (nonatomic, unsafe_unretained) IBOutlet UIButton *cancelButton;

@end

@implementation PBImportDidFailedViewController

- (void)addTarget:(id)target cancelAction:(SEL)cancelAction {
    [self view];
    
    [self.cancelButton addTarget:target
        action:cancelAction
        forControlEvents:UIControlEventTouchUpInside];
}

@end
