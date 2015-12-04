//
//  PBSendToInterfaceController.m
//  PhotoBox
//
//  Created by Dara on 03.06.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import "PBSendToInterfaceController.h"

typedef enum {
    sendToNowhere = 0,
    sendToDropbox = 1,
    sendToFlickr = 2,
    sendToGoogleDrive = 3
} SendToDestination;

@interface PBSendToInterfaceController () {
    SendToDestination destToSend;
}

@end

@implementation PBSendToInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}
- (IBAction)sendToDropbox {
}
- (IBAction)sendToFlickr {
}
- (IBAction)sendToGoogleDrive {
}

- (IBAction)cancelSend {
}

-(void)sendTo {
    
}

@end



