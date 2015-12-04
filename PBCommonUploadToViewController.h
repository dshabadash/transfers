//
//  PBUploadToDropboxViewController.h
//  PhotoBox
//
//  Created by Dara on 25.03.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBViewController.h"
#import "PBCommonUploadingEngine.h"

@interface PBCommonUploadToViewController : PBViewController


-(void)sendNextAsset;


@property (retain, nonatomic) PBCommonUploadingEngine *uploadingEngine;

@end
