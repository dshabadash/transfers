//
//  NSObject+LSAdditions.h
//  MyApp
//
//  Created by Artem Meleshko on 2/15/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^NSObjectVoidBlock)(void);

@interface NSObject (LSAdditions)

- (void)performBlockOnMainThreadSync:(NSObjectVoidBlock)block;

- (void)performBlockOnMainThreadAsync:(NSObjectVoidBlock)block;

- (void)performBlockOnBackgroundThreadAsync:(NSObjectVoidBlock)block;

@end
