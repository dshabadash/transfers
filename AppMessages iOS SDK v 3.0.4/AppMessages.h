//
//  AppMessages.h
//  AppMessages SDK
//
//  Created by Max Pavlyuchenko on 3/22/13.
//  Copyright (c) 2013 Apalon. All rights reserved.
//

#import <Foundation/Foundation.h>


#define APPMESS_SDK_APP_ID @"febe-665c-18d7-e7ad-2058-5d8c-16fa-4fb4"
#define APPMESS_SDK_APP_KEY @"e885de1c543bbef4"
#define AM_SERVER_URL @"http://ofukoskz.api.appmessages.com"


/*
    NSDictionary * params = [NSDictionary dictionaryWithObjectsAndKeys:
                                        APPMESS_SDK_APP_ID, @"amApplicationCode",
                                        APPMESS_SDK_APP_KEY, @"amSecretKey",
                                        AM_SERVER_URL, @"amServerUrl",
                                        [NSNumber numberWithBool:YES], @"showAutomatically",
                                        nil];

    [AppMessages invokeWithParams:params];
 */

@interface AppMessages : NSObject

+(BOOL)invokeWithParams:(NSDictionary*)params;
+(void)restoreFromBackground;

@end
