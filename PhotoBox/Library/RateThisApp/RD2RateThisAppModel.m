//
//  RD2RateThisAppModel.m
//  rScan
//
//  Created by Sergey Ischuk on 13.07.10.
//  Copyright 2010 Readdle. All rights reserved.
//

#import "RD2RateThisAppModel.h"

@interface RD2RateThisAppModel () {
    NSUInteger launchesCount;
    NSUInteger launchesCountSinceUpgrade;
    NSUInteger becomeActives;
    NSDate *lastUpgradeDate;
    NSDate *installDate;
    NSUInteger lastUpgradeVersion;
    NSDate *lastRequestDate;
    RTARequestResult askedForRating;
}

@end

@implementation RD2RateThisAppModel

- (id)init {
	if ((self = [super init])) {
		NSUserDefaults *defaults    = [NSUserDefaults standardUserDefaults];
		askedForRating              = [[defaults objectForKey:@"RTARequestResult"] intValue];
		lastUpgradeDate             = [[defaults objectForKey:@"RTALastUpgradeTime"] retain];
		installDate                 = [[defaults objectForKey:@"RTAInstallTime"] retain];
		launchesCount               = [[defaults objectForKey:@"RTALaunchesCount"] unsignedIntValue];
        launchesCountSinceUpgrade   = [[defaults objectForKey:@"RTALaunchesCountSinceUpgrade"] unsignedIntValue];
		lastRequestDate             = [[defaults objectForKey:@"RTALastRequestTime"] retain];

        // check if it is an update
        if (installDate == nil && lastUpgradeDate != nil) {
            installDate = lastUpgradeDate;
            lastUpgradeDate = nil;
            [defaults setObject:installDate forKey:@"RTAInstallTime"];
            [defaults removeObjectForKey:@"RTALastUpgradeTime"];
        }
    }
	return self;
}

- (void)dealloc {
	[lastRequestDate release];
	[lastUpgradeDate release];
    [installDate release];
	[super dealloc];
}

- (void)checkForNewVersion {
	lastUpgradeVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:@"RTALastVersion"] unsignedIntValue];
        
	UInt32 newVersion = (int)self.currentVersion;

	if (newVersion > lastUpgradeVersion) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        // TODO: enable logging
        //RDLog(@"rate this app update detected");
        
		lastUpgradeVersion = newVersion;
        if (installDate) {
            [lastUpgradeDate release];
            lastUpgradeDate = [self.currentDate retain];
            [defaults setObject:lastUpgradeDate forKey:@"RTALastUpgradeTime"];
        } else {
            installDate = [self.currentDate retain];
            [defaults setObject:installDate forKey:@"RTAInstallTime"];
        }
		askedForRating = RTARequestNotAsked;
		launchesCountSinceUpgrade = 0;
		
		[defaults setObject:@(lastUpgradeVersion) forKey:@"RTALastVersion"];
		[defaults setObject:[NSNumber numberWithUnsignedInteger:launchesCountSinceUpgrade] forKey:@"RTALaunchesCountSinceUpgrade"];
		[defaults setObject:[NSNumber numberWithInt:askedForRating] forKey:@"RTARequestResult"];
		[defaults synchronize];
	}
	
}

- (void)registerLaunch {
    becomeActives = 0;
	[self checkForNewVersion];
	launchesCount++;
	[[NSUserDefaults standardUserDefaults] setObject:@(launchesCount) forKey:@"RTALaunchesCount"];
    launchesCountSinceUpgrade++;
	[[NSUserDefaults standardUserDefaults] setObject:@(launchesCountSinceUpgrade) forKey:@"RTALaunchesCountSinceUpgrade"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)registerBecomeActive {
	becomeActives++;
	if (becomeActives >= RTA_BECOME_ACTIVE_AS_LAUNCH) {
		[self registerLaunch];
	}
}

-(BOOL)shouldAskForRate {
    if (askedForRating == RTARequestNo)
        return NO;
    if (askedForRating == RTARequestYes) 
        return NO;
    
	NSInteger daysSinceInstall = [self.currentDate timeIntervalSinceDate:installDate] / 86400;
	NSInteger daysSinceUpgrade = lastUpgradeDate ? [self.currentDate timeIntervalSinceDate:lastUpgradeDate] / 86400 : NSNotFound;
	NSInteger daysSinceRequest = NSNotFound;
	if (lastRequestDate) 
		daysSinceRequest = [self.currentDate timeIntervalSinceDate:lastRequestDate] / 86400;

    // TODO: Enable logging
	//RDLog(@"launches: %d\ndaysSinceInstall: %d\ndaysSinceUpgrade: %d\ndaysSinceRequest: %d",launchesCount, daysSinceInstall, daysSinceUpgrade, daysSinceRequest);
    
	BOOL show = NO;
    
    
	if (askedForRating == RTARequestRemind && daysSinceRequest >= RTA_LAST_REQUEST_WITHREMIND_DELAY) {
		show = YES;
	}
	else if (askedForRating == RTARequestNotAsked
             && ((daysSinceUpgrade == NSNotFound && daysSinceInstall >= RTA_AFTER_ISNTALL_DELAY && launchesCount >= RTA_INSTALL_MIN_LAUNCHES)
             || (daysSinceUpgrade != NSNotFound && daysSinceUpgrade >= RTA_AFTER_UPGRADE_DELAY && launchesCountSinceUpgrade >= RTA_UPGRADE_MIN_LAUNCHES))) {
		if ((daysSinceRequest == NSNotFound) || (daysSinceRequest >= RTA_LAST_REQUEST_DELAY)) {
			show = YES;
		}
	}
	
    return show;
}

- (void)setAnswer:(RTARequestResult)answer {
    askedForRating = answer;
    
    [lastRequestDate release];
	lastRequestDate = [self.currentDate retain];
	[[NSUserDefaults standardUserDefaults] setObject:lastRequestDate forKey:@"RTALastRequestTime"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:askedForRating] forKey:@"RTARequestResult"];
	[[NSUserDefaults standardUserDefaults] synchronize];

}

@end