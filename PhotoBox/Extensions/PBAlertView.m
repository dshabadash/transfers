//
//  PBAlertView.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 19/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBAlertView.h"

@interface PBAlertOKCompletion : UIAlertView<UIAlertViewDelegate> {
@private
    dispatch_block_t completionHandler;
}
@end

@implementation PBAlertOKCompletion

- (id)initWithTitle:(NSString *)title message:(NSString *)message button:(NSString *)button completionHandler:(dispatch_block_t)completion {
    self = [super initWithTitle:title
                        message:message
                       delegate:completion?self:nil
              cancelButtonTitle:button
              otherButtonTitles:nil];
    if (self) {
        if (completion)
            completionHandler = Block_copy(completion);
    }
    return self;
}

- (void)dealloc {
    if(completionHandler)
        Block_release(completionHandler);
    [super dealloc];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (completionHandler)
        completionHandler();
}
@end


void PBAlertOKWithCompletion(NSString *title, NSString *text, dispatch_block_t completionHandler) {
    PBAlertOKCompletion *alert = [[PBAlertOKCompletion alloc] initWithTitle:title
                                                                    message:text
                                                                     button:@"OK"
                                                          completionHandler:completionHandler];
    [alert show];
    [alert release];
}


void PBAlertOK(NSString *title, NSString *text) {
    PBAlertOKWithCompletion(title, text, nil);
}

CGFloat RDKeyboardHeightFromNotification(NSNotification *notification) {
	CGRect keyboardFrame = CGRectZero;
    
    if (UIKeyboardFrameEndUserInfoKey!=nil) {
        // Constant exists, we're >=3.2
        [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            return keyboardFrame.size.height;
        }
        else {
            return keyboardFrame.size.width;
        }
    } else {
        // Constant has no value. We're <3.2
        [[notification.userInfo valueForKey:@"UIKeyboardBoundsUserInfoKey"] getValue: &keyboardFrame];
        return keyboardFrame.size.height;
    }
    
	return 0;
}

UIView* RDSuperViewOfClassForView(Class cls, UIView* view) {
    UIView* currentView = view.superview;
    
    while (currentView != nil && ![currentView isKindOfClass:cls]) {
        currentView = currentView.superview;
    }
    return currentView;
}

@implementation PBAlert
@synthesize userInfo;

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (_selectorsArray) {
		if (buttonIndex > [_selectorsArray count] - 1)
			return;
        
		NSString *sname = [_selectorsArray objectAtIndex:buttonIndex];
		if ([sname hasContent] == NO)
			return;
        
		SEL sel = NSSelectorFromString(sname);
		if ([_target respondsToSelector:sel])
			[_target performSelectorLater:sel withObject:userInfo];
        
		return;
	}
    if (buttonIndex > 0) {
        if (_okSelector)
			[_target performSelectorLater:_okSelector withObject:userInfo];
	}
	else {
		if (_cancelSelector)
			[_target performSelectorLater:_cancelSelector withObject:userInfo];
	}
}

- (id)initWithTitle:(NSString *)_title
			message:(NSString *)_text
			 target:(id)target
		titlesArray:(NSArray *)titles
	 selectorsArray:(NSArray *)selectors
{
    if ((self = [super initWithTitle:_title
                             message:_text
                            delegate:self
                   cancelButtonTitle:nil
                   otherButtonTitles:nil])) {
        
        _target = target;
		for(NSString *buttonTitle in titles) {
			[self addButtonWithTitle:buttonTitle];
		}
		_selectorsArray = [selectors retain];
	}
	return self;
    
}

- (void) dealloc {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    [_yesBlock release];
    [_noBlock release];
#endif
	[userInfo release];
	[_selectorsArray release];
	[super dealloc];
}


- (id)initWithTitle:(NSString *)_title
			message:(NSString *)_text
		   delegate:(id)delegate
	  positiveTitle:(NSString *)positiveTitle
	  negativeTitle:(NSString *)negativeTitle
	 positiveAction:(SEL)okSelector
	 negativeAction:(SEL)cancelSelector

{
    if ((self = [super initWithTitle:_title
                             message:_text
                            delegate:self
                   cancelButtonTitle:negativeTitle
                   otherButtonTitles:positiveTitle, nil])) {
        
        _target = delegate;
        _okSelector = okSelector;
		_cancelSelector = cancelSelector;
    }
    
    return self;
}

+ (PBAlert *)alertWithTitle:(NSString *)alertTitle
					message:(NSString *)alertText
				   delegate:(id)delegate
			  positiveTitle:(NSString *)positiveTitle
			  negativeTitle:(NSString *)negativeTitle
			 positiveAction:(SEL)okSelector
			 negativeAction:(SEL)cancelSelector
{
    
	PBAlert *alert = [[PBAlert alloc] initWithTitle:alertTitle
											message:alertText
										   delegate:delegate
									  positiveTitle:positiveTitle
									  negativeTitle:negativeTitle
									 positiveAction:okSelector
									 negativeAction:cancelSelector];
    [alert show];
    [alert release];
	return alert;
}


+ (PBAlert *)alertWithTitle:(NSString *)alertTitle
					message:(NSString *)alertText
				   delegate:(id)delegate
				   okAction:(SEL)_okSelector
			   cancelAction:(SEL)_cancelSelector
{
	return [PBAlert alertWithTitle:alertTitle
						   message:alertText
						  delegate:delegate
					 positiveTitle:NSLocalizedString(@"OK", @"button")
					 negativeTitle:NSLocalizedString(@"Cancel", @"button")
					positiveAction:_okSelector
					negativeAction:_cancelSelector];
}

