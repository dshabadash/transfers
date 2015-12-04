//
//  NSDate+ISO8601DateFormatter.h
//  MyApp
//
//  Created by ameleshko on 2/14/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ISO8601DateFormatter)

+ (NSDate *)dateFromISO8601String:(NSString *)str;

+ (NSString *)iso8601StringFromDate:(NSDate *)date;

@end
