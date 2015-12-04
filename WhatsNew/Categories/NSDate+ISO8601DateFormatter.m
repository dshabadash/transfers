//
//  NSDate+ISO8601DateFormatter.m
//  MyApp
//
//  Created by ameleshko on 2/14/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "NSDate+ISO8601DateFormatter.h"
#import "ISO8601DateFormatter.h"



@implementation NSDate (ISO8601DateFormatter)

+ (ISO8601DateFormatter *)ISO8601DateFormatter{
    ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
    formatter.includeTime = YES;
    return formatter;
}

+ (NSDate *)dateFromISO8601String:(NSString *)str{
    if(str){
        NSDate *date = [[self ISO8601DateFormatter] dateFromString:str];
        return date;
    }
    return nil;
}

+ (NSString *)iso8601StringFromDate:(NSDate *)date{
    if(date){
        NSString *str = [[self ISO8601DateFormatter] stringFromDate:date];
        return str;
    }
    return nil;
}


@end
