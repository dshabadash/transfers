//
//  PBTransferSession.h
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 4/9/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kConnectionAccepted;
extern NSString * const kConnectionRejected;
extern NSString * const PBTransferWasCanceledNotification;
extern NSString * const kBeginTransferPath;
extern NSString * const kFinishTransferPath;
extern NSString * const kCancelTransferPath;

@interface PBTransferSession : NSObject
@property (copy, nonatomic, readonly) NSString *URLString;
@property (copy, nonatomic, readonly) NSString *deviceName;
@property (assign, nonatomic, readonly) BOOL isCanceled;
- (PBTransferSession *)initWithDeviceName:(NSString *)deviceName URLString:(NSString *)URLString;
- (void)beginSessionCompletion:(void (^)(BOOL started))completion;
- (void)finishSessionCompletion:(void (^)(void))completion;
- (void)cancel;
@end
