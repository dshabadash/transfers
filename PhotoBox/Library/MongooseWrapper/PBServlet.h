//
//  Servlet.h
//  MongooseWrapper
//
//  Created by Fabio Rodella on 6/10/11.
//  Copyright 2011 Crocodella Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBServletRequest.h"
#import "PBServletResponse.h"

/**
 * Main servlet class. Should not be used directly, but subclassed
 */
@interface PBServlet : NSObject {
    
}

+ (id)servlet;

/**
 * Handles a GET request
 *
 * @param request The request data
 * @returns a response to be sent to the client
 */
- (PBServletResponse *)doGet:(PBServletRequest *)request;

/**
 * Handles a POST request
 *
 * @param request The request data
 * @returns a response to be sent to the client
 */
- (PBServletResponse *)doPost:(PBServletRequest *)request;


/**
 * Handles a OPTIONS request
 *
 * @param request The request data
 * @returns a response to be sent to the client
 */
- (PBServletResponse *)doOptions:(PBServletRequest *)request;

/**
 * Handles a PUT request
 *
 * @param request The request data
 * @returns a response to be sent to the client
 */
- (PBServletResponse *)doPut:(PBServletRequest *)request;

/**
 * Handles a DELETE request
 *
 * @param request The request data
 * @returns a response to be sent to the client
 */
- (PBServletResponse *)doDelete:(PBServletRequest *)request;

/**
 * Notifies servlet when responce is delivered to client
 *
 * @param response the responce sent to client
 */
- (void)finishedSendingServletResponse:(PBServletResponse *)response;

/**
 * Convenience method to return a 500 error
 *
 * @returns a response to be sent to the client
 */
- (PBServletResponse *)sendInternalError;

/**
 * Convenience method to return a 404 error
 *
 * @returns a response to be sent to the client
 */
- (PBServletResponse *)sendNotFound;

/**
 * Convenience method to return a 401 error
 *
 * @returns a response to be sent to the client
 */
- (PBServletResponse *)sendNotImplemented;

/**
 * Extracts parameters from request path
 *
 * @returns a response to be sent to the client
 */
-(NSDictionary *)extractParametersFromPath:(NSString *)path;


//
@property (assign, nonatomic) BOOL notifyPostBodyProgressUpdates;
@property (assign, nonatomic) BOOL notifyGetBodyProgressUpdates;

@end
