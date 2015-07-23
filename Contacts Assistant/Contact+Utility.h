//
//  Contact+Utility.h
//  Contacts Assistant
//
//  Created by Amay on 7/23/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "Contact.h"
#import <UIKit/UIKit.h>

extern NSString * const CommunicationPhones;  //nsarray
extern NSString * const CommunicationEmails;  // nsarray

@interface Contact (Utility)

-(NSDictionary *)avaibleCommunications;

-(UIImage *)photoImage;

-(NSString *)companyAndDepartment;


@end
