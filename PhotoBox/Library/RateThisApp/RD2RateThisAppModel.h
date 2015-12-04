//
//  RD2RateThisAppModel.h
//  rScan
//
//  Created by Sergey Ischuk on 13.07.10.
//  Copyright 2010 Readdle. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RTA_AFTER_ISNTALL_DELAY 10
#define RTA_INSTALL_MIN_LAUNCHES 10
#define RTA_AFTER_UPGRADE_DELAY 0
#define RTA_UPGRADE_MIN_LAUNCHES 3
#define RTA_LAST_REQUEST_DELAY 30
#define RTA_LAST_REQUEST_WITHREMIND_DELAY 7

#define RTA_BECOME_ACTIVE_AS_LAUNCH 3

enum RTARequestResult {
	RTARequestNotAsked,
	RTARequestYes,
	RTARequestNo,
	RTARequestRemind
};
typedef enum RTARequestResult RTARequestResult;

@interface RD2RateThisAppModel : NSObject

@property (retain) NSDate *currentDate;
@property (assign) NSInteger currentVersion;

- (void)registerLaunch;
- (void)registerBecomeActive;
- (BOOL)shouldAskForRate;
- (void)setAnswer:(RTARequestResult)answer;

@end
