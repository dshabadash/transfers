//
//  PBHtmlBuilder.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PBHtmlBuilder : NSObject

+ (id)htmlBuilder;

/*
 Add raw HTML text to the end of the document
 */
- (void)appendHtmlString:(NSString *)htmlString;

/*
 Add single HTML element that doesn't require enclosing pair, like <br>
 [htmlBuilder appendElementWithTagName:@"br"];
 */
- (NSString *)createElementWithTagName:(NSString *)tagName;
- (void)appendElementWithTagName:(NSString *)tagName; //for not paired tags, like <br>

/*
 Add HTML element that requires enclosing pair, like <b>boldText</b>
 [htmlBuilder appendElementWithTagName:@"b" innerHtml:@"boldText"];
 */
- (NSString *)createElementWithTagName:(NSString *)tagName innerHtml:(id)innerHtml;
- (void)appendElementWithTagName:(NSString *)tagName innerHtml:(id)innerHtml; //for paired tags like <b>innerHtml</b>

/*
 Add HTML element that requires enclosing pair, like <a href="http://capablebits.com">Visit us</a>
 [htmlBuilder appendElementWithTagName:@"a" innerHtml:@"Visit us" parameters:@{@"href": @"http://capablebits.com"}];
 */
- (NSString *)createElementWithTagName:(NSString *)tagName innerHtml:(id)innerHtml parameters:(NSDictionary *)parameters;
- (void)appendElementWithTagName:(NSString *)tagName innerHtml:(id)innerHtml parameters:(NSDictionary *)parameters;

//get HTML Document string
- (NSString *)htmlString;

@end
