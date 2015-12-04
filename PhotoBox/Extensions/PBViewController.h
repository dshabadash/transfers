//
//  PBViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 09/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    PBViewControllerTopBarShadowTypeNone = 0,
    PBViewControllerTopBarShadowTypeNormal,
    PBViewControllerTopBarShadowTypeBold
} PBViewControllerTopBarShadowType;

@interface PBViewController : UIViewController

+ (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

@property (assign, nonatomic) BOOL showTopToolbar;
@property (assign, nonatomic) BOOL topToolbarShowFreeToSendPhotosOnly;
@property (assign, nonatomic) PBViewControllerTopBarShadowType topBarShadowType;


@end
