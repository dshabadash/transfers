//
//  UploadServlet.h
//  MongooseWrapper
//
//  Created by Fabio Rodella on 6/13/11.
//  Copyright 2011 Crocodella Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBServlet.h"

/**
 * Sample servlet which receives a file upload and saves it to the
 * Documents directory. WARNING: This is not a particularly robust 
 * implementation of the multipart form data standard. It should 
 * work only for cases where there is a single file element in 
 * the request.
 *
 * Changed on 04/15/2013 by: Viacheslav Savchenko vs.savchenko@readdle.com
 * It's probably fixed now. But in simplified way.
 * Just skip all Content-Disposition headers until found file header.
 * Get filename from filename field, and skip Content-type header.
 * TODO: Parse Content-type header to be able call proper method for import.
 */
@interface PBUploadServlet : PBServlet

@end
