 //
//  PBAdImageViewController.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 7/8/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBAdImageViewController.h"
#import "RDUsageTracker.h"
#import "RDHTTP.h"

@interface PBAdImageViewController ()

@end

@implementation PBAdImageViewController

- (void)openAdLink {
    if ((nil != _adLinkURL) &&
        [[UIApplication sharedApplication] canOpenURL:_adLinkURL]) {

        [[UIApplication sharedApplication] openURL:_adLinkURL];
    }
}

- (void)logAdImageClick {
    NSString *deviceType;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        deviceType = @"ipad";
    }
    else if (CGRectGetHeight([[UIScreen mainScreen] bounds]) > 480.0) {
        deviceType = @"iphone5";
    }
    else {
        deviceType = @"iphone";
    }

    NSDictionary *params = @{@"adLinkURL" : _adLinkURL,
                             @"device" : deviceType,
                             @"appName" : PB_APP_NAME};

    [[CBAnalyticsManager sharedManager] logEvent:@"AdImageHasBeenTapped" withParameters:params];
}


#pragma mark - View

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - Events handling

- (IBAction)didTapCloseButton:(id)sender {
    [_delegate dismissAdImageViewController:self];
}

- (IBAction)didTapOpenAdLinkButton:(id)sender {
    [self logAdImageClick];
    [self openAdLink];
    [_delegate dismissAdImageViewController:self];
}

@end


#pragma mark - PBAdMessageLoader class

@implementation PBAdMessageLoader

- (NSString *)URLStringWithMessageID:(NSInteger)messageID {
    NSString *URLTemplate = @"http://sendp.com/get_message.php?id=%i";
    NSString *URLString = [NSString stringWithFormat:URLTemplate, messageID];

    return URLString;
}

- (NSString *)URLStringWithApplicationName:(NSString *)appName
                              launchNumber:(NSInteger)launchNumber {

    NSString *URLTemplate = @"http://sendp.com/get_launch_message.php?app_name=%@&launch_number=%i";
    NSString *URLString = [NSString stringWithFormat:URLTemplate, appName, launchNumber];

    return URLString;
}

- (void)loadAdMessageLaunchNumber:(NSInteger)launchNumber
                  applicationName:(NSString *)applicationName
                       completion:(void (^)(AdMessage *message))completion {

    NSString *URLString = [self URLStringWithApplicationName:applicationName
                                                launchNumber:launchNumber];
    
    [self loadAdMessageURLString:URLString completion:completion];
}

- (void)loadAdMessageID:(NSInteger)messageID
             completion:(void (^)(AdMessage *message))completion {

    NSString *URLString = [self URLStringWithMessageID:messageID];
    [self loadAdMessageURLString:URLString completion:completion];
}

- (void)loadAdMessageURLString:(NSString *)URLString
                    completion:(void (^)(AdMessage *message))completion {

    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURLString:URLString];
    request.timeoutInterval = 20.0;
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        NSDictionary *adMessage = nil;

        if (nil != response.responseData) {
            adMessage = [NSJSONSerialization
                JSONObjectWithData:response.responseData
                options:0
                error:nil];
        }

        AdMessage *message = [[[AdMessage alloc] initWithProperties:adMessage] autorelease];
        completion(message);
    }];
}

@end


#pragma mark - AdMessage class

@implementation AdMessage

- (instancetype)initWithProperties:(NSDictionary *)properties {
    self = [super init];

    if (nil != self) {
        if ((nil == properties) || ([properties count] == 0)) {
            return self;
        }

        _text = [properties objectForKey:@"text"];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            _adImageURLString = [properties objectForKey:@"ipad_link"];
        }
        else if (CGRectGetHeight([[UIScreen mainScreen] bounds]) > 480.0) {
            _adImageURLString = [properties objectForKey:@"iphone5_link"];
        }
        else {
            _adImageURLString = [properties objectForKey:@"iphone_link"];
        }

        _adLinkURLString = [properties objectForKey:@"ad_link"];
    }

    return self;
}

@end
