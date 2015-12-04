//
//  AppDelegate.m
//  WhatsNew
//
//  Created by Artem Meleshko on 4/14/15.
//  Copyright (c) 2015 LeshkoApps. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "LSAppUpdateManager.h"
#import "Appirater.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    ViewController *vc = [[ViewController alloc] init];
    self.window.rootViewController = vc;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //rate the app
    [Appirater setAppId:[[self class] applicationID]];
    [Appirater setDaysUntilPrompt:1];
    [Appirater setUsesUntilPrompt:3];
    [Appirater setSignificantEventsUntilPrompt:3];
    [Appirater setTimeBeforeReminding:1];
    
    LSItunesAppUpdateManager *updateManager = [[LSItunesAppUpdateManager alloc] initWithAppID:[[self class] applicationID]];
    [updateManager checkForUpdateWithCompletion:nil];
    [LSAppUpdateManager setSharedManager:updateManager];
    
    [self showSplash];
    
    [[LSAppUpdateManager sharedManager] saveLastStartedAppVersion];
    
    return YES;
}

+ (NSString *)applicationID{
    NSString *appID = @"588696602"; //@"903653828";
    return appID;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (BOOL)showUpdateAvailableIfNeeded{
    BOOL result = NO;
    id<LSAppUpdateManager> updateManager = [LSAppUpdateManager sharedManager];
    result = [updateManager shouldShowUpdateAvailableUserPromt];
    if(result){
        [updateManager showUpdateAvailableUserPromtWithCompletion:nil];
    }
    return result;
}

- (BOOL)showWhatsNewIfNeeded{
    BOOL result = NO;
    result = [[LSAppUpdateManager sharedManager] shouldShowWhatsNewUserPromt];
    if(result){
        [[LSAppUpdateManager sharedManager] showWhatsNewUserPromtWithCompletion:nil];
    }
    return result;
}

- (void)showSplash{
    BOOL splashDidShow = [self showWhatsNewIfNeeded];
    if(splashDidShow==NO){
        splashDidShow = [self showUpdateAvailableIfNeeded];
    }
    //if splashDidShow==NO: show other splashes...
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    [[LSAppUpdateManager sharedManager] checkForUpdateWithCompletion:nil];
    
    
    [self showSplash];
    
    
    [[LSAppUpdateManager sharedManager] saveLastStartedAppVersion];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
