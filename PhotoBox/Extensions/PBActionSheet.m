//
//  PBActionSheet.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 08/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBActionSheet.h"

static NSMutableArray *allRDActionSheets = nil;

@implementation PBActionSheet
@synthesize userInfo;

- (id)initWithTitle:(NSString *)title delegate:(id<UIActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	NSAssert(NO, @"call -initWithTitle:delegate: not this method");
	return nil;
}

- (id)initWithTitle:(NSString *)title delegate:(NSObject<PBActionSheetDelegate> *)delegate
{
	self = [super initWithTitle:title
					   delegate:self
			  cancelButtonTitle:nil
		 destructiveButtonTitle:nil
			  otherButtonTitles:nil];
    
	if (self != nil) {
		selectorsArray = [NSMutableArray new];
		pbActionSheetDelegate = delegate;
	}
	return self;
}

- (void) dealloc {
	[userInfo release];
	[selectorsArray release];
	[super dealloc];
}

- (NSInteger)addButtonWithTitle:(NSString *)title {
	NSAssert(NO, @"do not call addButtonWithTitle for RDActionSheet");
	return -1;
}

- (void)addButtonWithTitle:(NSString *)title action:(SEL)action {
	[super addButtonWithTitle:title];
	if (action == nil)
		[selectorsArray addObject:[NSNull null]];
	else
		[selectorsArray addObject:NSStringFromSelector(action)];
    
	self.cancelButtonIndex = [selectorsArray count] - 1;
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
	if ([pbActionSheetDelegate respondsToSelector:@selector(willShowPBActionSheet:)])
		[pbActionSheetDelegate willShowPBActionSheet:self];
    
	if (allRDActionSheets == nil) {
		allRDActionSheets = [NSMutableArray new];
	}
	[allRDActionSheets addObject:self];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ([pbActionSheetDelegate respondsToSelector:@selector(willHidePBActionSheet:)])
		[pbActionSheetDelegate willHidePBActionSheet:self];
    
	if (allRDActionSheets) {
		[allRDActionSheets removeObject:self];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSObject *obj = [selectorsArray objectAtIndex:buttonIndex];
	if ([obj isKindOfClass:[NSNull class]])
		return;
    
	SEL s = NSSelectorFromString((NSString *)obj);
    [pbActionSheetDelegate performSelector:s
                                withObject:userInfo
                                afterDelay:0.01];
}

+ (void)cancelAllActionSheets {
	if (allRDActionSheets) {
		for (PBActionSheet *as in allRDActionSheets) {
			[as dismissWithClickedButtonIndex:0 animated:NO];
		}
	}
}

@end
