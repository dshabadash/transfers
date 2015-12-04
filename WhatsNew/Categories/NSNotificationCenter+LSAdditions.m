//
//  NSNotificationCenter+LSAdditions.m
//  MyApp
//
//  Created by Artem Meleshko on 3/13/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "NSNotificationCenter+LSAdditions.h"
#import "NSObject+LSAdditions.h"


@implementation NSNotificationCenter (LSAdditions)

- (void)postInMainThreadNotificationName:(NSString *)aName object:(id)anObject{
    [NSObject performBlockOnMainThreadAsync:^{
         [self postNotificationName:aName object:anObject];
    }];
}

- (void)postInMainThreadNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)userInfo{
    [NSObject performBlockOnMainThreadAsync:^{
        [self postNotificationName:aName object:anObject userInfo:userInfo];
    }];
}

@end
