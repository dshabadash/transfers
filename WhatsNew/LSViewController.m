//
//  LSViewController.m
//  MyApp
//
//  Created by Artem Meleshko on 10/16/13.
//  Copyright (c) 2013 My Company. All rights reserved.
//

#import "LSViewController.h"
#import "UIView+LSAdditions.h"
#import "UIColor+LSAdditions.h"
#import "NSObject+LSAdditions.h"
#import "LSViewController+Private.h"
#import "LSConstants.h"

@interface LSViewController ()

@property (nonatomic, assign) BOOL needsDataReload;
@property (nonatomic, assign) BOOL needsViewUpdate;

@property (nonatomic, strong) UIView *contentView;

@end






@implementation LSViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self customInit];
    }
    return self;
}

- (id)init{
    self = [super init];
    if(self){
        [self customInit];
    }
    return self;
}

- (void)customInit{

}

- (void)dealloc{

}

- (UIRectEdge)edgesForExtendedLayout{
    return UIRectEdgeNone;
}

- (UIView *)createContentView{
    return [UIView new];
}

- (void)loadView{
    [super loadView];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIView *v = [self createContentView];
    [v setFrame:self.view.bounds];
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:v];
    self.contentView = v;

}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self setNeedsDataReload];
    if(self.viewDidLoadBlock){
        self.viewDidLoadBlock(self);
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(self.needsDataReload){
        self.needsDataReload = NO;
        self.needsViewUpdate = NO;
        [self reloadData];
    }
    if(self.needsViewUpdate){
        self.needsViewUpdate = NO;
        [self updateView:NO];
    }
    
    if(self.viewWillAppearBlock){
        self.viewWillAppearBlock(self);
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(self.viewDidAppearBlock){
        self.viewDidAppearBlock(self);
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if(self.viewWillDisappearBlock){
        self.viewWillDisappearBlock(self);
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if(self.viewDidDisappearBlock){
        self.viewDidDisappearBlock(self);
    }
}

- (void)viewDidUnload{
    [super viewDidUnload];
}

- (BOOL)isViewVisible{
    return ([self isViewLoaded] && self.view.window);
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
}

#pragma mark - Autorotate

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
	return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if(DEVICE_IS_IPAD()){
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
}

#pragma mark - Data Update


- (void)reloadDataIfViewIsVisible{
    if(self.isViewVisible){
        
        if([NSThread isMainThread]){
            [self reloadData];
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                if(self.isViewVisible){
                    [self reloadData];
                }
                else{
                    self.needsDataReload = YES;
                }
            });
        }
    }
    else{
        self.needsDataReload = YES;
    }
}

- (void)updateViewIfVisible{
    if(self.isViewVisible){
        if([NSThread isMainThread]){
            [self updateView:NO];
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                if(self.isViewVisible){
                    [self updateView:NO];
                }
                else{
                    self.needsViewUpdate = YES;
                }
            });
        }
    }
    else{
        self.needsViewUpdate = YES;
    }
}

- (void)setNeedsDataReload{
    self.needsDataReload = YES;
}

- (void)setNeedsViewUpdate{
    self.needsViewUpdate = YES;
}

- (void)loadData{
}

- (void)updateView:(BOOL)animated{
}

- (void)reloadData:(BOOL)animated{
    [self loadData];
    [self updateView:animated];
}

- (void)reloadData{
    [self reloadData:NO];
}

@end
