 //
//  PBNavigationController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 09/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBNavigationController.h"
#import "PBPhotoBar.h"
#import "PBToolbar.h"
#import "PBAssetsGroupListViewController.h"
#import "PBAssetListViewController.h"
#import "PBReceiveViewController.h"
#import "PBRootViewController.h"

#import "PBAssetManager.h"


@interface PBNavigationController () <UINavigationControllerDelegate>


@end

@implementation PBNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

   // self.navigationBar.layer.masksToBounds = YES;

   // self.view.backgroundColor = [UIColor defaultBackgroundColor];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(photobarDidSelectAssetUrl:)
        name:PBPhotoBarDidSelectAssetUrlNotification
        object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    PBViewController *vc = self.childViewControllers.lastObject;
    
    self.topToolBarIsHidden = !vc.showTopToolbar;
    
    UIView *view = vc.view;
    
    CGRect childViewFrame = view.frame;
    CGSize childSize = childViewFrame.size;
    CGFloat childWidth = childSize.width;
    
    CGRect nbFrame = self.navigationBarHidden ? CGRectZero : self.navigationBar.frame;
    
    if (_topToolBar && !_topToolBarIsHidden) {
        CGFloat topToolbarHeight = _topToolBar.bounds.size.height;
        CGFloat topToolBarY = nbFrame.origin.y + nbFrame.size.height;
        _topToolBar.frame = CGRectMake(0, topToolBarY, childWidth, topToolbarHeight);
        
        PBPhotoBar *photoBar = (PBPhotoBar *)_topToolBar;
        [photoBar setShadowStrength:vc.topBarShadowType animated:YES];
        
        photoBar.showFreeToSendPhotosOnly = vc.topToolbarShowFreeToSendPhotosOnly;
        photoBar.backgroundColor = [UIColor redColor];
    }

}

#pragma mark - PhotoBar

- (void)photobarDidSelectAssetUrl:(NSNotification *)notification {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return;
    }

    
    NSURL *url = notification.object;
    ALAssetsGroup *group = [[PBAssetManager sharedManager] getGroupForAssetUrl:url];
    if (group == nil) {
        return;
    }

    NSString *targetGroupName = [group valueForProperty:ALAssetsGroupPropertyName];
    
    PBAssetListViewController *targetAssetListViewController = nil;
    UIViewController *topViewController = self.topViewController;

    //pop to album list viewController
    if ([topViewController isKindOfClass:[PBAssetListViewController class]]) {

        // TODO: Fix it !!!
        PBAssetListViewController *alvc = (PBAssetListViewController *)self.topViewController;
        
        if ([[alvc.assetsGroup valueForProperty:ALAssetsGroupPropertyName] isEqual:targetGroupName]) {
            targetAssetListViewController = alvc;
        } else {
            [self popViewControllerAnimated:NO];
        }
    } else if ([topViewController isKindOfClass:[PBAssetsGroupListViewController class]] == NO) {
        //we're not in album list nor in asset list. there's nothing to do here
        return;
    }
    
    if (targetAssetListViewController == nil) {
        Class targetClass = (nil == _assetsListViewControllerClass)
            ? [PBAssetListViewController class]
            : _assetsListViewControllerClass;

        targetAssetListViewController = [[[targetClass alloc] initWithAssetsGroup:group] autorelease];
        [self pushViewController:targetAssetListViewController animated:NO];
    }

    [[[PBAssetManager sharedManager] assetsLibrary]
        assetForURL:url
        resultBlock:^(ALAsset *asset) {
            [targetAssetListViewController scrollToAsset:asset];
        }
        failureBlock:^(NSError *error) {

        }];
}



#pragma mark - Properties

- (void)setTopToolBar:(UIView *)topToolBar {
    [_topToolBar autorelease];
    [_topToolBar removeFromSuperview];
    
    _topToolBar = [topToolBar retain];
    [self.view addSubview:_topToolBar];
}

- (void)setTopToolBarIsHidden:(BOOL)topToolBarIsHidden {
    _topToolBarIsHidden = topToolBarIsHidden;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         _topToolBar.alpha = _topToolBarIsHidden ? 0 : 1;
                     }];
}


@end
