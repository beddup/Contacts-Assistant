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
extern NSString *const FetchResultContactsKey;
extern NSString *const FetchResultTagsKey;
extern NSString *const ContactManagerDidFinishUpdatingCoreData;
@protocol ContactsManagerDelegate <NSObject>
-(void)addNewContactUnderTag:(Tag *)tag;
@end


@interface ContactsManager : NSObject<UITableViewDataSource,UITableViewDelegate>

@property(weak,nonatomic)id<ContactsManagerDelegate>delegate;

+(instancetype)sharedContactManager;

-(void)updateCoreDataBasedOnContacts;

-(NSDictionary *)searchResultByKeyword:(NSString *)string;

-(UIImage *)thumbnailOfContact:(Contact *)contact;
-(NSString *)companyAndDepartmentOfContact:(Contact *)contact;
-(NSArray *)phoneNumbersOfContact:(Contact *)contact;
-(NSArray *)emailsOfContact:(Contact *)contact;
-(NSArray *)addressesOfContact:(Contact *)contact;

@end
