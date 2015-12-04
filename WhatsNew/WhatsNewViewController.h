//
//  WhatsNewViewController.h
//  MyApp
//
//  Created by Artem Meleshko on 12/29/14.
//  Copyright (c) 2014 My Company. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef void (^WhatsNewViewControllerCompletionBlock)(void);


@interface WhatsNewViewController : UINavigationController

- (instancetype)initWithTitle:(NSString *)titleText
                       detail:(NSString *)detailText
                     rateInfo:(NSDictionary *)rateInfo
                   completion:(WhatsNewViewControllerCompletionBlock)completion;


- (void)show:(BOOL)animated;

- (void)hide:(BOOL)animated;

+ (NSDictionary *)rateInfoWithMessage:(NSString *)titleText
                    title:(NSString *)rateTitle;

@end
