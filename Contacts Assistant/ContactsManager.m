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
#import "TagCell.h"
#import "ContactCell.h"
#import "Event.h"
#import "NSString+ContactsAssistant.h"
#import <AddressBook/AddressBook.h>
#import "defines.h"
#import <CoreData/CoreData.h>

NSString *const AdvicedContactsKey=@"AdvicedContactsKey";
NSString *const AdvicedTagsKey=@"AdvicedTagsKey";
NSString *const SearchResultContactsKey=@"SearchResultContactsKey";

NSString *const ContactInfoTypeKey=@"CIT";
NSString *const ContactInfoIndexKey=@"CII";
NSString *const ContactInfoLabelKey=@"CIL";
NSString *const ContactInfoValueKey=@"CIV";

NSString *const PersonInfoNameKey=@"N_";
NSString *const PersonInfoContactInfoKey=@"CI_";
NSString *const PersonInfoCompanyKey=@"C_";
NSString *const PersonInfoDepartmentKey=@"D_";
NSString *const PersonInfoJobTitleKey=@"J_";


typedef enum : NSUInteger {
    UpdateContactInfoModeAdd,
    UpdateContactInfoModeModify,
    UpdateContactInfoModeDelete,
} UpdateContactInfoMode;

@interface ContactsManager()


@property(assign,nonatomic)ABAddressBookRef addressBook;

@property(copy,nonatomic)NSArray *allPossibleIndexTitles;
@property(strong,nonatomic)NSMutableArray *arrangedAllContactsPlaceHolder; // same count with allPossibleIndexTitles,may has empty array

@property(nonatomic) ABPersonSortOrdering preferedSortOrdering;

@end

@implementation ContactsManager

#pragma mark - instanitiation

//note: instance of ABAddressBookRef must be used by only one thread.
static dispatch_queue_t abQueue;
static ContactsManager * shareManager;

+(instancetype)sharedContactManager{

    shareManager=[[self alloc]init];
    return shareManager;

}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager=[[super allocWithZone:zone]init];
        abQueue = dispatch_queue_create("ABQueue", NULL);
    });
    return shareManager;

}

#pragma mark - properties
-(NSMutableArray *)arrangedAllContactsPlaceHolder{
    if (!_arrangedAllContactsPlaceHolder) {
        _arrangedAllContactsPlaceHolder=[@[] mutableCopy];
        for (NSInteger index = 0; index<self.allPossibleIndexTitles.count; index++) {
            [_arrangedAllContactsPlaceHolder addObject:[@[] mutableCopy]];
        }
    }
    // 28 empty mutable array;
    return _arrangedAllContactsPlaceHolder;
}

-(NSArray *)allPossibleIndexTitles{
    if (!_allPossibleIndexTitles) {
        NSString *string=@"☆,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,#";
        _allPossibleIndexTitles=[string componentsSeparatedByString:@","];
    }
    return _allPossibleIndexTitles;
}

#pragma mark -Execute AddressBook Related task In Same Queue
// execute addressBook related task, use addressBook in the same queue
-(void)synExecuteBlockOnABQueue:(void(^)())block  {
    dispatch_sync(abQueue, block);
}
-(void)asyncExecuteBlockOnABQueue:(void(^)())block  {
    dispatch_async(abQueue, block);
}

#pragma mark - Rearrange Contacts
-(void)putContactIntoArrangedAllContacts:(Contact *)contact{
    if (contact.contactOrderWeight.doubleValue != 0.0) {
        [[self.arrangedAllContactsPlaceHolder firstObject] addObject:contact];
        return;
    }
    NSString *firstLetter= [self firstLetter:contact];
    NSInteger possibleIndex=[self.allPossibleIndexTitles indexOfObject:firstLetter];
    if (possibleIndex == NSNotFound) {
        [[self.arrangedAllContactsPlaceHolder lastObject] addObject:contact];
    }else{
        [self.arrangedAllContactsPlaceHolder[possibleIndex] addObject:contact];

    }
}
-(NSArray *)arrangedContactsunderTag:(Tag *)tag{
    NSArray *arragnedAllContacts=[self arrangedAllContacts];
    if ([tag isRootTag]) {
        return arragnedAllContacts;
    }
    return [self filterArrangedContacts:arragnedAllContacts underTag:tag];
}
-(NSArray *)arrangedAllContacts{
    NSMutableArray *arrangedContacts=[@[] mutableCopy];
    for (NSInteger section=0; section<self.arrangedAllContactsPlaceHolder.count; section++) {
        if ([self.arrangedAllContactsPlaceHolder[section] count]) {
            [arrangedContacts addObject:self.arrangedAllContactsPlaceHolder[section]];
        }
    }
    return [arrangedContacts copy];
}
-(void)arrangeContactToTop:(Contact *)contact indexTitle:(NSString *)title{
    NSInteger section=[self.allPossibleIndexTitles indexOfObject:title];
    [self.arrangedAllContactsPlaceHolder[section] removeObject:contact];
    [[self.arrangedAllContactsPlaceHolder firstObject] insertObject:contact atIndex:0];
}