+ (PBAlert *)alertWithTitle:(NSString *)alertTitle
					message:(NSString *)alertText
				   delegate:(id)delegate
				  yesAction:(SEL)_yesSelector
				   noAction:(SEL)_noSelector
{
	return [PBAlert alertWithTitle:alertTitle
						   message:alertText
						  delegate:delegate
					 positiveTitle:NSLocalizedString(@"Yes", @"button")
					 negativeTitle:NSLocalizedString(@"No", @"button")
					positiveAction:_yesSelector
					negativeAction:_noSelector];
}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
+ (PBAlert *)alertWithTitle:(NSString*)alertTitle
                    message:(NSString*)alertText
                    okBlock:(PBAlertCompletionBlock)okBlock {
    return [PBAlert alertWithTitle:alertTitle
                           message:alertText
                     positiveTitle:nil
                     negativeTitle:NSLocalizedString(@"OK", @"OK")
                          yesBlock:nil
                           noBlock:okBlock];
}

+ (PBAlert *)alertWithTitle:(NSString *)alertTitle
                    message:(NSString *)alertText
                   yesBlock:(PBAlertCompletionBlock)yesBlock
                    noBlock:(PBAlertCompletionBlock)noBlock {
    return [PBAlert alertWithTitle:alertTitle
                           message:alertText
                     positiveTitle:NSLocalizedString(@"Yes", @"button")
                     negativeTitle:NSLocalizedString(@"No", @"button")
                          yesBlock:yesBlock
                           noBlock:noBlock];
}

+ (PBAlert *)alertWithTitle:(NSString *)alertTitle
                    message:(NSString *)alertText
              positiveTitle:(NSString *)positiveTitle
			  negativeTitle:(NSString *)negativeTitle
                   yesBlock:(PBAlertCompletionBlock)yesBlock
                    noBlock:(PBAlertCompletionBlock)noBlock {
    PBAlert* alert = [PBAlert alertWithTitle:alertTitle
                                     message:alertText
                                    delegate:nil
                               positiveTitle:positiveTitle
                               negativeTitle:negativeTitle
                              positiveAction:@selector(yesSelected)
                              negativeAction:@selector(noSelected)];
    
    alert.target = alert;
    alert.yesBlock = yesBlock;
    alert.noBlock = noBlock;
    return alert;
}

+ (PBAlert*)alertWithSecureTextInputAndTitle:(NSString*)title
                                        text:(NSString*)text
                           cancelButtonTitle:(NSString*)cancelButtonTitle
                                     handler:(PBAlertCompletionBlock)cancelHandler
                             doneButtonTitle:(NSString*)doneButtonTitle
                                     handler:(void (^)(NSString*))doneHandler {
    PBAlert* alertView = nil;
    UITextField* textField = nil;
    
    alertView = [[PBAlert alloc] initWithTitle:title
                                       message:text
                                      delegate:nil
                                 positiveTitle:doneButtonTitle
                                 negativeTitle:cancelButtonTitle
                                positiveAction:@selector(yesSelected)
                                negativeAction:@selector(noSelected)];
    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    textField = [alertView textFieldAtIndex:0];
    textField.text = @"";
    textField.placeholder = NSLocalizedString(@"Password", @"Password");
    
    alertView.target = alertView;
    alertView.yesBlock = ^{ doneHandler(textField.text); };
    alertView.noBlock = cancelHandler;
    
    [alertView show];
    [alertView release];
    
    textField.frame = CGRectMake(15.0f, alertView.bounds.size.height - 98.0f, alertView.bounds.size.width - 30.0f, 30.0f);
    [alertView bringSubviewToFront:textField];
    
    return alertView;
}

+ (PBAlert*)alertWithLoginPasswordInputAndTitle:(NSString*)title
                                           text:(NSString*)text
                              cancelButtonTitle:(NSString*)cancelButtonTitle
                                        handler:(PBAlertCompletionBlock)cancelHandler
                                doneButtonTitle:(NSString*)doneButtonTitle
                                        handler:(void (^)(NSString*, NSString*))doneHandler {
    
    PBAlert* alertView = [[PBAlert alloc] initWithTitle:title
                                                message:text
                                               delegate:nil
                                          positiveTitle:doneButtonTitle
                                          negativeTitle:cancelButtonTitle
                                         positiveAction:@selector(yesSelected)
                                         negativeAction:@selector(noSelected)];
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    
    UITextField* loginTextField = [alertView textFieldAtIndex:0];
    UITextField* passwordTextField = [alertView textFieldAtIndex:1];
    
    alertView.target = alertView;
    alertView.yesBlock = ^{ doneHandler(loginTextField.text, passwordTextField.text); };
    alertView.noBlock = cancelHandler;
    
    [alertView show];
    [alertView release];
    
    [alertView bringSubviewToFront:loginTextField];
    
    return alertView;
}


- (void)yesSelected {
    if (_yesBlock) {
        _yesBlock();
    }
}

- (void)noSelected {
    if (_noBlock) {
        _noBlock();
    }
}

@synthesize yesBlock = _yesBlock;
@synthesize noBlock = _noBlock;
#endif
@synthesize target = _target;
@end

