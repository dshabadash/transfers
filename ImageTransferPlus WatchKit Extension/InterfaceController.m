










































































//
//  InterfaceController.m
//  ImageTransferPlus WatchKit Extension
//
//  Created by Dara on 28.05.15.
//  Copyright (c) 2015 CapableBits. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *infoLabel;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    [self.infoLabel setText:@"Send your media files to cloud."];
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

#pragma mark -
#pragma mark Actions
#pragma mark -

-(void)parsingResultString:(NSString *)resString {
    
}

- (IBAction)sendButtonTapped {
    NSArray *startPhrases = @[@"Send please last one hundred twenty-four media file", @"Send last 5 media files", @"Send last 10 media files", @"Send today media files"];
    
    [self presentTextInputControllerWithSuggestions:startPhrases
                                   allowedInputMode:WKTextInputModePlain
                                         completion:^(NSArray *results) {\
                                             if (results && results.count > 0) {
                                                 NSString *result = [results objectAtIndex:0];
                                                 NSLog(@"%@", result);
                                                 
                                                 [self presentControllerWithName:@"CloudMenuInterfaceController"
                                                                         context:nil];
                                             }
                                             else {
                                                 //nothing
                                             }
                                             
                                         }];
    
}

@end



