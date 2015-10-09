//
//  UIViewController+SendSMSOrEmail.m
//  Contacts Assistant
//
//  Created by Amay on 10/9/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "UIViewController+SendSMSOrEmail.h"
#import "MBProgressHUD+ContactsAssistant.h"
#import "UIViewController+SendSMSOrEmail.h"
#import "defines.h"
#import "AppDelegate.h"

@implementation UIViewController (SendSMSOrEmail)
-(void)SMSTo:(NSArray *)phones{
    MBProgressHUD *hud=[MBProgressHUD textHud:@"跳转中" view:self.view];
    [hud show:YES];
    APP.globalMessageComposer.recipients=phones;
    APP.globalMessageComposer.messageComposeDelegate=self;
    [self presentViewController:APP.globalMessageComposer animated:YES completion:^{
        [hud hide:YES];
    }];
}
-(void)emailTo:(NSArray *)to cc:(NSArray *)cc bcc:(NSArray *)bcc{

    MBProgressHUD *hud=[MBProgressHUD textHud:@"跳转中" view:self.view];
    [hud show:YES];
    APP.globalMailComposer.mailComposeDelegate=self;

    if (to.count) {
        [APP.globalMailComposer setToRecipients:to];
    }
    if (cc.count) {
        [APP.globalMailComposer setCcRecipients:cc];
    }
    if (bcc.count) {
        [APP.globalMailComposer setBccRecipients:bcc];
    }

    [self presentViewController:APP.globalMailComposer animated:YES completion:^{
        [hud hide:YES];
    }];
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [APP cycleTheGlobalMailComposer];
    }];
}
#pragma mark -MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{

    [controller.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [APP cycleTheGlobalMessageComposer];
    }];
}


@end
