//
//  PBVideoAssetListViewController.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/24/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBVideoAssetListViewController.h"

@interface PBVideoAssetListViewController ()

@end

@implementation PBVideoAssetListViewController


#pragma mark - Appearence

+ (UIColor *)collectionViewBackgroundColor {
    return [UIColor whiteColor];
}

+ (UIView *)noAssetsViewWithRect:(CGRect)rect {
    UINib *nib = [UINib nibWithNibName:@"PBVideoNoAssetsView" bundle:nil];
    UIView *view = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
    [view setFrame:rect];

    return view;
}

@end
