//
//  NSObject+PB.h
//  Browser
//
//  Created by Andrew Kosovich on 7/24/12.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (PB)

+ (Class)currentTargetImplementationClass;

- (id)checkAndPerformSelector:(SEL)aSelector;
- (id)checkAndPerformSelector:(SEL)aSelector withObject:(id)object;
- (id)checkAndPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;
- (id)checkAndPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3;
- (void)performSelectorLater:(SEL)aSelector withObject:(id)arg;
- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3;

- (void)checkAndPerformSelector:(SEL)aSelector onThread:(NSThread*)thread;
- (void)checkAndPerformSelector:(SEL)aSelector withObject:(id)object onThread:(NSThread*)thread;
- (void)checkAndPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 onThread:(NSThread*)thread;
- (void)checkAndPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3 onThread:(NSThread*)thread;

- (id)performSuperSelector:(SEL)selector withObject:(id)object1 withObject:(id)object2;

@end