-(NSArray *)filterArrangedContacts:(NSArray *)arrangedContacts underTag:(Tag *)tag{

    NSMutableArray *contacts = [@[] mutableCopy];
    for (int section = 0 ; section < arrangedContacts.count; section++) {
        NSMutableArray *originalSubContacts=arrangedContacts[section];
        NSMutableArray *newSubContacts=[@[] mutableCopy];
        for (int row = 0; row<originalSubContacts.count; row++) {
            Contact * contact= originalSubContacts[row];
            if ([contact.underWhichTags containsObject:tag] && !contact.contactIsDeleted.boolValue) {
                [newSubContacts addObject:contact];
            }
        }
        if (newSubContacts.count) {
            [contacts addObject:newSubContacts];
        }
    }
    return [contacts copy];
}
-(NSMutableArray *)indexTitleOfContacts:(NSArray *)contacts{

    NSMutableArray *indexTitles=[@[] mutableCopy];

    for (int section=0; section<contacts.count; section++) {
        NSArray *contactsInSection=contacts[section];
        Contact *contact=[contactsInSection firstObject];
        if (contact.contactOrderWeight.doubleValue != 0.0) {
            [indexTitles addObject:@"☆"];
        }else{
            NSString *firstLetter=[self firstLetter:contact];
            if (firstLetter) {
                [indexTitles addObject:firstLetter];
            }
        }
    }
    return indexTitles;
    
}

#pragma mark - Contact
-(ABRecordRef)personOfContact:(Contact *)contact{

    __block ABRecordRef person;
    [self synExecuteBlockOnABQueue:^{
        person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    }];
    return person;
}
-(NSComparisonResult)compareResult:(Contact *)contact1 contact2:(Contact *)contact2{

    NSComparisonResult result=[contact1.contactOrderWeight compare:contact2.contactOrderWeight];
    if (result != NSOrderedSame) {
        return  result;
    }

    ABRecordRef person1=[self personOfContact:contact1];
    ABRecordRef person2=[self personOfContact:contact2];
    CFComparisonResult compareresult=ABPersonComparePeopleByName(person1, person2, self.preferedSortOrdering);
    if (compareresult == kCFCompareLessThan) {
        return NSOrderedAscending;
    }else if (compareresult == kCFCompareGreaterThan){
        return NSOrderedDescending;
    }else{
        return NSOrderedSame;
    }

}
-(NSString *)firstLetter:(Contact *)contact{
 // return contact first letter for table index title
    if (!contact) {
        return nil;
    }
    NSString *name=[self contactNameForOrdering:contact];
    if (!name) {
        return @"#";
    }
    return [name firstLetterOfString];
}

-(NSString *)contactNameForDisplay:(Contact *)contact{
    //return displayed contact name in contact cell
    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return nil;
    }
    NSString *name=(__bridge NSString *)ABRecordCopyCompositeName(person);
    if (name) {
        return name;
    }

    NSString *email=[self emailAtIndex:0 contact:contact];
    if (email.length){
        return email;
    }

    NSString *phoneNumber=[self phoneNumberAtIndex:0 contact:contact];
    if (phoneNumber.length) {
        return phoneNumber;
    }
    return  @"无名称";
}

