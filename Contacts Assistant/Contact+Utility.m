//
//  Contact+Utility.m
//  Contacts Assistant
//
//  Created by Amay on 7/23/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "Contact+Utility.h"
#import "ContactsManager.h"

 NSString * const CommunicationPhones=@"CommunicationPhones";
 NSString * const CommunicationEmails=@"CommunicationEmails";

@implementation Contact (Utility)

#pragma mark - public api
-(NSDictionary *)avaibleCommunications{

    NSMutableDictionary *dic=[@{} mutableCopy];
    NSArray *phoneNumber=[[ContactsManager sharedContactManager] phoneNumbersOfContact:self];
    NSArray *eMails=[[ContactsManager sharedContactManager] emailsOfContact:self];
    if (phoneNumber.count) {
        [dic setObject:phoneNumber forKey:CommunicationPhones];
    }
    if (eMails.count) {
        [dic setObject:eMails forKey:CommunicationEmails];
    }
    
    NSLog(@"self:%@,avaibleCommunications:%@",self.contactName, dic);

    return dic;
}

-(UIImage *)photoImage{
    return [[ContactsManager sharedContactManager] thumbnailOfContact:self];

}

-(NSString *)companyAndDepartment{
    return [[ContactsManager sharedContactManager] companyAndDepartmentOfContact:self];
}

@end
