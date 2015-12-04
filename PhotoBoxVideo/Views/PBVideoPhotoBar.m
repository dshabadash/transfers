//
//  PBVideoPhotoBar.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/17/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBVideoPhotoBar.h"

@implementation PBVideoPhotoBar

+ (PSTCollectionView *)collectionViewWithFrame:(CGRect)frame {
    PSTCollectionView *collectionView = [[self superclass] collectionViewWithFrame:frame];
    collectionView.backgroundColor = [self collectionViewBackgroundColor];

    PSTCollectionViewFlowLayout *collectionViewLayout = [[[PSTCollectionViewFlowLayout alloc] init] autorelease];
    collectionViewLayout.scrollDirection = PSTCollectionViewScrollDirectionHorizontal;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        //ipad
        collectionViewLayout.itemSize = CGSizeMake(75, 75);
        collectionViewLayout.minimumLineSpacing = 23;
        collectionViewLayout.minimumInteritemSpacing = 23;
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(14, 14, 14, 14);
    } else {
        //iphone
        collectionViewLayout.itemSize = CGSizeMake(43, 43);
        collectionViewLayout.minimumLineSpacing = 5;
        collectionViewLayout.minimumInteritemSpacing = 5;

        CGFloat topInset = (frame.size.height - collectionViewLayout.itemSize.height) / 2.0;
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(topInset, 5, 0, 5);
    }

    [collectionView setCollectionViewLayout:collectionViewLayout];

    return collectionView;
}

+ (UILabel *)noAssetsLabelWithFrame:(CGRect)frame {
    UILabel *noAssetsLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    noAssetsLabel.textAlignment = NSTextAlignmentCenter;
    noAssetsLabel.adjustsFontSizeToFitWidth = NO;
    noAssetsLabel.text = NSLocalizedString(@"Choose files to send", @"");

    noAssetsLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight);

    CGFloat fontSize = 20.0;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        fontSize = 30.0;
    }

    noAssetsLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:fontSize];
    noAssetsLabel.textColor = [UIColor colorWithRGB:0x969696];
    noAssetsLabel.shadowColor = [UIColor colorWithRGB:0xfbfbfb];
    noAssetsLabel.shadowOffset = CGSizeMake(0, 1.0);
    noAssetsLabel.backgroundColor = [self collectionViewBackgroundColor];

    return noAssetsLabel;
}

+ (UIView *)backgroundViewWithFrame:(CGRect)frame {
    PBStretchableImageView *backgroundImage = [[[PBStretchableImageView alloc] initWithFrame:frame] autorelease];
    UIImage *image = [UIImage imageNamed:@"picked_assets_bg"];
    [backgroundImage setImage:image];

    return backgroundImage;
}

+ (UIColor *)collectionViewBackgroundColor {
    UIImage *image = [UIImage imageNamed:@"picked_assets_bg"];
    return [UIColor colorWithPatternImage:image];
}


#pragma mark - CollectionView

- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PSTCollectionViewCell *cell = [super collectionView:collectionView
        cellForItemAtIndexPath:indexPath];

    cell.layer.cornerRadius = 4.0;
    cell.layer.masksToBounds = YES;

    return cell;
}

@end
