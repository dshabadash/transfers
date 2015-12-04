//
//  NSString+CB.h
//  Browser
//
//  Created by Andrew Kosovich on 7/24/12.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (CB)

+ (NSString *)stringFromFileSize:(NSInteger)theSize;
+ (NSString *)copyReaddleStringWithFormat:(NSString *)format arguments:(va_list)argList;
+ (NSString *)stringWithInteger:(NSInteger)integerNumber;
+ (NSString *)normalizedASCIIStringWithString:(NSString *)stringToNormalize;

- (NSString *)stringByDeletingLastSlash;
- (BOOL)hasString:(NSString *)s;
- (BOOL)hasStringInsensitive:(NSString *)s;
- (BOOL)hasContent;
- (NSString *)trim;
- (NSString *)shortStringWithMaxLength:(int)l;
- (NSString *)stringByAppendingURLComponent:(NSString *)component;
- (NSString *)stringByAppendingURLExtension:(NSString *)extension;
- (NSString *)stringByDeletingLastURLComponent;
- (NSString *)stringByDeletingBeginningOfPath:(NSString*)pathBeginning;
- (BOOL)isBasePathOfPath:(NSString*)path;
- (BOOL)isDirectParentPathOfPath:(NSString*)path;
- (BOOL)isEqualToPath:(NSString*)path;
- (BOOL)isValidEmail;

- (NSString *)urlStringByDeletingCapableBrowserInternalAdditions;

- (NSString *)filesystemSafeString;


- (NSString *)host; //returns host of url contained in string or nil, if url is not correct
- (NSString *)urlStringByDeletingHttpWwwPrefix; //http://www.apple.com/mac => apple.com/mac

@end