-(NSString *)contactNameForOrdering:(Contact *)contact{
    //return string for ordering
    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return nil;
    }
    NSString *name;
    // middle name ,suffix, prefix, are not involved in ordering
    if (self.preferedSortOrdering == kABPersonSortByLastName) {
        name = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        if (name) {return name;}
        name =(__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    }
    else{
        name = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        if (name) {return name;}
        name = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    }
    if (name) {return name;}

    name =(__bridge NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);
    if (name) {return name;}

    //    kABPersonMiddleNamePhoneticProperty is not involved in ordering
    name =(__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNamePhoneticProperty);
    if (name) {return name;}
    name =(__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNamePhoneticProperty);
    if (name) {return name;}

    name =(__bridge NSString *)ABRecordCopyValue(person, kABPersonNicknameProperty);
    if (name) {return name;}

    // phone number not involved in ordering
    name =[self emailAtIndex:0 contact:contact];
    if (name) {
        return name;
    }

    return @"😍";
}
-(UIImage *)thumbnailOfContact:(Contact *)contact{

    ABRecordRef person=[self personOfContact:contact];
    NSData *data=(__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
    UIImage *image=[UIImage imageWithData:data];

    if (!image) {
        image=[UIImage imageNamed:@"DefaultContactImage"];
    }


    return image;

}

-(NSString *)companyAndDepartmentOfContact:(Contact *)contact{

    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return nil;
    }
    NSString *companyName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonOrganizationProperty);
    NSString *departmentName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonDepartmentProperty);
    NSString *combinedString= [companyName ? companyName : @"" stringByAppendingString:departmentName ? departmentName : @""];
    return combinedString;

}

//contact info
-(BOOL)hasPhone:(Contact *)contact{
    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return NO;
    }
    ABMultiValueRef phones=(ABMultiValueRef)ABRecordCopyValue(person, kABPersonPhoneProperty);
    return ABMultiValueGetCount(phones);
}
-(BOOL)hasEmail:(Contact *)contact{
    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return NO;
    }
    ABMultiValueRef emails=(ABMultiValueRef)ABRecordCopyValue(person, kABPersonEmailProperty);
    return ABMultiValueGetCount(emails);

}
-(NSInteger)phoneCountOfContact:(Contact *)contact{
    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return 0;
    }
    ABMultiValueRef phones=ABRecordCopyValue(person, kABPersonPhoneProperty);
    return ABMultiValueGetCount(phones);

}
-(NSInteger)emailCountOfContact:(Contact *)contact{
    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return 0;
    }
    ABMultiValueRef emails=ABRecordCopyValue(person, kABPersonEmailProperty);
    return ABMultiValueGetCount(emails);
}

-(NSArray *)phoneNumbersOfContact:(Contact *)contact{

    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return nil;
    }
    ABMultiValueRef phones=ABRecordCopyValue(person, kABPersonPhoneProperty);
    NSMutableArray *phonesMA=[@[] mutableCopy];
    if (phones) {
        for (int i=0 ; i<ABMultiValueGetCount(phones); i++) {
            CFStringRef label=ABMultiValueCopyLabelAtIndex(phones, i);
            [phonesMA addObject:@{ContactInfoTypeKey:@(ContactInfoTypePhone),
                                  ContactInfoIndexKey:@(i),
                                  ContactInfoLabelKey:[ContactsManager localizedLabel:label],
                                  ContactInfoValueKey:(__bridge NSString *)ABMultiValueCopyValueAtIndex(phones, i)}];
        }
    }
    return phonesMA.count ? phonesMA : @[];
}

-(NSArray *)emailsOfContact:(Contact *)contact{

    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return nil;
    }
    ABMultiValueRef emails=ABRecordCopyValue(person, kABPersonEmailProperty);
    NSMutableArray *emailsMA=[@[] mutableCopy];

    if (emails) {
        for (int i=0 ; i<ABMultiValueGetCount(emails); i++) {
            CFStringRef label=ABMultiValueCopyLabelAtIndex(emails, i);
            [emailsMA addObject:@{ContactInfoTypeKey:@(ContactInfoTypeEmail),
                                  ContactInfoIndexKey:@(i),
                                  ContactInfoLabelKey:[ContactsManager localizedLabel:label],
                                  ContactInfoValueKey:(__bridge NSString *)ABMultiValueCopyValueAtIndex(emails, i)}];
        }
    }

    return emailsMA.count ? emailsMA : @[];
}
-(NSString *)phoneNumberAtIndex:(NSInteger )index contact:(Contact *)contact{

    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return nil;
    }
    ABMultiValueRef phones=(ABMultiValueRef)ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFIndex phonesCount= ABMultiValueGetCount(phones);
    NSString *name=nil;
    if (phonesCount>index) {
        name= (__bridge NSString *)ABMultiValueCopyValueAtIndex(phones, index);
    }
    return name;
}
-(NSString *)emailAtIndex:(NSInteger )index contact:(Contact *)contact{
    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return nil;
    }
    ABMultiValueRef emails=ABRecordCopyValue(person, kABPersonEmailProperty);
    CFIndex eamilsCount= ABMultiValueGetCount(emails);
    NSString*email=nil;
    if (eamilsCount>index) {
        email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(emails, index);
    }
    return email;
}

