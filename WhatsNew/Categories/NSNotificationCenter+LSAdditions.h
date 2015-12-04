//
//  NSNotificationCenter+LSAdditions.h
//  MyApp
//
//  Created by Artem Meleshko on 3/13/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotificationCenter (LSAdditions)

- (void)postInMainThreadNotificationName:(NSString *)aName object:(id)anObject;

- (void)postInMainThreadNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)userInfo;

@end
