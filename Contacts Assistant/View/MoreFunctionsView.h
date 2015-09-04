//
//  ActionsView.h
//  Contacts Assistant
//
//  Created by Amay on 7/22/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MoreFunctionsView;
@protocol ActionsViewDelegate <NSObject>

-(void)groupSMS;
-(void)groupEmail;
-(void)scanContactQR;
-(void)addContactManually;

@end
@interface MoreFunctionsView : UIView

@property(weak,nonatomic)id <ActionsViewDelegate>delegate;

@end
