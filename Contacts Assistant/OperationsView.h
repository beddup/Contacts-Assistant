//
//  OperationsView.h
//  Contacts Assistant
//
//  Created by Amay on 7/15/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OperationsView;
@protocol OperationDelegate

-(void)operationViewCreatNewContact:(OperationsView *)view;
-(void)operationViewScanQRCode:(OperationsView *)view;
-(void)operationViewExchangeCard:(OperationsView *)view;
-(void)operationViewSendSMS:(OperationsView *)view;
-(void)operationViewSendEmail:(OperationsView *)view;

@end


@interface OperationsView : UIView

@property(weak,nonatomic)id<OperationDelegate>delegate;

@end
