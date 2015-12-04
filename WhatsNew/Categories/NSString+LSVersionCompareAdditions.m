//
//  NSString+LSVersionCompareAdditions.m
//  MyApp
//
//  Created by ameleshko on 1/6/15.
//  Copyright (c) 2015 My Company. All rights reserved.
//

#import "NSString+LSVersionCompareAdditions.h"

@implementation NSString (LSVersionCompareAdditions)

//version compare
+ (NSComparisonResult)compareVersion:(NSString *)ver1 toVersion:(NSString *)ver2 {

    NSMutableArray *ver1Array = [NSMutableArray arrayWithArray:[ver1 componentsSeparatedByString:@"."]];
    NSMutableArray *ver2Array = [NSMutableArray arrayWithArray:[ver2 componentsSeparatedByString:@"."]];
    
    while ([ver1Array count] < 4) {
        [ver1Array addObject:@"0"];
    }
    while ([ver2Array count] < 4) {
        [ver2Array addObject:@"0"];
    }
    
    NSString *ver1String = [NSString stringWithFormat:@"%@%@%@%@", ver1Array[0], ver1Array[1],ver1Array[2],ver1Array[3]];
    NSString *ver2String = [NSString stringWithFormat:@"%@%@%@%@", ver2Array[0], ver2Array[1],ver2Array[2],ver2Array[3]];
    
    NSInteger ver1Int = [ver1String integerValue];
    NSInteger ver2Int = [ver2String integerValue];
    
    if (ver1Int < ver2Int) {
        return NSOrderedAscending;
    }
    else if (ver1Int > ver2Int) {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
    
}

@end
