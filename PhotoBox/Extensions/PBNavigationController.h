//
//  PBNavigationController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 09/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBNavigationController : UINavigationController

@property (retain, nonatomic) UIView *topToolBar;
@property (assign, nonatomic) BOOL topToolBarIsHidden;
@property (assign, nonatomic) Class assetsListViewControllerClass;

@end
