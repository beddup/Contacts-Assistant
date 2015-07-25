//
//  ContactsManager.m
//  Contacts Assistant
//
//  Created by Amay on 7/15/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ContactsManager.h"
#import "AppDelegate.h"
#import "Contact+Utility.h"
#import "Relation.h"
#import "Tag+Utility.h"
#import "HeaderView.h"
#import "TagCell.h"
#import "ContactCell.h"

#import <AddressBook/AddressBook.h>

#import <CoreData/CoreData.h>

NSString *const FetchResultContactsKey=@"Contacts";
NSString *const FetchResultTagsKey=@"Tags";
NSString *const ContactManagerDidFinishUpdatingCoreData=@"ContactManagerDidFinishUpdatingCoreData";

@interface ContactsManager()


@property(weak,nonatomic)NSManagedObjectContext *context;

@property(nonatomic,assign)ABAddressBookRef addressBook;
@property(strong,nonatomic)NSArray *peopleInAddressBook;

//for update tableview
@property(strong,nonatomic)Tag *currentTag;
@property(strong,nonatomic)NSMutableArray *contacts;
@property(strong,nonatomic)NSArray *cellHeightArray;



@end

@implementation ContactsManager

@synthesize contacts=_contacts;

#pragma mark - instanitiation
static ContactsManager * shareManager;
+(instancetype)sharedContactManager{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager=[[self alloc]init];
    });
    return shareManager;

}
+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager=[[super allocWithZone:zone]init];
    });
    return shareManager;

}
-(id)copy{
    return shareManager;
}

#pragma mark - UITableViewRowAction

#pragma mark - context
-(NSManagedObjectContext *)context{
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
}

-(void)saveContext{
    [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
}


#pragma mark - properties of contact

-(NSString *)nameOfPerson:(ABRecordRef)recordRef{

    NSString *firstName=(__bridge NSString *)ABRecordCopyValue(recordRef, kABPersonFirstNameProperty);
    NSString *lastName=(__bridge NSString *)ABRecordCopyValue(recordRef, kABPersonLastNameProperty);
    NSString *name=[lastName==nil ? @"" :lastName stringByAppendingString:firstName==nil ? @"" : firstName];

    return name;
}

-(UIImage *)thumbnailOfContact:(Contact *)contact{

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    NSData *data=(__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
    UIImage *image=[UIImage imageWithData:data];
    return image;

}

-(NSString *)companyAndDepartmentOfContact:(Contact *)contact{

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    NSString *companyName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonOrganizationProperty);
    NSString *departmentName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonDepartmentProperty);
    NSString *combinedString= [companyName ? companyName : @"" stringByAppendingString:departmentName ? departmentName : @""];
    return combinedString.length ? combinedString : nil;

}

-(NSArray *)phoneNumbersOfContact:(Contact *)contact{

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    ABMultiValueRef phones=ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFArrayRef phonesArrayRef=ABMultiValueCopyArrayOfAllValues(phones);
    NSMutableArray *phonesMA=[@[] mutableCopy];
    if (phonesArrayRef) {
        for (int i=0 ; i<CFArrayGetCount(phonesArrayRef); i++) {
            [phonesMA addObject:(__bridge NSString *)CFArrayGetValueAtIndex(phonesArrayRef, i)];
        }
    }

    return phonesMA.count ? phonesMA : nil;

}

-(NSArray *)emailsOfContact:(Contact *)contact{

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    ABMultiValueRef emails=ABRecordCopyValue(person, kABPersonEmailProperty);
    NSArray *emailsArray =(__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emails);

    return emailsArray.count ? emailsArray : nil;
    
}
-(NSArray *)filterContactsWithoutPhoneNumbers:(NSArray *)contacts{
    NSMutableArray *array=[contacts mutableCopy];
    NSMutableIndexSet *indexSet=[NSMutableIndexSet indexSet];
    for (int i=0; i <contacts.count; i++) {
        Contact *contact = contacts[i];
        if (![self phoneNumbersOfContact:contact] ) {
            [indexSet addIndex:i];
        }
    }
    [array removeObjectsAtIndexes:indexSet];
    return array;
}
-(NSArray *)filterContactsWithoutemail:(NSArray *)contacts{
    NSMutableArray *array=[contacts mutableCopy];
    NSMutableIndexSet *indexSet=[NSMutableIndexSet indexSet];
    for (int i=0; i <contacts.count; i++) {
        Contact *contact = contacts[i];
        if (![self emailsOfContact:contact]) {
            [indexSet addIndex:i];
        }
    }
    [array removeObjectsAtIndexes:indexSet];
    return array;

}

