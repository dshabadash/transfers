//
//  NSObject+PB.m
//  Browser
//
//  Created by Andrew Kosovich on 7/24/12.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "NSObject+PB.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (PB)

+ (Class)currentTargetImplementationClass {
#if defined (PB_RESOURCE_PREFIX)
    NSString *className = NSStringFromClass([self class]);
    NSString *prefix = PB_RESOURCE_PREFIX;
    
    NSString *prefixedClassName = [prefix stringByAppendingFormat:@"_%@", className];
    Class resultClass = NSClassFromString(prefixedClassName);
    BOOL isSubclass = [resultClass isSubclassOfClass:[self class]];
    if (resultClass == nil || !isSubclass) {
        resultClass = [self class];
    }
    return resultClass;
#else
    return [self class];
#endif
}

- (id)checkAndPerformSelector:(SEL)aSelector {
	if ([self respondsToSelector:aSelector])
		return [self performSelector:aSelector];
	return nil;
}

- (id)checkAndPerformSelector:(SEL)aSelector withObject:(id)object {
	if ([self respondsToSelector:aSelector])
		return [self performSelector:aSelector withObject:object];
	return nil;
}

- (id)checkAndPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 {
	if ([self respondsToSelector:aSelector])
		return [self performSelector:aSelector withObject:object1 withObject:object2];
	return nil;
}

- (id)checkAndPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3 {
    if ([self respondsToSelector:aSelector])
        return [self performSelector:aSelector withObject:object1 withObject:object2 withObject:object3];
    return nil;
}

- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3 {
    return objc_msgSend(self, aSelector, object1, object2, object3);
}

- (void)performSelectorLater:(SEL)aSelector withObject:(id)arg {
	[self performSelector:aSelector withObject:arg afterDelay:0.01];
}

- (void)checkAndPerformSelector:(SEL)aSelector onThread:(NSThread*)thread {
    [self checkAndPerformSelector:aSelector
                       withObject:nil
                         onThread:thread];
}

- (void)checkAndPerformSelector:(SEL)aSelector withObject:(id)object onThread:(NSThread*)thread {
    if ([self respondsToSelector:aSelector]) {
        
        NSThread *threadToPerformOn = nil;
        if (thread != nil) {
            threadToPerformOn = thread;
        } else {
            threadToPerformOn = [NSThread currentThread];
        }
        
        [self performSelector:aSelector
                     onThread:threadToPerformOn
                   withObject:object
                waitUntilDone:NO];
    }
}

- (void)performSelectorWithTwoArgsInDictionary:(NSDictionary*)dic {
    NSString *selectorName = [dic objectForKey:@"selectorName"];
    SEL selector = NSSelectorFromString(selectorName);
    
    NSObject *object1 = [dic objectForKey:@"object1"];
    NSObject *object2 = [dic objectForKey:@"object2"];
    
    [self performSelector:selector
               withObject:object1
               withObject:object2];
}

- (void)performSelectorWithThreeArgsInDictionary:(NSDictionary*)dic {
    NSString *selectorName = [dic objectForKey:@"selectorName"];
    SEL selector = NSSelectorFromString(selectorName);
    
    NSObject *object1 = [dic objectForKey:@"object1"];
    NSObject *object2 = [dic objectForKey:@"object2"];
    NSObject *object3 = [dic objectForKey:@"object3"];
    
    [self performSelector:selector
               withObject:object1
               withObject:object2
               withObject:object3];
}

- (void)checkAndPerformSelector:(SEL)aSelector
                     withObject:(id)object1
                     withObject:(id)object2
                       onThread:(NSThread*)thread
{
	if ([self respondsToSelector:aSelector]) {
        if (object1 == nil) {
            object1 = [NSNull null];
        }
        
        NSString *selectorName = NSStringFromSelector(aSelector);
        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                           selectorName, @"selectorName",
                           object1, @"object1",
                           object2, @"object2",
                           nil];
        
        NSThread *threadToPerformOn = nil;
        if (thread != nil) {
            threadToPerformOn = thread;
        } else {
            threadToPerformOn = [NSThread currentThread];
        }
        
        
        [self performSelector:@selector(performSelectorWithTwoArgsInDictionary:)
                     onThread:threadToPerformOn
                   withObject:d
                waitUntilDone:NO];
    }
}

- (void)checkAndPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3 onThread:(NSThread*)thread {
    if ([self respondsToSelector:aSelector]) {
        NSString *selectorName = NSStringFromSelector(aSelector);
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObject:selectorName forKey:@"selectorName"];
        
        if (object1) {
            [d setObject:object1 forKey:@"object1"];
        }
        if (object2) {
            [d setObject:object2 forKey:@"object2"];
        }
        if (object3) {
            [d setObject:object3 forKey:@"object3"];
        }
        NSThread *threadToPerformOn = nil;
        if (thread != nil) {
            threadToPerformOn = thread;
        } else {
            threadToPerformOn = [NSThread currentThread];
        }
        
        
        [self performSelector:@selector(performSelectorWithThreeArgsInDictionary:)
                     onThread:threadToPerformOn
                   withObject:d
                waitUntilDone:NO];
    }
}

- (id)performSuperSelector:(SEL)selector withObject:(id)object1 withObject:(id)object2 {
    struct objc_super theSuper;
    theSuper.receiver = self;
    theSuper.super_class = [[self class] superclass];
    return objc_msgSendSuper(&theSuper, selector, object1, object2);
}

@end
