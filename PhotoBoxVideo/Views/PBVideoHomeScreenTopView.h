//
//  PBVideoHomeScreenTopView.h
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/8/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBHomeScreenCoverView.h"

@interface PBVideoHomeScreenTopView : PBHomeScreenCoverView

+ (id<PSTCollectionViewDataSource>)collectionViewDataSource;
+ (PSTCollectionViewFlowLayout *)collectionViewLayout;

@end