+(NSString *)localizedLabel:(CFStringRef)label{
    return (__bridge NSString *) ABAddressBookCopyLocalizedLabel(label);
}


#pragma mark - search
-(NSDictionary *)searchContacts:(NSArray *)contacts keywords:(NSArray *)keywords{

    if (!keywords.count) {
        return nil;
    }

    NSMutableArray *advicedContacts=[@[] mutableCopy];

    NSMutableSet *relatedTags=[NSMutableSet set];
    NSMutableArray *advicedTags=[@[] mutableCopy];

    NSMutableArray *resultContacts=[@[] mutableCopy];

    for (int section = 0 ; section < contacts.count; section++) {
        // search the matched contacts
        NSMutableArray *subContacts=contacts[section];
        NSMutableArray *conformedSubContacts=[@[] mutableCopy];
        for (int row= 0 ; row < subContacts.count; row++) {
            Contact *contact= subContacts[row];
            if (contact.contactIsDeleted.boolValue) {
                continue;
            }
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
        // search the matched tags
        if ([self string:tag.tagName conformKeywords:keywords]) {
            [advicedTags addObject:tag];
        }
    }
    return @{AdvicedContactsKey:advicedContacts,
             AdvicedTagsKey:advicedTags,
             SearchResultContactsKey:resultContacts};
    
}

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

    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return NO;
    }

    NSString *departmentName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonDepartmentProperty);
    if ([self string:departmentName conformKeywords:keywords]) {
        return YES;
    }

    NSArray *phones =[self phoneNumbersOfContact:contact];
    for (NSDictionary *phone in phones) {
        if ([self string:phone[ContactInfoValueKey] conformKeywords:keywords]) {
            return YES;
        }
    }

    NSArray *emails=[self emailsOfContact:contact];
    for (NSDictionary *email in emails) {
        if ([self string:email[ContactInfoValueKey] conformKeywords:keywords]) {
            return YES;
        }
    }

    NSArray *events=[[contact.attendWhichEvents allObjects] arrayByAddingObjectsFromArray:[contact.ownedEvents allObjects]];
    for (Event *event in events) {
        if ([self string:event.eventDescription conformKeywords:keywords]) {
            return YES;
        }
    }

    return NO;
}

#pragma mark load contacts
-(void)loadContacts{

    ABAddressBookRef addressBook= ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        ABAuthorizationStatus authorizationStatus=ABAddressBookGetAuthorizationStatus();
        if (authorizationStatus == kABAuthorizationStatusAuthorized) {
            self.addressBookAuthorized=YES;
            // load update CoreData
            self.addressBook=addressBook;
            self.preferedSortOrdering=ABPersonGetSortOrdering();
            [self updateCoreData];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didFinishLoadContacts];
        });
    });
}

