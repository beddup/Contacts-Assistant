//
//  Contact+Utility.h
//  Contacts Assistant
//
//  Created by Amay on 7/23/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "Contact.h"
#import <UIKit/UIKit.h>


@interface Contact (Utility)

+(NSArray *)allContacts;

+(Contact *)contactOfContactID:(int)contactID;
+(void)deleteContactsWhoseIDNotIn:(NSSet *)contactIDs;
+(Contact *)createContactWithName:(NSString *)name contactID:(u_int32_t)contactID;
-(NSString *)companyAndDepartment;

+(NSString *)QRStringOfContact:(Contact *)contact; //including name  + contactinfo
+(NSDictionary *)infoFromQRString:(NSString *)qrstring;
-(Event *)mostRecentEvent;

-(NSMutableArray *)sortedUnfinishedOwnedEvents;
-(BOOL)hasUnfinishedOwnedEvents;
-(NSArray *)unfinishedOwnedEvents;
-(NSArray *)finishedOwnedEvents;


-(NSString *)phoneInfoString;
-(NSString *)emailInfoString;

-(BOOL)hasPhone;
-(BOOL)hasEmail;

-(void)addRelation:(NSString *)relationName WithContacts:(NSArray *)contacts;


@end
