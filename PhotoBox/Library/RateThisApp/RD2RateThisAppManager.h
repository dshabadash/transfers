//
//  RD2RateThisAppManager.h
//  rgCalendar
//
//  Created by Viktor Gedzenko on 2/14/13.
//
//

#import <Foundation/Foundation.h>
#import "RD2RateThisAppCustomViewController.h"

@interface RD2RateThisAppManager : NSObject <UIAlertViewDelegate,
RD2RateThisAppCustomViewControllerDelegate>

+ (RD2RateThisAppManager *)sharedManager;

@property (retain) NSString *applicationITunesID;
@property (retain) NSString *appName;

- (void)presentAskForRateController;
- (void)registerLaunch;
- (void)registerBecomeActive;
- (BOOL)askForRate;

- (void)debugShowCustomRTAScreen;

@end
