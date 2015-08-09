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

NSString *const AdvicedContactsKey=@"AdvicedContactsKey";
NSString *const AdvicedTagsKey=@"AdvicedTagsKey";
NSString *const SearchResultContactsKey=@"SearchResultContactsKey";


NSString *const ContactManagerDidFinishUpdatingCoreData=@"ContactManagerDidFinishUpdatingCoreData";

NSString *const PhoneLabel=@"PLabel";
NSString *const PhoneNumber=@"PNum";
NSString *const EmailLabel=@"ELabel";
NSString *const EmailValue=@"EValue";


NSString * const CommunicationPhones=@"CPhones";
NSString * const CommunicationEmails=@"CEmails";

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

+(NSString *)localizedLabel:(CFStringRef)label{
    return (__bridge NSString *) ABAddressBookCopyLocalizedLabel(label);
}
+(NSArray *)localizedSystemContactLabels{

    return @[ [ContactsManager localizedLabel:kABWorkLabel],
             [ContactsManager localizedLabel:kABHomeLabel],
             [ContactsManager localizedLabel:kABPersonPhoneMobileLabel],
             [ContactsManager localizedLabel:kABPersonPhoneIPhoneLabel],
             [ContactsManager localizedLabel:kABPersonPhoneMainLabel],
             [ContactsManager localizedLabel:kABPersonPhoneHomeFAXLabel],
             [ContactsManager localizedLabel:kABPersonPhoneWorkFAXLabel],
             [ContactsManager localizedLabel:kABPersonPhoneOtherFAXLabel],
             [ContactsManager localizedLabel:kABPersonPhonePagerLabel],
             [ContactsManager localizedLabel:kABOtherLabel]
             ];
}

+(NSArray *)localizedSystemRelationLabel{

    return @[ [ContactsManager localizedLabel:kABPersonFatherLabel],
              [ContactsManager localizedLabel:kABPersonMotherLabel],
              [ContactsManager localizedLabel:kABPersonParentLabel],
              [ContactsManager localizedLabel:kABPersonBrotherLabel],
              [ContactsManager localizedLabel:kABPersonSisterLabel],
              [ContactsManager localizedLabel:kABPersonChildLabel],
              [ContactsManager localizedLabel:kABPersonFriendLabel],
              [ContactsManager localizedLabel:kABPersonSpouseLabel],
              [ContactsManager localizedLabel:kABPersonPartnerLabel],
              [ContactsManager localizedLabel:kABPersonAssistantLabel],
              [ContactsManager localizedLabel:kABPersonManagerLabel]
              ];
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

    NSString *name=(__bridge NSString *)ABRecordCopyCompositeName(recordRef);
    return  name;
}

-(UIImage *)thumbnailOfContact:(Contact *)contact{

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    NSData *data=(__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
    UIImage *image=[UIImage imageWithData:data];


    return image;

}
-(NSComparisonResult)compareResult:(Contact *)contact1 contact2:(Contact *)contact2{

    NSComparisonResult result=[contact1.contactOrderWeight compare:contact2.contactOrderWeight];
    if (result != NSOrderedSame) {
        return  result;
    }

    ABRecordRef person1= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact1.contactID.intValue);
    ABRecordRef person2= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact2.contactID.intValue);
    CFComparisonResult compareresult=ABPersonComparePeopleByName(person1, person2, ABPersonGetSortOrdering());
    if (compareresult == kCFCompareLessThan) {
        return NSOrderedAscending;
    }else if (compareresult == kCFCompareGreaterThan){
        return NSOrderedDescending;
    }else{
        return NSOrderedSame;
    }

}
-(NSString *)firstLetter:(Contact *)contact{

    if (!contact) {
        return nil;
    }
    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    NSString *name=(__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);

    if (!name.length) {
        name=[self nameOfPerson:person];
    }

    NSMutableString *mname=[name mutableCopy];
    CFRange range=CFRangeMake(0, 1);
    CFStringTransform((__bridge CFMutableStringRef)mname, &range, kCFStringTransformMandarinLatin, NO);
    NSString *firstLetter=[[mname substringToIndex:1] uppercaseString];
    NSLog(@"%@ first letter %@",contact.contactName,firstLetter);
    return  firstLetter;

}

