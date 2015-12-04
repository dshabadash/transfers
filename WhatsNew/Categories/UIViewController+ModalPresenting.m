//
//  UIViewController+ModalPresenting.m
//  MyApp
//
//  Created by Artem Meleshko on 5/23/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import "UIViewController+ModalPresenting.h"
#import "LSConstants.h"



@implementation UIViewController (ModalPresenting)

- (void)presentModalViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion{

    if(DEVICE_IS_IPAD()){
        viewControllerToPresent.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        viewControllerToPresent.modalPresentationStyle = UIModalPresentationFormSheet;

        [self presentViewController:viewControllerToPresent animated:flag completion:^{            
            if(completion){
                completion();
            }
        }];
    }
    else{
        [self presentViewController:viewControllerToPresent animated:flag completion:completion];
    }
}

@end