-(void)updateCoreData{

    // if first launch ,then create default tags
    BOOL firstLaunch=[[NSUserDefaults standardUserDefaults]boolForKey:FirstLaunch];
    if (firstLaunch) {
        [self createDefaultTags];
    }
    Tag *rootTag=[Tag rootTag];
    // if keep syn with ab
    __block NSArray *sortedPeopleInAddressBook;
    [self synExecuteBlockOnABQueue:^{

        ABRecordRef source= ABAddressBookCopyDefaultSource(self.addressBook);
        sortedPeopleInAddressBook= (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(self. addressBook,source, self.preferedSortOrdering);

    }];
    NSMutableSet *peopleRecordIDs=[[NSMutableSet alloc]init];
    // 优化心得：使用set，用小set配合，枚举，及时删除已确认的对象
    NSMutableOrderedSet *allContact=[[NSMutableOrderedSet alloc]initWithArray:[Contact allContacts]];
    NSMutableOrderedSet *allContactID=[[allContact valueForKey:@"contactID"] mutableCopy];

    for (signed long i= 0; i< sortedPeopleInAddressBook.count; i++) {
        ABRecordRef recordRef=(__bridge ABRecordRef)sortedPeopleInAddressBook[i];
        ABRecordID recordID=ABRecordGetRecordID(recordRef);
        [peopleRecordIDs addObject:@(recordID)];
        //Contact *contact=[Contact contactOfContactID:recordID]; //1071ms time consuming
        // use NSMutableOrderedSet to search, more efficient
        Contact *contact=nil;
        if ([allContactID containsObject:@(recordID)]) {
            NSInteger contactIndex=[allContactID indexOfObject:@(recordID)];
            contact=[allContact objectAtIndex:contactIndex];
            [allContact removeObjectAtIndex:contactIndex];
            [allContactID removeObjectAtIndex:contactIndex];
        }

        if (contact) {
            // update contact name in core data , because it may have been changed ( id wouldn't change ? )
            contact.contactName=[self contactNameForDisplay:contact];
        }else{
            // add contact that is not in core data but in ab
            contact=[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:APP.managedObjectContext];
            contact.contactID=@(recordID);
            contact.contactName=[self contactNameForDisplay:contact];
            contact.contactIsDeleted=@(NO);
            [rootTag addOwnedContactsObject:contact];
            NSString *companyName=(__bridge NSString*)ABRecordCopyValue(recordRef, kABPersonOrganizationProperty);
            if (companyName.length) {
                // if comanpy property exists, then create this company tag
                Tag *tag=[Tag createTagWithName:companyName];
                [tag addOwnedContactsObject:contact];
            }

        }
        // put it into the arrangedAllContacts
        if ([contact.contactIsDeleted boolValue] == NO) {
            [self putContactIntoArrangedAllContacts:contact];
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate loadingContact:i total:sortedPeopleInAddressBook.count];
        });
    }

    // delete any contact in core data which is not included in ab
    [Contact deleteContactsWhoseIDNotIn:peopleRecordIDs];
    [APP saveContext];
}

-(BOOL)addressBookAuthorized{
    ABAuthorizationStatus authorizationStatus=ABAddressBookGetAuthorizationStatus();
    if (authorizationStatus != kABAuthorizationStatusAuthorized){
        return NO;
    }
    return YES;
}

-(void)createDefaultTags{

    [Tag createTagWithName:RootTagName];
    [Tag createTagWithName:@"朋友"];
    [Tag createTagWithName:@"家人"];
}

#pragma  mark - edit contact info
-(BOOL)addContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact{
    return [self updateContactInfo:contactInfo contact:contact mode:UpdateContactInfoModeAdd];
}

-(BOOL)modifyContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact{
    return [self updateContactInfo:contactInfo contact:contact mode:UpdateContactInfoModeModify];
}

-(BOOL)deleteContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact{
    return [self updateContactInfo:contactInfo contact:contact mode:UpdateContactInfoModeDelete];

}
-(BOOL)updateContactInfo:(NSDictionary *)contactInfo contact:(Contact *)contact mode:(UpdateContactInfoMode)mode{

    NSString *label=contactInfo[ContactInfoLabelKey];
    NSString *value=contactInfo[ContactInfoValueKey];
    NSInteger index=[contactInfo[ContactInfoIndexKey] integerValue];
    NSInteger type=[contactInfo[ContactInfoTypeKey] integerValue];
    ABPropertyID property= (type == ContactInfoTypePhone) ? kABPersonPhoneProperty : kABPersonEmailProperty;

    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return NO;
    }
    ABMultiValueRef multiContactInfo=ABRecordCopyValue(person, property);
    ABMutableMultiValueRef mutableMultiContactInfo= ABMultiValueCreateMutableCopy(multiContactInfo);
    if (!mutableMultiContactInfo) {
        mutableMultiContactInfo=ABMultiValueCreateMutable(property);
    }

    switch (mode) {
        case UpdateContactInfoModeAdd:{
            ABMultiValueAddValueAndLabel(mutableMultiContactInfo, (__bridge CFStringRef)value, (__bridge CFStringRef)label, NULL);
            break;
        }
        case UpdateContactInfoModeModify:{
            ABMultiValueReplaceValueAtIndex(mutableMultiContactInfo,(__bridge CFStringRef)value, index);
            ABMultiValueReplaceLabelAtIndex(mutableMultiContactInfo,(__bridge CFStringRef)label ,index);
            break;
        }
        case UpdateContactInfoModeDelete:{
            ABMultiValueRemoveValueAndLabelAtIndex(mutableMultiContactInfo,index);
            break;
        }
    }

    ABRecordSetValue(person,property,mutableMultiContactInfo,NULL);

    __block bool success;
    [self synExecuteBlockOnABQueue:^{
        success =  ABAddressBookSave(self.addressBook, NULL);
    }];
    return success;
}

