
//
//  MBProgressHUD+ContactsAssistant.m
//  Contacts Assistant
//
//  Created by Amay on 9/19/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "MBProgressHUD+ContactsAssistant.h"
#import "defines.h"

@implementation MBProgressHUD (ContactsAssistant)
+(MBProgressHUD *)textHud:(NSString *)text view:(UIView *)view{
    MBProgressHUD * hud=[[MBProgressHUD alloc]initWithView:view];
    hud.removeFromSuperViewOnHide=YES;
    [view addSubview:hud];
    hud.labelText=text;
    return hud;
}
+(MBProgressHUD *)loadingContactHudMode:(MBProgressHUDMode)mode view:(UIView *)view{

    MBProgressHUD* hud=[[MBProgressHUD alloc]initWithView:view];
    hud.removeFromSuperViewOnHide=YES;
    [view addSubview:hud];
    hud.mode=mode;
    hud.color=[UIColor colorWithWhite:0.85 alpha:1];
    hud.labelText=@"加载中...";
    hud.labelColor=IconColor;
    return hud;
}

@end
