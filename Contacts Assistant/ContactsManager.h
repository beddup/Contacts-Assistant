//
//  ContactsManager.h
//  Contacts Assistant
//
//  Created by Amay on 7/15/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Contact,Tag;
extern NSString *const AdvicedContactsKey;
extern NSString *const AdvicedTagsKey;
extern NSString *const SearchResultContactsKey;

extern NSString *const ContactManagerDidFinishUpdatingCoreData;

extern NSString *const PhoneLabel;
extern NSString *const PhoneNumber;

extern NSString *const EmailLabel;
extern NSString *const EmailValue;

extern NSString * const CommunicationPhones;  //nsarray
extern NSString * const CommunicationEmails;  // nsarray


@protocol ContactsManagerDelegate <NSObject>

@end


@interface ContactsManager : NSObject

@property(weak,nonatomic)id<ContactsManagerDelegate>delegate;

+(instancetype)sharedContactManager;

-(void)updateCoreDataBasedOnContacts;

-(NSDictionary *)searchContacts:(NSArray *)contacts keywords:(NSArray *)keywords ;

-(NSString *)companyAndDepartmentOfContact:(Contact *)contact;
-(NSArray *)phoneNumbersOfContact:(Contact *)contact;
-(NSArray *)emailsOfContact:(Contact *)contact;

-(NSArray *)filterContactsWithoutPhoneNumbers:(NSArray *)contacts;
-(NSArray *)filterContactsWithoutemail:(NSArray *)contacts;

-(void)addContactLabel:(NSString *)label value:(NSString *)phoneOrEmail isPhoneNumber:(BOOL)isPhoneNumber;

-(NSComparisonResult)compareResult:(Contact *)contact1 contact2:(Contact *)contact2;
-(NSString *)firstLetter:(Contact *)contact;

+(NSArray *)localizedSystemContactLabels;
+(NSArray *)localizedSystemRelationLabel;

@end
