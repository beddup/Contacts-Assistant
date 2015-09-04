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
#import "Event+Utility.h"
#import "Tag+Utility.h"

@implementation Contact (Utility)
+(NSManagedObjectContext *)context{
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;

}

+(NSArray *)allContacts{
    // prepare core data
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    [fetchRequest setFetchBatchSize:20];
    NSPredicate *predicate=[NSPredicate predicateWithFormat:@"contactIsDeleted.boolValue == %d",NO];
    fetchRequest.predicate=predicate;
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[Contact context] executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
}

+(Contact *)createContactWithName:(NSString *)name contactID:(u_int32_t)contactID{
    Contact *contact=[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:[Contact context]];
    contact.contactID=@(contactID);
    contact.contactName=name;
    contact.contactIsDeleted=@(NO);
    [[Tag rootTag] addOwnedContactsObject:contact];
    return contact;
}


+(void)deleteContactsWhoseIDNotIn:(NSSet *)contactIDs{
    
    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    fetchRequest.predicate=[NSPredicate predicateWithFormat:@"NOT contactID IN %@",contactIDs];
    NSArray *contacts=[[Contact context] executeFetchRequest:fetchRequest error:NULL];
    for (Contact *contact in contacts) {
        [[Contact context] deleteObject:contact];
    }
}

+(Contact *)contactOfContactID:(int)contactID{

    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    fetchRequest.predicate=[NSPredicate predicateWithFormat:@"contactID.intValue == %d",contactID];
    NSArray *contacts=[[Contact context] executeFetchRequest:fetchRequest error:NULL];
    return  [contacts firstObject];

}

-(NSString *)companyAndDepartment{
    return [[ContactsManager sharedContactManager] companyAndDepartmentOfContact:self];
}

+(NSString *)QRStringOfContact:(Contact *)contact{
    NSDictionary *info=@{@"N":contact.contactName, // name
                         @"P":[[ContactsManager sharedContactManager]phoneNumbersOfContact:contact], // phones
                         @"E":[[ContactsManager sharedContactManager]emailsOfContact:contact]};
    NSData *data= [NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:NULL];
    NSString *string=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    return string;
}
+(NSDictionary *)infoFromQRString:(NSString *)qrstring{
    NSData *data=[qrstring dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *info=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
    return info;
}

-(Event *)mostRecentEvent{

    Event *mostRecentEvent=[self.attendWhichEvents anyObject];
    for (Event *event in self.attendWhichEvents) {
        if ([[event nextdate] compare:[mostRecentEvent nextdate]] == NSOrderedDescending) {
            mostRecentEvent=event;
        }
    }
    return mostRecentEvent;
}

#pragma mark - contactInfo string
-(NSString *)phoneInfoString{
    NSArray *phones=[[ContactsManager sharedContactManager] phoneNumbersOfContact:self];
    return  [self stringOfContactInfos:phones];
}
-(NSString *)emailInfoString{
    NSArray *emails=[[ContactsManager sharedContactManager] emailsOfContact:self];
    return  [self stringOfContactInfos:emails];
}
-(NSString *)stringOfContactInfos:(NSArray *)contactInfos{
    NSString *contactInfosString=@"";
    for (NSDictionary *contactInfo in contactInfos) {
        contactInfosString=[contactInfosString stringByAppendingString:[NSString stringWithFormat:@"%@:%@,",contactInfo[ContactInfoLabelKey],contactInfo[ContactInfoValueKey]]];
    }
    if (contactInfosString.length) {
        contactInfosString=[contactInfosString substringToIndex:contactInfosString.length-1];
        contactInfosString=[contactInfosString stringByAppendingString:@";"];
    }
    return contactInfosString;
}

-(BOOL)hasPhone{
 return    [[ContactsManager sharedContactManager] hasPhone:self];
}
-(BOOL)hasEmail{
  return   [[ContactsManager sharedContactManager] hasEmail:self];
}













@end
