//
//  PBTransferProgressViewController.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    PBTransferDirectionSend = 0,
    PBTransferDirectionReceive
} PBTransferDirection;

@interface PBTransferProgressViewController : PBViewController

@property (assign, nonatomic) CGFloat initialProgress;
@property (assign, nonatomic) PBTransferDirection transferDirection;

@property (copy, nonatomic) NSString *deviceName;
@property (copy, nonatomic) NSString *deviceType;

-(void)checkIfFinishedNotificationReceived;

@end
