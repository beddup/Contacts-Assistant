//
//  UIViewController+SendSMSOrEmail.h
//  Contacts Assistant
//
//  Created by Amay on 10/9/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface UIViewController (SendSMSOrEmail) <MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>
-(void)SMSTo:(NSArray *)phones;

-(void)emailTo:(NSArray *)to cc:(NSArray *)cc bcc:(NSArray *)bcc;

@end
