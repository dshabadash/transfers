//
//  PBHtmlBuilder.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBHtmlBuilder.h"

@interface PBHtmlBuilder () {
    NSMutableString *_htmlString;
}

@end

@implementation PBHtmlBuilder

+ (id)htmlBuilder {
    return [[self new] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        _htmlString = [[NSMutableString alloc] initWithCapacity:1024];

        [self appendElementWithTagName:@"html"];
        
        NSString *titleHtml = [self createElementWithTagName:@"title" innerHtml:PB_APP_NAME];
        NSString *charsetHtml = [self createElementWithTagName:@"meta" innerHtml:nil parameters:@{@"charset" : @"utf-8"}];
        [self appendElementWithTagName:@"head" innerHtml:@[titleHtml, charsetHtml]];
    }
    return self;
}

#pragma mark - Adding elements

- (void)appendHtmlString:(NSString *)htmlString {
    [_htmlString appendString:htmlString];
}

- (NSString *)createElementWithTagName:(NSString *)tagName {
    NSString *htmlString = [NSString stringWithFormat:@"<%@>", tagName];
    return htmlString;
}

- (NSString *)createElementWithTagName:(NSString *)tagName innerHtml:(id)innerHtml {
    NSString *htmlString = [self createElementWithTagName:tagName innerHtml:innerHtml parameters:nil];
    return htmlString;
}

- (NSString *)createElementWithTagName:(NSString *)tagName innerHtml:(id)innerHtml parameters:(NSDictionary *)parameters {
    NSMutableString *htmlString = [NSMutableString string];
    [htmlString appendFormat:@"<%@", tagName];
    
    Class stringClass = [NSString class];
    
    for (id key in parameters.allKeys) {
        if ([key isKindOfClass:stringClass]) {
            id value = parameters[key];
            if ([value isKindOfClass:stringClass]) {
                [htmlString appendFormat:@" %@=\"%@\"", key, value];
            }
        }
    }
    
    NSMutableString *tmpInnerHtml = [NSMutableString string];
    if ([innerHtml isKindOfClass:stringClass]) {
        [tmpInnerHtml appendString:innerHtml];
    } else if ([innerHtml isKindOfClass:[NSArray class]]) {
        for (id object in innerHtml) {
            if ([object isKindOfClass:stringClass]) {
                [tmpInnerHtml appendString:object];
            }
        }
    }
    
    [htmlString appendFormat:@">%@</%@>", tmpInnerHtml, tagName];

    return htmlString;
}


- (void)appendElementWithTagName:(NSString *)tagName {
    [_htmlString appendString:[self createElementWithTagName:tagName]];
}

- (void)appendElementWithTagName:(NSString *)tagName innerHtml:(id)innerHtml {
    [_htmlString appendString:[self createElementWithTagName:tagName innerHtml:innerHtml]];
}

- (void)appendElementWithTagName:(NSString *)tagName innerHtml:(id)innerHtml parameters:(NSDictionary *)parameters {
    [_htmlString appendString:[self createElementWithTagName:tagName innerHtml:innerHtml parameters:parameters]];
}

#pragma mark - Getting the result

- (NSString *)htmlString {
    if ([_htmlString hasSuffix:@"</html>"] == NO) {
        [self appendElementWithTagName:@"/html"];
    }
    
    NSString *htmlString = [NSString stringWithString:_htmlString];
    return htmlString;
}

@end
