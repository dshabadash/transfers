//
//  PBVideoHomeScreenBottomView.h
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/10/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBHomeScreenBottomView.h"

@interface PBVideoHomeScreenBottomView : PBHomeScreenBottomView

+ (id<PSTCollectionViewDataSource>)collectionViewDataSource;
+ (PSTCollectionViewFlowLayout *)collectionViewLayout;
- (IBAction)helpButtonTapped:(id)sender;

@end
