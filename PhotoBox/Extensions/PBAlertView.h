//
//  PBAlertView.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 19/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

void PBAlertOKWithCompletion(NSString *title, NSString *text, dispatch_block_t completionHandler);
void PBAlertOK(NSString *title, NSString *text);

CGFloat RDKeyboardHeightFromNotification(NSNotification *notification);


typedef void (^PBAlertCompletionBlock)(void);

@interface PBAlert : UIAlertView <UIAlertViewDelegate> {
    id  _target;
	NSArray *_selectorsArray;
    SEL _okSelector;
	SEL _cancelSelector;
	id userInfo;
    
    PBAlertCompletionBlock _yesBlock;
    PBAlertCompletionBlock _noBlock;
}
@property (nonatomic, copy) PBAlertCompletionBlock yesBlock;
@property (nonatomic, copy) PBAlertCompletionBlock noBlock;

@property (nonatomic, assign) id target;
@property (nonatomic, retain) id userInfo;

- (id)initWithTitle:(NSString *)_title
			message:(NSString *)_text
			 target:(id)target
		titlesArray:(NSArray *)titles
	 selectorsArray:(NSArray *)selectors;

+ (PBAlert *)alertWithTitle:(NSString *)alertTitle
					message:(NSString *)alertText
				   delegate:(id)delegate
			  positiveTitle:(NSString *)positiveTitle
			  negativeTitle:(NSString *)negativeTitle
			 positiveAction:(SEL)okSelector
			 negativeAction:(SEL)cancelSelector;

+ (PBAlert *)alertWithTitle:(NSString *)_title
					message:(NSString *)_text
				   delegate:(id)_delegate
				   okAction:(SEL)_okSelector
			   cancelAction:(SEL)_cancelSelector;

+ (PBAlert *)alertWithTitle:(NSString *)_title
					message:(NSString *)_text
				   delegate:(id)_delegate
				  yesAction:(SEL)_yesSelector
				   noAction:(SEL)_noSelector;

+ (PBAlert *)alertWithTitle:(NSString *)alertTitle
                    message:(NSString *)alertText
                    okBlock:(PBAlertCompletionBlock)okBlock;

+ (PBAlert *)alertWithTitle:(NSString *)alertTitle
                    message:(NSString *)alertText
                   yesBlock:(PBAlertCompletionBlock)yesBlock
                    noBlock:(PBAlertCompletionBlock)noBlock;

+ (PBAlert *)alertWithTitle:(NSString*)alertTitle
                    message:(NSString*)alertText
              positiveTitle:(NSString*)positiveTitle
			  negativeTitle:(NSString*)negativeTitle
                   yesBlock:(PBAlertCompletionBlock)yesBlock
                    noBlock:(PBAlertCompletionBlock)noBlock;

+ (PBAlert *)alertWithSecureTextInputAndTitle:(NSString*)title
                                         text:(NSString*)text
                            cancelButtonTitle:(NSString*)cancelButtonTitle
                                      handler:(PBAlertCompletionBlock)cancelHandler
                              doneButtonTitle:(NSString*)doneButtonTitle
                                      handler:(void (^)(NSString*))doneHandler;

+ (PBAlert*)alertWithLoginPasswordInputAndTitle:(NSString*)title
                                           text:(NSString*)text
                              cancelButtonTitle:(NSString*)cancelButtonTitle
                                        handler:(PBAlertCompletionBlock)cancelHandler
                                doneButtonTitle:(NSString*)doneButtonTitle
                                        handler:(void (^)(NSString*, NSString*))doneHandler;

@end
