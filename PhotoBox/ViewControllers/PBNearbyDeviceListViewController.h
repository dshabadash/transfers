//
//  PBNearbyDeviceListViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 08/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBViewController.h"

@interface PBNearbyDeviceListViewController : PBViewController
@property (nonatomic, retain) UINib *tableViewCellNib;
- (IBAction)cancelButtonTapped:(id)sender;
@end
