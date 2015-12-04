//
//  NSBundle+CB.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 22/01/2013.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "NSBundle+CB.h"

@implementation NSBundle (CB)

- (id)loadNibNamed:(NSString *)aNibName {
    NSString *ipadSuffix = @"";
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        ipadSuffix = @"-ipad";
    }
    
    NSString *nibName = [aNibName stringByAppendingString:ipadSuffix];
    
    NSString *nibPath = [self pathForResource:nibName ofType:@"nib"];
    if (!nibPath) {
        nibName = aNibName;
        nibPath = [self pathForResource:nibName ofType:@"nib"];
    }
    
    if (!nibPath) {
        return nil;
    }
    
    return [[NSBundle mainBundle] loadNibNamed:nibName
                                         owner:nil
                                       options:nil];
}

@end
