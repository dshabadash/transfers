//
//  NSString+CB.m
//  Browser
//
//  Created by Andrew Kosovich on 7/24/12.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "NSString+CB.h"

@implementation NSString (CB)

+ (NSString *)stringFromFileSize:(NSInteger)theSize
{
	float floatSize = theSize;
	if (theSize<1023)
		return([NSString stringWithFormat:@"%li bytes",(long)theSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
	floatSize = floatSize / 1024;
    
	return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

+ (NSString *)copyReaddleStringWithFormat:(NSString *)format arguments:(va_list)argList {
	NSArray *pparts = [format componentsSeparatedByString:@"%"];
	NSMutableString *result = [[NSMutableString alloc] initWithCapacity:[format length]*2];
    
	int i = 0;
	for(NSString *s in pparts) {
		i++;
        
		if (i == 1) {
			[result appendString:s];
			continue;
		}
        
		if ([s isEqualToString:@""]) {
			if (i != [pparts count])
				[result appendString:@"%"];
			continue;
		}
        
		int flen = 1; // format length
		if ([s hasPrefix:@"point"]) {
			flen = 5;
			CGPoint p = va_arg(argList, CGPoint);
			[result appendFormat:@"(%f, %f)", p.x, p.y];
		}
		else if ([s hasPrefix:@"size"]) {
			flen = 4;
			CGSize s = va_arg(argList, CGSize);
			[result appendFormat:@"%fx%f", s.width, s.height];
		}
		else if ([s hasPrefix:@"rect"]) {
			flen = 4;
			CGRect r = va_arg(argList, CGRect);
			[result appendFormat:@"[(%f, %f) %fx%f]", r.origin.x, r.origin.y, r.size.width, r.size.height];
		}
		else if ([s hasPrefix:@"frame"]) {
			flen = 5;
			CGRect r = va_arg(argList, CGRect);
			[result appendFormat:@"[(%f, %f) %fx%f]", r.origin.x, r.origin.y, r.size.width, r.size.height];
		}
		else if ([s hasPrefix:@"range"]) {
			flen = 5;
			NSRange r = va_arg(argList, NSRange);
			[result appendFormat:@"[%d +%d]", (int)r.location, (int)r.length];
		}
		else if ([s hasPrefix:@"class"]) {
			flen = 5;
			id c = va_arg(argList, id);
			[result appendFormat:@"%@", [c class]];
		}
		else if ([s hasPrefix:@"@"]) {
			id c = va_arg(argList, id);
			[result appendFormat:@"%@", c];
		}
		else if ([s hasPrefix:@"d"]) {
			int c = va_arg(argList, int);
			[result appendFormat:@"%d", c];
		}
		else if ([s hasPrefix:@"u"]) {
			unsigned int c = va_arg(argList, unsigned int);
			[result appendFormat:@"%u", c];
		}
		else if ([s hasPrefix:@"lld"]) {
			flen = 3;
			long long c = va_arg(argList, long long);
			[result appendFormat:@"%lld", c];
		}
		else if ([s hasPrefix:@"f"]) {
			double c = va_arg(argList, double);
			[result appendFormat:@"%f", c];
		}
		else if ([s hasPrefix:@"p"]) {
			int c = va_arg(argList, int);
			[result appendFormat:@"%x", c];
            
		}
		else if ([s hasPrefix:@"s"]) {
			char *c = va_arg(argList, char *);
			[result appendFormat:@"%s", c];
		}
		else {
			NSString *fstring = [[NSString alloc] initWithFormat:@"%%%@", s];
			NSString *tmp = [[NSString alloc] initWithFormat:fstring arguments:argList];
			// lets pray and hope that initWithFormat:arguments: will shift argument list
			[result appendString:tmp];
			[tmp release];
			[fstring release];
			flen = (int)[s length]; // do not add source string at all
		}
        
		if ([s length] > flen)
			[result appendString:[s substringFromIndex:flen]];
	}
    
	return result;
}

+ (NSString *)stringWithInteger:(NSInteger)integerNumber {
    return [NSString stringWithFormat:@"%d", (int)integerNumber];
}

+ (NSString *)normalizedASCIIStringWithString:(NSString *)stringToNormalize {
    NSMutableString *asciiCharacters = [NSMutableString string];
    for (NSInteger i = 32; i < 127; i++)  {
        [asciiCharacters appendFormat:@"%c", (int)i];
    }

    NSCharacterSet *nonAsciiCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:asciiCharacters] invertedSet];
    NSString *normalizedString = [[stringToNormalize componentsSeparatedByCharactersInSet:nonAsciiCharacterSet] componentsJoinedByString:@""];

    return normalizedString;
}

- (NSString *)stringByDeletingLastSlash {
	if ([self length] > 1 && [self hasSuffix:@"/"]) {
		return [self substringToIndex:[self length] - 1];
	}
	else
		return self;
}

- (BOOL)hasString:(NSString *)s {
	return ([self rangeOfString:s].location != NSNotFound);
}

- (BOOL)hasStringInsensitive:(NSString *)s {
	return ([self rangeOfString:s options:NSCaseInsensitiveSearch].location != NSNotFound);
}

- (BOOL)hasContent {
    return [self length] > 0;
}

- (NSString *)trim {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)shortStringWithMaxLength:(int)l {
	if (l == 0) l = 25;
	if ([self length] <= l) return self;
    
	int middle = l / 2;
	NSString *shortString = [NSString stringWithFormat:@"%@...%@",
							 [self substringToIndex:(middle-3)],
							 [self substringFromIndex:([self length] - middle)]];
    
	return shortString;
}

- (NSString *)stringByAppendingSomething:(NSString *)component separator:(NSString *)separator {
	if ([component hasContent] == NO)
		return [[self copy] autorelease];
    
	if ([self hasSuffix:separator]) {
		if ([component hasPrefix:separator])
			return [self stringByAppendingString:[component substringFromIndex:[separator length]]]; // /url/ + /path =  /url/path
		else
			return [self stringByAppendingString:component];	// /url/ + path = /url/path
	}
	else {
		if ([component hasPrefix:separator])
			return [self stringByAppendingString:component];
		else {
			return [self stringByAppendingFormat:@"%@%@", separator, component];
		}
	}
    
}

- (NSString *)stringByAppendingURLComponent:(NSString *)component {
	return [self stringByAppendingSomething:component separator:@"/"];
}

- (NSString *)stringByAppendingURLExtension:(NSString *)extension {
	return [self stringByAppendingSomething:extension separator:@"."];
}

- (NSString *)stringByDeletingLastURLComponent {
	int index = (int)([self length] - [[self lastPathComponent] length]);
	return [self substringToIndex:index];
}

- (NSString*)stringByDeletingBeginningOfPath:(NSString*)pathBeginning {
    pathBeginning = [pathBeginning stringByNormalizingPathAndAddingTrailingSlash:YES];
    NSString* normalizedSelf = [self stringByNormalizingPathAndAddingTrailingSlash:YES];
    NSString* result = normalizedSelf;
    NSRange range = [normalizedSelf rangeOfString:pathBeginning];
    
    if (range.location != NSNotFound) {
        range.length -= 1; //for trailing slash
        result = [normalizedSelf stringByReplacingCharactersInRange:range withString:@""];
        if ([result length] == 0) {
            result = @"/";
        }
    }
    if (![self hasSuffix:@"/"] && [result hasSuffix:@"/"] && result.length > 1) {
        result = [result stringByDeletingLastSlash];
    }
    return result;
}

- (BOOL)isBasePathOfPath:(NSString*)path {
    if (self.length > 0 && path.length > 0) {
        NSString* basePath = [self stringByNormalizingPathAndAddingTrailingSlash:YES];
        NSString* normalizedPath = [path stringByNormalizingPathAndAddingTrailingSlash:YES];
        
        return [normalizedPath hasPrefix:basePath] && normalizedPath.length != basePath.length;
    }
    return NO;
}

- (NSString*)stringByNormalizingPathAndAddingTrailingSlash:(BOOL)addSlash {
    NSString* normilizedPath = [self stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
    
    normilizedPath = [normilizedPath stringByReplacingOccurrencesOfString:@"/./" withString:@"/"];
    if ([normilizedPath hasPrefix:@"/private/"]) {
        normilizedPath = [normilizedPath substringFromIndex:[@"/private" length]];
    }
    if (addSlash && ![normilizedPath hasSuffix:@"/"]) {
        normilizedPath = [normilizedPath stringByAppendingString:@"/"];
    }
    return normilizedPath;
}

- (BOOL)isDirectParentPathOfPath:(NSString*)path {
    return [self isEqualToPath:[path stringByDeletingLastPathComponent]];
}

- (BOOL)isEqualToPath:(NSString*)path {
    NSString* normalizedSelf = [self stringByNormalizingPathAndAddingTrailingSlash:YES];
    NSString* normalizedPath = [path stringByNormalizingPathAndAddingTrailingSlash:YES];
    
    return [normalizedSelf isEqualToString:normalizedPath];
}

- (BOOL)isValidEmail {
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

- (NSString *)urlStringByDeletingCapableBrowserInternalAdditions {
    NSString *newTabSuffix = @"cbinternal_blank=1";
    NSInteger newTabSuffixLength = [newTabSuffix length] + 1; //add the '&' or '?' before suffix
    NSInteger urlStringLength = [self length];
    if (urlStringLength > newTabSuffixLength && [self hasSuffix:newTabSuffix]) {
        NSString *newUrlString = [self substringToIndex:urlStringLength-newTabSuffixLength];
        return newUrlString;
    }
    return [NSString stringWithString:self];
}

- (NSString *)filesystemSafeString {
    NSString *newString = [self stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    newString = [newString stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    newString = [newString stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    newString = [newString stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
    newString = [newString stringByReplacingOccurrencesOfString:@"*" withString:@"_"];
    newString = [newString stringByReplacingOccurrencesOfString:@"%" withString:@"_"];
    newString = [newString stringByReplacingOccurrencesOfString:@"|" withString:@"_"];
    newString = [newString stringByReplacingOccurrencesOfString:@"\"" withString:@"_"];
    newString = [newString stringByReplacingOccurrencesOfString:@"<" withString:@"_"];
    newString = [newString stringByReplacingOccurrencesOfString:@">" withString:@"_"];

    return newString;
}

- (NSString *)host {
    NSURL *url = [NSURL URLWithString:self];
    if (url) {
        NSString *host = url.host;
        return host;
    }
    
    return nil;
}

- (NSString *)urlStringByDeletingHttpWwwPrefix {
    NSString *newUrlString = [self stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    newUrlString = [newUrlString stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    newUrlString = [newUrlString stringByDeletingLastSlash];
    if ([newUrlString hasPrefix:@"www."]) {
        newUrlString = [newUrlString substringFromIndex:4];
    }

    return newUrlString;
}

@end
