//
//  PBHelpViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 20/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#if PB_LITE
#import "PBPurchaseManager.h"
#endif

@interface PBHelpViewController : PBViewController<UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

+ (NSString *)shareThisAppText;
+ (UITableView *)tableViewWithFrame:(CGRect)frame;
+ (NSArray *)tableViewCells;
+ (NSDictionary *)cellDictionaryWithTitle:(NSString *)title
                                    image:(UIImage *)image
                                   action:(SEL)action;

+ (UINib *)tableViewCellNib;
- (void)presentChildViewController:(UIViewController *)controller;
- (void)presentChildViewController:(UIViewController *)controller hideNavigationBar:(BOOL)hideNavigationBar;
- (IBAction)closeButtonTapped:(id)sender;

@end
