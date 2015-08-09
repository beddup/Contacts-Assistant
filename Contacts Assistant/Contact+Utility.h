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
//+(NSArray *)contactsWhoseNameContains:(NSString *)keyword;
+(NSArray *)contactsOfContactIDs:(NSArray *)contactIDs;
+(Contact *)contactOfContactID:(int)contactID;


-(NSDictionary *)avaibleCommunications;

-(NSString *)companyAndDepartment;

+(NSString *)QRStringOfContact:(Contact *)contact; //including name  + contactinfo
+(NSDictionary *)infoFromQRString:(NSString *)qrstring;
-(Event *)recentEvent;
@end
