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

//search result key
extern NSString *const AdvicedContactsKey;
extern NSString *const AdvicedTagsKey;
extern NSString *const SearchResultContactsKey;

//contact info key
extern NSString *const ContactInfoIndexKey;
extern NSString *const ContactInfoLabelKey;
extern NSString *const ContactInfoValueKey;
extern NSString *const ContactInfoTypeKey;

//Person Info key
extern NSString *const PersonInfoNameKey;
extern NSString *const PersonInfoContactInfoKey;
extern NSString *const PersonInfoCompanyKey;
extern NSString *const PersonInfoDepartmentKey;
extern NSString *const PersonInfoJobTitleKey;


typedef enum : NSUInteger {
    ContactInfoTypeUnkown,
    ContactInfoTypePhone,
    ContactInfoTypeEmail,
} ContactInfoType;


@protocol LoadContactsDelegate <NSObject>

-(void)loadingContact:(NSInteger)index total:(NSInteger)total;
-(void)didFinishLoadContacts;
-(void)didCreateNewPerson;

@end

@class Relation;
@interface ContactsManager : NSObject

@property(weak,nonatomic)id<LoadContactsDelegate>delegate;
@property(nonatomic)BOOL addressBookAuthorized;


+(instancetype)sharedContactManager;
-(void)loadContacts;

//search
-(NSDictionary *)searchContacts:(NSArray *)contacts keywords:(NSArray *)keywords ;

//person info
-(NSString *)companyAndDepartmentOfContact:(Contact *)contact;
-(BOOL)hasPhone:(Contact *)contact;
-(BOOL)hasEmail:(Contact *)contact;
-(NSInteger)phoneCountOfContact:(Contact *)contact;
-(NSInteger)emailCountOfContact:(Contact *)contact;
-(NSArray *)phoneNumbersOfContact:(Contact *)contact;
-(NSArray *)emailsOfContact:(Contact *)contact;
-(UIImage *)thumbnailOfContact:(Contact *)contact;


-(Contact *)createPerson:(NSDictionary *)personInfo;
-(void)removePerson:(Contact *)contact;


// rearrange contacts(section&row)
-(NSArray *)arrangedAllContacts;
-(NSArray *)arrangedContactsunderTag:(Tag *)tag;
-(NSArray *)indexTitleOfContacts:(NSArray *)contacts;
-(NSComparisonResult)compareResult:(Contact *)contact1 contact2:(Contact *)contact2;
-(void)arrangeContactToTop:(Contact *)contact indexTitle:(NSString *)title;

//edit contact info
-(BOOL)modifyContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact;
-(BOOL)addContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact;
-(BOOL)deleteContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact;

@end
