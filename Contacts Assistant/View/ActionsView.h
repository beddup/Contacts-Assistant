//
//  ActionsView.h
//  Contacts Assistant
//
//  Created by Amay on 7/22/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {

    ActionViewButtonMoreFunctionSMS =281,
    ActionViewButtonMoreFunctionEmail,
    ActionViewButtonMoreFunctionScanQR,
    ActionViewButtonMoreFunctionManuallyAdd,
    ActionViewButtonMoreFunctionShareContacts,
    
} ActionViewButton;
@class ActionsView;
@protocol ActionsViewDelegate <NSObject>

-(void)actionView:(ActionsView *)actionView actionButtonTapped:(NSInteger)buttonTag;  // the most left button tag is 81, and its nearest right button is 82, and so on

@end
@interface ActionsView : UIView

@property(weak,nonatomic)id <ActionsViewDelegate>delegate;

@end
