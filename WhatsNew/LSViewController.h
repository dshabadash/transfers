//
//  LSViewController.h
//  MyApp
//
//  Created by Artem Meleshko on 10/16/13.
//  Copyright (c) 2013 My Company. All rights reserved.
//

#import <UIKit/UIKit.h>


@class LSViewController;

typedef void (^LSViewControllerBlock)(LSViewController *controller);

@interface LSViewController : UIViewController

@property (nonatomic,copy)LSViewControllerBlock viewDidLoadBlock;
@property (nonatomic,copy)LSViewControllerBlock viewWillAppearBlock;
@property (nonatomic,copy)LSViewControllerBlock viewDidAppearBlock;
@property (nonatomic,copy)LSViewControllerBlock viewWillDisappearBlock;
@property (nonatomic,copy)LSViewControllerBlock viewDidDisappearBlock;
@property (nonatomic, readonly) BOOL isViewVisible;
@property (nonatomic, readonly, strong) UIView *contentView;

//data update
- (void)loadData;
- (void)updateView:(BOOL)animated;
- (void)reloadData:(BOOL)animated;
- (void)reloadData;
- (void)reloadDataIfViewIsVisible;
- (void)updateViewIfVisible;
- (void)setNeedsDataReload;
- (void)setNeedsViewUpdate;

@end

