//
//  RDUsageTracker.h
//  ReaddleDocs2
//
//  Created by Andrian Budantsov on 04.05.12.
//  Copyright (c) 2012 Readdle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RDUShouldAskBlock)(BOOL shouldAsk);

@interface RDUsageTracker : NSObject

+ (RDUsageTracker *)sharedTracker;

+ (NSString *)RDUUserStoreIDHash;
+ (NSString *)RDUUserStoreID;
+ (NSString *)RDUMacIdentifier;


- (void)addTarget:(id)target action:(SEL)action;
- (void)removeTarget:(id)target action:(SEL)action;


- (void)appStart;
- (void)appEnterForeground;
- (void)appEnterBackground;


- (void)appShouldAskForEmail:(RDUShouldAskBlock)block;
- (void)appSendEmail:(NSString *)email;

- (void)shouldAskForTwitter:(RDUShouldAskBlock)block;
- (void)appTwitterFollowDone:(NSString *)username;


@property(nonatomic, assign) BOOL       waitForPushToken;
@property(nonatomic, assign) BOOL       needsAppHash; 
@property(nonatomic, retain) NSString   *appTag;

@property(nonatomic, retain) NSData     *pushToken;
@property(nonatomic, assign) BOOL       debugMode;

@end
