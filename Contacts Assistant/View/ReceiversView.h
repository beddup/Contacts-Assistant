//
//  ReceiversView.h
//  Contacts Assistant
//
//  Created by Amay on 9/1/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Contact;

extern NSString * const ReceiversContactKey;
extern NSString * const ReceiversContactInfosKey;

@interface ReceiversView : UIView
//abstract;
@property(copy)void (^cancelHandler)();
@property(copy)void (^sendHandler)(NSArray *phoneNumbersOrEmails);
@property(nonatomic)BOOL hasContactInfo;

-(void)addContactInfosToReceivers:(NSArray *)contactInfos contact:(Contact *)contact;
-(void)removeContactInfosOfContact:(Contact *)contact;
-(void)removeAllContactInfos;

-(NSString *)contactInfosStringOfReceivers:(NSArray *)receivers;
-(NSArray *)phoneNumbersOrEmailOfReceivers:(NSArray *)receivers;
@end
