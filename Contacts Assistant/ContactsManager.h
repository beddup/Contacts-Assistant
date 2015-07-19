//
//  ContactsManager.h
//  Contacts Assistant
//
//  Created by Amay on 7/15/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactNetView.h"
@class Contact,Tag;
extern NSString *const FetchResultContactsKey;
extern NSString *const FetchResultTagsKey;
extern NSString *const ContactManagerDidFinishUpdatingCoreData;
@interface ContactsManager : NSObject<ContactNetViewDataSource,ContactNetViewDelegate>

-(void)updateCoreDataBasedOnContacts;

-(NSDictionary *)searchResultByKeyword:(NSString *)string;

@end
