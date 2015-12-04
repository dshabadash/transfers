//
//  NSString+LSFormatAdditions.m
//  MyApp
//
//  Created by ameleshko on 1/6/15.
//  Copyright (c) 2015 My Company. All rights reserved.
//

#import "NSString+LSFormatAdditions.h"

@implementation NSString (LSFormatAdditions)

- (NSString *)trim{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)cropToIndex:(NSUInteger)to{
    if((self.length-1)<=to){
        return self;
    }
    return [self substringToIndex:to];
}

- (NSString *)stringByStrippingHTML {
    NSRange r;
    NSString *s = [self copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

- (NSString *)stringByDeletingContentInRoundBrackets{
    NSRange r;
    NSString *s = [self copy];
    while ((r = [s rangeOfString:@"\\([^\\)]+\\)" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

+ (NSString *)stringByURLEncodingForURI:(NSString *)str {
    
     NSString *string = (__bridge_transfer NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                        (__bridge CFStringRef) str,
                                                                                        NULL,
                                                                                        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                        kCFStringEncodingUTF8);
    return string;
    
}

- (unsigned long long)unsignedLongLongValue{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *myNumber = [f numberFromString:self];
    unsigned long long result = [myNumber unsignedLongLongValue];
    return result;
}

@end
