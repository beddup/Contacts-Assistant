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
//notification
extern NSString *const ContactManagerDidFinishUpdatingCoreData;
//search
extern NSString *const AdvicedContactsKey;
extern NSString *const AdvicedTagsKey;
extern NSString *const SearchResultContactsKey;
//contact info key
extern NSString *const ContactInfoIndexKey;
extern NSString *const ContactInfoLabelKey;
extern NSString *const ContactInfoValueKey;
extern NSString *const ContactInfoTypeKey;

typedef enum : NSUInteger {
    ContactInfoTypePhone=1,
    ContactInfoTypeEmail,
} ContactInfoType;

@protocol ContactsManagerDelegate <NSObject>

@end

@class Relation;
@interface ContactsManager : NSObject

@property(weak,nonatomic)id<ContactsManagerDelegate>delegate;
@property(strong,nonatomic)NSMutableArray *arrangedAllContacts;

+(instancetype)sharedContactManager;

-(void)loadContacts;

-(NSDictionary *)searchContacts:(NSArray *)contacts keywords:(NSArray *)keywords ;

-(NSString *)companyAndDepartmentOfContact:(Contact *)contact;
-(NSArray *)phoneNumbersOfContact:(Contact *)contact;
-(NSArray *)emailsOfContact:(Contact *)contact;
-(BOOL)hasPhone:(Contact *)contact;
-(BOOL)hasEmail:(Contact *)contact;

-(UIImage *)thumbnailOfContact:(Contact *)contact;

-(NSComparisonResult)compareResult:(Contact *)contact1 contact2:(Contact *)contact2;
-(NSString *)firstLetter:(Contact *)contact;

+(NSArray *)localizedSystemContactLabels;
+(NSArray *)localizedSystemRelationLabel;


-(NSMutableArray *)arrangedContactsunderTag:(Tag *)tag;
-(NSMutableArray *)indexTitleOfContact:(NSMutableArray *)contacts;


//edit
-(BOOL)modifyContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact;
-(BOOL)addContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact;
-(BOOL)deleteContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact;

-(Contact *)createPerson:(NSDictionary *)personInfo;
-(void)removePerson:(Contact *)contact;

-(void)addRelation:(NSString *)relationName forContact:(Contact *)contact otherContacts:(NSArray *)contacts;
-(void)removeRelation:(Relation *)relation;




@end
