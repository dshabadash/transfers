//
//  MoongoseServer.h
//  MongooseWrapper
//
//  Created by Fabio Rodella on 6/10/11.
//  Copyright 2011 Crocodella Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBServlet.h"
#import "pbmongoose.h"

extern NSString * const PBMongooseServerPostBodyProgressDidUpdateNotification;
extern NSString * const PBMongooseServerGetBodyProgressDidUpdateNotification;

extern NSString * const PBMongooseServerPostBodyProgressDidFinishNotification;
extern NSString * const PBMongooseServerGetBodyProgressDidFinishNotification;

/**
 * Main wrapper object, handles the dispatching of requests to servlets
 */
@interface PBMongooseServer : NSObject {
    
    /**
     * Mongoose context
     */
    struct pbmg_context *ctx;
    
    /**
     * Servlets, where the key is the URI path
     */
    NSMutableDictionary *servlets;
}

@property (readonly,assign) struct pbmg_context *ctx;
@property (readonly, assign) int startedOnPort;
@property (readonly, assign) struct pbmg_connection *connection;
@property (readonly,retain) NSMutableDictionary *servlets;

/**
 * Creates a new server in the specified port, with an option to allow
 * directory and file listing
 *
 * @param port The port the server will be listening on
 * @param listing Flag indicating if directory listing is enabled
 * @returns a new server
 */
- (id)initWithPort:(int)port allowDirectoryListing:(BOOL)listing;

/**
 * Creates a new server with the options specified. Check the Mongoose
 * server documentation for the available options.
 *
 * @param options Array of options to initialize the server
 * @returns a new server
 */
- (id)initWithOptions:(const char *[])options;

/**
 * Registers a new servlet in the server
 *
 * @param servlet The servlet to be registered
 * @param path The URI path. It may contain the * wildcard
 */
- (void)addServlet:(PBServlet *)servlet forPath:(NSString *)path;

/**
 * Removes the server registered for the path
 *
 * @param path The URI path
 */
- (void)removeServletForPath:(NSString *)path;

- (BOOL)start;
- (void)stop;
- (void)forceStop;

- (BOOL)isUploadInProgress;
- (BOOL)isDownloadInProgress;

@end