#pragma  mark - create and remove person
-(Contact *)createPerson:(NSDictionary *)personInfo{

    NSString *name= personInfo[PersonInfoNameKey];
    NSString *company=personInfo[PersonInfoCompanyKey];
    NSString *department=personInfo[PersonInfoDepartmentKey];
    NSString *jobTitle=personInfo[PersonInfoJobTitleKey];
    NSArray *contactsInfo=personInfo[PersonInfoContactInfoKey];

    ABRecordRef person= ABPersonCreate();
    if (!person) {
        return nil;
    }
    ABRecordSetValue(person,kABPersonFirstNameProperty,(__bridge CFStringRef)name,NULL);
    ABRecordSetValue(person,kABPersonOrganizationProperty,(__bridge CFStringRef)company,NULL);
    ABRecordSetValue(person,kABPersonDepartmentProperty,(__bridge CFStringRef)department,NULL);
    ABRecordSetValue(person,kABPersonJobTitleProperty,(__bridge CFStringRef)jobTitle,NULL);

    ABMutableMultiValueRef phones=ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMutableMultiValueRef emails=ABMultiValueCreateMutable(kABMultiStringPropertyType);

    for (NSDictionary *contactInfo in contactsInfo) {
        switch ([contactInfo[ContactInfoTypeKey] integerValue]) {
            case ContactInfoTypePhone:{
                ABMultiValueAddValueAndLabel(phones, (__bridge CFStringRef)contactInfo[ContactInfoValueKey], (__bridge CFStringRef)contactInfo[ContactInfoLabelKey], NULL);
                break;
            }
            case ContactInfoTypeEmail:{
                ABMultiValueAddValueAndLabel(emails, (__bridge CFStringRef)contactInfo[ContactInfoValueKey], (__bridge CFStringRef)contactInfo[ContactInfoValueKey], NULL);
                break;
            }
        }
    }

    ABRecordSetValue(person,kABPersonPhoneProperty,phones,NULL);
    ABRecordSetValue(person,kABPersonEmailProperty,emails,NULL);

    __block bool flag1;
    __block bool flag2;
    [self synExecuteBlockOnABQueue:^{
        flag1= ABAddressBookAddRecord(self.addressBook,person,NULL);
        flag2= ABAddressBookSave(self.addressBook, NULL);
    }];

    if (flag1 && flag2) {
        // create person in core data
        Contact * contact=[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:APP.managedObjectContext];
        contact.contactID=@(ABRecordGetRecordID(person));
        contact.contactName=[self contactNameForDisplay:contact];
        contact.contactIsDeleted=@(NO);
        [[Tag rootTag] addOwnedContactsObject:contact];

        NSString *firstLetter= [self firstLetter:contact];
        NSInteger possibleIndex=[self.allPossibleIndexTitles indexOfObject:firstLetter];
        if (possibleIndex == NSNotFound) {
            //update arrangedContact
            [[self.arrangedAllContactsPlaceHolder lastObject] addObject:contact];
        }else{
            [self.arrangedAllContactsPlaceHolder[possibleIndex] addObject:contact];
            self.arrangedAllContactsPlaceHolder[possibleIndex]=[[self.arrangedAllContactsPlaceHolder[possibleIndex] sortedArrayUsingComparator:^NSComparisonResult(Contact * obj1, Contact * obj2) {
                return [self compareResult:obj1 contact2:obj2];
            }] mutableCopy];
        }
        [APP saveContext];
        return contact;
    }

    return nil;

}

-(void)removePerson:(Contact*)contact{

    ABRecordRef person=[self personOfContact:contact];

    [self asyncExecuteBlockOnABQueue:^{
        ABAddressBookRemoveRecord(self.addressBook, person, NULL);
        ABAddressBookSave(self.addressBook, NULL);
    }];
}











@end
