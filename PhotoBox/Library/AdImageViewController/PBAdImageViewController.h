//
//  PBAdImageViewController.h
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 7/8/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AdMessage;
@protocol AdImageViewControllerDelegate;

@interface PBAdImageViewController : UIViewController
@property (nonatomic, assign) id<AdImageViewControllerDelegate> delegate;
@property (nonatomic, unsafe_unretained) IBOutlet UIImageView *adImageView;
@property (nonatomic, copy) NSURL *adLinkURL;

- (IBAction)didTapCloseButton:(id)sender;
- (IBAction)didTapOpenAdLinkButton:(id)sender;

@end

@protocol AdImageViewControllerDelegate<NSObject>
- (void)dismissAdImageViewController:(PBAdImageViewController *)controller;
@end


#pragma mark - PBAdMessageLoader class

@interface PBAdMessageLoader : NSObject
- (void)loadAdMessageLaunchNumber:(NSInteger)launchNumber
                  applicationName:(NSString *)applicationName
                       completion:(void (^)(AdMessage *message))completion;

- (void)loadAdMessageID:(NSInteger)messageID
             completion:(void (^)(AdMessage *message))completion;

@end


#pragma mark - AdMessage class

@interface AdMessage : NSObject
@property (copy, nonatomic) NSString *text;
@property (copy, nonatomic) NSString *adImageURLString;
@property (copy, nonatomic) NSString *adLinkURLString;

- (instancetype)initWithProperties:(NSDictionary *)properties;

@end
