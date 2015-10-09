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
#import "Relation.h"

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
    [((AppDelegate *)[UIApplication sharedApplication].delegate) saveContext];
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
    
    NSArray *phones=[[ContactsManager sharedContactManager]phoneNumbersOfContact:contact];// phones
    NSArray *emails=[[ContactsManager sharedContactManager]emailsOfContact:contact];//emails
    NSDictionary *info=@{PersonInfoNameKey:contact.contactName, // name
                         PersonInfoContactInfoKey:[phones arrayByAddingObjectsFromArray:emails]};

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
    NSArray *unfinishedEvent=[self unfinishedOwnedEvents];
    if (!unfinishedEvent.count) {
        return nil;
    }
    NSTimeInterval theInterval=0;
    Event *theEvent=nil;
    for (Event *event in unfinishedEvent) {
        NSDate *nextDate=[event nextEventDate];
        NSTimeInterval nextDateInterval=[nextDate timeIntervalSinceNow];
        BOOL flag=NO;
        if (!nextDate) {
            // no date;
            return event;
        }else if (theInterval == 0) {
            theEvent=event;
        }else if ( theInterval > 0 && nextDateInterval>0 && nextDateInterval<theInterval ) {
            // both coming date
            flag=YES;
        }else if (theInterval <0 && nextDateInterval<0 && nextDateInterval>theInterval ) {
            // both passed date
            flag=YES;
        }else if (theInterval<0 && nextDateInterval >0) {
            // coming date vs passed date
            flag=YES;
        }
        if (flag) {
            theEvent=event;
            theInterval=nextDateInterval;
        }
    }

    return theEvent;
}

-(NSArray *)unfinishedOwnedEvents{
    return [[self.ownedEvents allObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"finished.boolValue==%d",NO]];
}
-(NSArray *)finishedOwnedEvents{
    return [[self.ownedEvents allObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"finished.boolValue==%d",YES]];
}
-(BOOL)hasUnfinishedOwnedEvents{
    for (Event *event in self.ownedEvents) {
        if (event.finished.boolValue == NO) {
            return YES;
        }
    }
    return NO;
}

-(NSMutableArray *)sortedUnfinishedOwnedEvents{
    // first no date event ,then coming event,then passed event
    NSMutableArray *nodateEvent=[@[] mutableCopy];
    NSMutableArray *comingAndNoDateEvent=[@[] mutableCopy];
    NSMutableArray *passedEvent=[@[] mutableCopy];
    for (Event *event in [self unfinishedOwnedEvents]) {
        if (![event nextEventDate]) {
            // no date event
            [nodateEvent addObject:event];
        }
        if ([[event nextEventDate] timeIntervalSinceNow] > 0){
            //coming event
            [comingAndNoDateEvent addObject:event];
        }else if ( [[event nextEventDate] timeIntervalSinceNow] < 0){
            //passedEvent
            [passedEvent addObject: event];
        }
    }

    //sort
    [nodateEvent sortUsingComparator:^NSComparisonResult(Event * obj1, Event * obj2) {
        return [obj1.eventDescription compare:obj2.eventDescription];
    }];
    [comingAndNoDateEvent sortUsingComparator:^NSComparisonResult(Event * obj1, Event * obj2) {
       return  [[obj1 nextEventDate] compare:[obj2 nextEventDate]];
    }];
    [passedEvent sortUsingComparator:^NSComparisonResult(Event * obj1, Event * obj2) {
        return  [[obj2 nextEventDate] compare:[obj1 nextEventDate]];
    }];

    [nodateEvent addObjectsFromArray:comingAndNoDateEvent];
    [nodateEvent addObjectsFromArray:passedEvent];
    return nodateEvent;

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
    }
    return contactInfosString;
}

-(BOOL)hasPhone{
 return    [[ContactsManager sharedContactManager] hasPhone:self];
}
-(BOOL)hasEmail{
  return   [[ContactsManager sharedContactManager] hasEmail:self];
}

-(void)addRelation:(NSString *)relationName  WithContacts:(NSArray *)contacts{

    for (Contact *otherContact in contacts) {
        // update core data
        Relation *relation=[NSEntityDescription insertNewObjectForEntityForName:@"Relation" inManagedObjectContext:self.managedObjectContext];
        relation.relationName=relationName;
        relation.whoseRelation=self;
        relation.otherContact=otherContact;
    }

}












@end