#pragma mark - tag
#pragma mark -search tag and contact



-(NSDictionary *)searchResultByKeyword:(NSString *)string{

#warning  trim space  of the string
    if (!string) {
        return nil;
    }
    // get possible contacts
    NSArray *advicedContacts;
    if (self.addressBook) {
        NSMutableArray *advicedPersonIDs=[@[] mutableCopy];
        for (signed long i= 0; i< self.peopleInAddressBook.count; i++) {
            ABRecordRef recordRef=(__bridge ABRecordRef)self.peopleInAddressBook[i];
            NSString *compositeName=(__bridge NSString *)ABRecordCopyCompositeName(recordRef);
            if ([compositeName containsString:string]) {
                [advicedPersonIDs addObject:@(ABRecordGetRecordID(recordRef))];
            }
        }
        advicedContacts=[Contact contactsOfContactIDs:advicedPersonIDs];

    }else{
        advicedContacts=[Contact contactsWhoseNameContains:string];
    }
    NSArray *advicedtags=[Tag tagsWhoseNameContains:string];

    return @{FetchResultContactsKey:advicedContacts,FetchResultTagsKey:advicedtags};

}

-(void)updateCoreDataBasedOnContacts{
    // prepare all contacts

    ABAddressBookRef addressBook= ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        ABAuthorizationStatus authorizationStatus=ABAddressBookGetAuthorizationStatus();
        if (authorizationStatus != kABAuthorizationStatusAuthorized) {
            return ; // not authorizated
        }

        self.addressBook=addressBook;

        // initialize Tags
        BOOL isFirstLaunch=![Tag rootTag];
        Tag *colleaguesTag;
        Tag *allContactsTag;
        Tag *rootTag;
        if (isFirstLaunch) {
            // if first launch ,then create default tags
            rootTag=[Tag createTagWithTagName:RootTagName];
            colleaguesTag=[Tag createTagWithTagName:@"Colleagues"];
            allContactsTag=[Tag createTagWithTagName:@"All Contacts"];
            Tag *friendsTag=[Tag createTagWithTagName:@"Friends"];
            Tag *familyTag=[Tag createTagWithTagName:@"Family"];
            [rootTag addChildrenTagsObject:colleaguesTag];
            [rootTag addChildrenTagsObject:friendsTag];
            [rootTag addChildrenTagsObject:familyTag];
            [rootTag addChildrenTagsObject:allContactsTag];
        }

        self.peopleInAddressBook =(__bridge NSArray *) ABAddressBookCopyArrayOfAllPeople(addressBook);

        NSMutableSet *peopleRecordIDs=[[NSMutableSet alloc]init];

        for (signed long i= 0; i< self.peopleInAddressBook.count; i++) {
            ABRecordRef recordRef=(__bridge ABRecordRef)self.peopleInAddressBook[i];
            ABRecordID recordID=ABRecordGetRecordID(recordRef);
            [peopleRecordIDs addObject:@(recordID)];
            Contact *contact=[Contact contactOfContactID:recordID];

            if (contact) {
                // if contact exist in core data, update its info, because it may have been changed
                contact.contactName=[self nameOfPerson:recordRef];
            }else{
                // if contact doesn't exist in core data , then create contact
                contact=[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.context];
                contact.contactID=@(recordID);
                contact.contactName=[self nameOfPerson:recordRef];
                contact.contactIsDeleted=@(NO);
                [allContactsTag addDirectlyOwnedContactsObject:contact];
            }

            if (isFirstLaunch) {
                // if isFirstLaunch, then create company tag
                NSString *companyName=(__bridge NSString*)ABRecordCopyValue(recordRef, kABPersonOrganizationProperty);
                if (companyName.length) {
                    // if comanpy property exists, then create this company tag
                    Tag *tag=[Tag createTagWithTagName:companyName];
                    tag.parentTag=colleaguesTag;
                    [tag addDirectlyOwnedContactsObject:contact];
                }
            }
            CFRelease(recordRef);
        }
        [self saveContext];

        [[NSNotificationCenter defaultCenter] postNotificationName:ContactManagerDidFinishUpdatingCoreData object:nil];
    });
}
#pragma  mark - instruction from delegate











@end
