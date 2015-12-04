//
//  UIViewController+ModalPresenting.h
//  MyApp
//
//  Created by Artem Meleshko on 5/23/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (ModalPresenting)

- (void)presentModalViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;

@end