-(NSString *)companyAndDepartmentOfContact:(Contact *)contact{

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    NSString *companyName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonOrganizationProperty);
    NSString *departmentName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonDepartmentProperty);
    NSString *combinedString= [companyName ? companyName : @"" stringByAppendingString:departmentName ? departmentName : @""];
    return combinedString;
//    combinedString.length ? combinedString : nil;

}

-(NSArray *)phoneNumbersOfContact:(Contact *)contact{

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    ABMultiValueRef phones=ABRecordCopyValue(person, kABPersonPhoneProperty);
    NSMutableArray *phonesMA=[@[] mutableCopy];
    if (phones) {
        for (int i=0 ; i<ABMultiValueGetCount(phones); i++) {
            CFStringRef label=ABMultiValueCopyLabelAtIndex(phones, i);
            [phonesMA addObject:@{PhoneLabel:[ContactsManager localizedLabel:label],
                                  PhoneNumber:(__bridge NSString *)ABMultiValueCopyValueAtIndex(phones, i)}];
        }
    }

    return phonesMA.count ? phonesMA : nil;

}

-(NSArray *)emailsOfContact:(Contact *)contact{

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    ABMultiValueRef emails=ABRecordCopyValue(person, kABPersonEmailProperty);
    NSMutableArray *emailsMA=[@[] mutableCopy];

    if (emails) {
        for (int i=0 ; i<ABMultiValueGetCount(emails); i++) {
            CFStringRef label=ABMultiValueCopyLabelAtIndex(emails, i);
            [emailsMA addObject:@{EmailLabel:[ContactsManager localizedLabel:label],
                                  EmailValue:(__bridge NSString *)ABMultiValueCopyValueAtIndex(emails, i)}];
        }
    }

    return emailsMA.count ? emailsMA : nil;
    
}
-(NSArray *)filterContactsWithoutPhoneNumbers:(NSArray *)contacts{

    NSMutableArray *array=[@[] mutableCopy];

    for (int section = 0; section < contacts.count; section++) {

        NSMutableArray *subArray=[@[] mutableCopy];
        NSMutableArray *sectionArray=contacts[section];
        for (int row=0 ; row < sectionArray.count; row++) {
            Contact *contact = sectionArray[row];
            if ([self phoneNumbersOfContact:contact] ) {
                [subArray addObject:contact];
            }
        }
        if (subArray.count > 0) {
            [array addObject:subArray];
        }
    }
    NSLog(@"contacts:%@",@(array.count));

    return array;
}
-(NSArray *)filterContactsWithoutemail:(NSArray *)contacts{

    NSMutableArray *array=[@[] mutableCopy];

    for (int section = 0; section < contacts.count; section++) {
        NSMutableArray *subArray=[@[] mutableCopy];
        NSMutableArray *sectionArray=contacts[section];
        for (int row=0 ; row < sectionArray.count; row++) {
            Contact *contact = sectionArray[row];
            if ([self emailsOfContact:contact] ) {
                [subArray addObject:contact];
            }
        }
        if (subArray.count > 0) {
            [array addObject:subArray];
        }
    }
    NSLog(@"contacts:%@",@(array.count));
    return array;

}

#pragma mark - tag
#pragma mark -search tag and contact
-(BOOL)string:(NSString *)string conformKeywords:(NSArray *)keywords{

    BOOL flag = YES;
    for (NSString *keyword in keywords) {
        if (![string localizedCaseInsensitiveContainsString:keyword]) {
            flag=NO;
            break;
        }
    }
    return flag;
}

