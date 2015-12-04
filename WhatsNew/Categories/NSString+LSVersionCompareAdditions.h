//
//  NSString+LSVersionCompareAdditions.h
//  MyApp
//
//  Created by ameleshko on 1/6/15.
//  Copyright (c) 2015 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LSVersionCompareAdditions)

//version compare
+ (NSComparisonResult)compareVersion:(NSString *)ver1 toVersion:(NSString *)ver2;


@end
