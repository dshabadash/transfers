//
//  NSString+LSFormatAdditions.h
//  MyApp
//
//  Created by ameleshko on 1/6/15.
//  Copyright (c) 2015 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LSFormatAdditions)

- (NSString *)trim;

- (NSString *)cropToIndex:(NSUInteger)to;

- (NSString *)stringByStrippingHTML;

- (NSString *)stringByDeletingContentInRoundBrackets;

+ (NSString *)stringByURLEncodingForURI:(NSString *)str;

- (unsigned long long)unsignedLongLongValue;

@end