-(BOOL)doesContact:(Contact *)contact conformKeywords:(NSArray *)keywords{
    // if composite name , departmentName, phone number or email contain  keywords, then return yes, otherwise return no


    // evalute name
    if ([self string:contact.contactName conformKeywords:keywords]) {
        return YES;
    }

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    NSString *departmentName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonDepartmentProperty);
    if ([self string:departmentName conformKeywords:keywords]) {
        return YES;
    }
    NSArray *phones =[[self phoneNumbersOfContact:contact] valueForKey:PhoneNumber];
    NSString *phonesString=[phones componentsJoinedByString:@" "];
    if ([self string:phonesString conformKeywords:keywords]) {
        return YES;
    }

    NSArray *emails=[[self emailsOfContact:contact] valueForKey:EmailValue];
    NSString *emailsString=[emails componentsJoinedByString:@" "];
    if ([self string:emailsString conformKeywords:keywords]) {
        return YES;
    }
    return NO;
}

-(NSDictionary *)searchContacts:(NSArray *)contacts keywords:(NSArray *)keywords{

    if (!keywords.count) {
        return nil;
    }

    NSMutableArray *advicedContacts=[@[] mutableCopy];

    NSMutableSet *relatedTags=[NSMutableSet set];
    NSMutableArray *advicedTags=[@[] mutableCopy];
    
    NSMutableArray *resultContacts=[@[] mutableCopy];

    for (int section = 0 ; section < contacts.count; section++) {
        NSMutableArray *subContacts=contacts[section];
        NSMutableArray *conformedSubContacts=[@[] mutableCopy];
        for (int row= 0 ; row < subContacts.count; row++) {
            Contact *contact= subContacts[row];
            if ([self doesContact:contact conformKeywords:keywords]) {
                // if conform , it is one of the adviced contacts
                [advicedContacts addObject:contact];
                [conformedSubContacts addObject:contact];
            }
            [relatedTags addObjectsFromArray:[contact.underWhichTags allObjects]];
        }
        if (conformedSubContacts.count) {
            [resultContacts addObject:conformedSubContacts];
        }
    }
    for (Tag *tag in relatedTags) {
        if ([self string:tag.tagName conformKeywords:keywords]) {
            [advicedTags addObject:tag];
        }
    }
    return @{AdvicedContactsKey:advicedContacts,
             AdvicedTagsKey:advicedTags,
             SearchResultContactsKey:resultContacts};

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
        Tag *rootTag=[Tag rootTag];
        BOOL isFirstLaunch = !rootTag;
        Tag *colleaguesTag;
        if (isFirstLaunch) {
            // if first launch ,then create default tags
            rootTag=[Tag getTagWithTagName:RootTagName];
            colleaguesTag=[Tag getTagWithTagName:@"Colleagues"];
            [Tag getTagWithTagName:@"Friends"];
            [Tag getTagWithTagName:@"Family"];
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
                [rootTag addOwnedContactsObject:contact];

            }

            if (isFirstLaunch) {
                // if isFirstLaunch, then create company tag
                NSString *companyName=(__bridge NSString*)ABRecordCopyValue(recordRef, kABPersonOrganizationProperty);

                if (companyName.length) {
                    // if comanpy property exists, then create this company tag
                    Tag *tag=[Tag getTagWithTagName:companyName];
                    [tag addOwnedContactsObject:contact];
                    [colleaguesTag addOwnedContactsObject:contact];
                    NSLog(@"%@,company:%@",@(i),companyName);
                }
            }
            CFRelease(recordRef);
        }
        [self saveContext];

        [[NSNotificationCenter defaultCenter] postNotificationName:ContactManagerDidFinishUpdatingCoreData object:nil];
    });
}

-(void)addContactLabel:(NSString *)label value:(NSString *)phoneOrEmail isPhoneNumber:(BOOL)isPhoneNumber{
    
}

#pragma  mark - instruction from delegate











@end
