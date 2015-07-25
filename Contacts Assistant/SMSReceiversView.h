//
//  SMSReceiversView.h
//  Contacts Assistant
//
//  Created by Amay on 7/24/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMSReceiversView : UIView

@property(copy)void (^cancelSMSHandler)();

-(void)addContactAtIndex:(NSInteger)index withName:(NSString *)name andPhoneNumbers:(NSArray *)numbers;
-(void)removeContactAtIndex:(NSInteger)index;


@end
