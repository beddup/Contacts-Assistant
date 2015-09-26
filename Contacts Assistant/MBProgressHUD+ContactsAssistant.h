//
//  MBProgressHUD+ContactsAssistant.h
//  Contacts Assistant
//
//  Created by Amay on 9/19/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD (ContactsAssistant)
+(MBProgressHUD *)textHud:(NSString *)text view:(UIView *)view;
+(MBProgressHUD *)loadingContactHudMode:(MBProgressHUDMode)mode view:(UIView *)view;
@end
