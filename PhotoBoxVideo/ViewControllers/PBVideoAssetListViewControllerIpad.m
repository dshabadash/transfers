//
//  PBVideoAssetListViewControllerIpad.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 6/3/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBVideoAssetListViewControllerIpad.h"
#import "PBVideoAssetsGroupListViewController.h"
#import "PBAssetManager.h"

@interface PBVideoAssetListViewControllerIpad ()

@end

@implementation PBVideoAssetListViewControllerIpad

+ (PBAssetsGroupListViewController *)groupsListViewController {
    return [[PBVideoAssetsGroupListViewController new] autorelease];
}

+ (UIColor *)collectionViewBackgroundColor {
    return [UIColor whiteColor];
}

+ (UIView *)noAssetsViewWithRect:(CGRect)rect {
    UINib *nib = [UINib nibWithNibName:@"PBVideoNoAssetsView" bundle:nil];
    UIView *view = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
    [view setFrame:rect];

    return view;
}

- (PSTCollectionViewFlowLayout *)collectionViewLayout {
    PSTCollectionViewFlowLayout *collectionViewLayout = [[[PSTCollectionViewFlowLayout alloc] init] autorelease];
    collectionViewLayout.itemSize = CGSizeMake(122, 122);
    collectionViewLayout.minimumLineSpacing = 7;
    collectionViewLayout.minimumInteritemSpacing = 5;
    collectionViewLayout.sectionInset = UIEdgeInsetsMake(5, 10, 5, 10);


    return collectionViewLayout;
}

- (UINib *)collectionViewCellNib {
    UINib *nib = [UINib nibWithNibName:@"PBVideoAssetPreviewCollectionCell-ipad" bundle:[NSBundle mainBundle]];

    return nib;
}

+ (UIBarButtonItem *)cancelBarButtonItemTarget:(id)target action:(SEL)action {
    UIImage *image = [UIImage imageNamed:@"navbar_cancel_icon"];
    UIBarButtonItem *cancelButton =
        [[[UIBarButtonItem alloc] initWithImage:image
            style:UIBarButtonItemStyleBordered
            target:target
            action:action]
        autorelease];
    
    return cancelButton;
}

- (UILabel *)navigationBarTitleLabel {
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 44.0)] autorelease];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:21];
    titleLabel.shadowOffset = CGSizeMake(0, -1);
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.shadowColor = [UIColor darkGrayColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;

    return titleLabel;
}

- (void)albumSelected:(NSNotification *)notification {
    NSString *groupName = [[notification userInfo] objectForKey:@"groupName"];
    
    if ([groupName isEqualToString:[PBAssetManager allVideosGroupLocalizedName]]) {
        [_assetsGroup autorelease];
        _assetsGroup = nil;
        _assetsGroup = [[[notification userInfo] objectForKey:@"group"] retain];
        
        self.title = groupName;
        [_collectionView reloadData];
    }
    else {
        NSURL *albumUrl = notification.userInfo[kPBAssetsGroupUrl];
        [self setAssetsGroupUrl:albumUrl];
        [_collectionView reloadData];
        self.title = groupName;
    }
    
    if (self.currentPopoverController) {
        [self.currentPopoverController dismissPopoverAnimated:YES];
        self.currentPopoverController = nil;
    }
}


@end
