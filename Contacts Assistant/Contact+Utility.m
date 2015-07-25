//
//  Contact+Utility.m
//  Contacts Assistant
//
//  Created by Amay on 7/23/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "Contact+Utility.h"
#import "ContactsManager.h"
#import "AppDelegate.h"
 NSString * const CommunicationPhones=@"CommunicationPhones";
 NSString * const CommunicationEmails=@"CommunicationEmails";

@implementation Contact (Utility)
+(NSManagedObjectContext *)context{
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;

}
+(NSArray *)allContacts{
    // prepare core data
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    [fetchRequest setFetchBatchSize:20];
    NSError *error = nil;
    NSArray *fetchedObjects = [[Contact context] executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"fetchedObjects nil");
    }
    NSLog(@"fetchedObjects:%@",fetchedObjects);
    return fetchedObjects;
}

+(NSArray*)contactsWhoseNameContains:(NSString *)keyword{

    NSFetchRequest *contactFectchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    contactFectchRequest.predicate=[NSPredicate predicateWithFormat:@"contactName CONTAINS %@",keyword];
    NSArray * advicedContacts=[[Contact context] executeFetchRequest:contactFectchRequest error:NULL];
    return advicedContacts;
}


+(NSArray *)contactsOfContactIDs:(NSArray *)contactIDs{

    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    fetchRequest.predicate=[NSPredicate predicateWithFormat:@"contactID IN %@",contactIDs];
    NSArray *contacts=[[Contact context] executeFetchRequest:fetchRequest error:NULL];
    
    return  [contacts firstObject];
    
}
+(Contact *)contactOfContactID:(int)contactID{

    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    fetchRequest.predicate=[NSPredicate predicateWithFormat:@"contactID == %@",@(contactID)];
    NSArray *contacts=[[Contact context] executeFetchRequest:fetchRequest error:NULL];
    return  [contacts firstObject];

}


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

-(NSString *)companyAndDepartment{
    return [[ContactsManager sharedContactManager] companyAndDepartmentOfContact:self];
}

@end
