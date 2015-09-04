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
#import "Event.h"
#import "NSString+ContactsAssistant.h"
#import <AddressBook/AddressBook.h>
#import <CoreData/CoreData.h>

NSString *const ContactManagerDidFinishUpdatingCoreData=@"ContactManagerDidFinishUpdatingCoreData";

NSString *const AdvicedContactsKey=@"AdvicedContactsKey";
NSString *const AdvicedTagsKey=@"AdvicedTagsKey";
NSString *const SearchResultContactsKey=@"SearchResultContactsKey";

NSString *const ContactInfoTypeKey=@"CIT";
NSString *const ContactInfoIndexKey=@"CII";
NSString *const ContactInfoLabelKey=@"CIL";
NSString *const ContactInfoValueKey=@"CIV";

typedef enum : NSUInteger {
    UpdateContactInfoModeAdd,
    UpdateContactInfoModeModify,
    UpdateContactInfoModeDelete,
} UpdateContactInfoMode;
@interface ContactsManager()

@property(copy)dispatch_queue_t abQueue;
//note: instance of ABAddressBookRef must be used by only one thread.


@property(weak,nonatomic)NSManagedObjectContext *context;

@property(nonatomic,assign)ABAddressBookRef addressBook;

//for update tableview
@property(strong,nonatomic)Tag *currentTag;
@property(strong,nonatomic)NSMutableArray *contacts;
@property(strong,nonatomic)NSArray *cellHeightArray;

@property(strong,nonatomic)NSMutableArray *indexTitlesOfAllContacts;


@end

@implementation ContactsManager

@synthesize contacts=_contacts;

#pragma mark - instanitiation
static ContactsManager * shareManager;
static dispatch_queue_t abQueue;

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
        abQueue = dispatch_queue_create("ABQueue", NULL);
    });
    return shareManager;

}

-(id)copy{
    return shareManager;
}

-(void)executeBlockOnABQueue:(void(^)())block  {
    dispatch_sync(abQueue, block);
}

-(NSMutableArray *)indexTitlesOfAllContacts{
    if (!_indexTitlesOfAllContacts) {
        _indexTitlesOfAllContacts=[self indexTitleOfContact:[self arrangedAllContacts]];
    }
    return _indexTitlesOfAllContacts;
}

-(NSMutableArray *)indexTitleOfContact:(NSMutableArray *)contacts{

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

-(NSMutableArray *)arrangedAllContacts{
    if (!_arrangedAllContacts) {
        _arrangedAllContacts=[self rearrangeContacts:[Contact allContacts]];
    }
    return _arrangedAllContacts;
}

-(NSMutableArray *)arrangedContactsunderTag:(Tag *)tag{

    NSMutableArray *arrangedAllContacts=self.arrangedAllContacts;
    if ([tag isRootTag]) {
        return arrangedAllContacts;
    }
    return [self filterArrangedContacts:arrangedAllContacts underTag:tag];
}

-(NSMutableArray *)filterArrangedContacts:(NSMutableArray *)arrangedContacts underTag:(Tag *)tag{

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
    return contacts;
}

-(NSMutableArray *)rearrangeContacts:(NSArray *)contacts{

    NSMutableArray *sortedContacts=[[contacts sortedArrayUsingComparator:^NSComparisonResult(Contact * obj1, Contact * obj2) {
        return [self compareResult:obj1 contact2:obj2];
    }] mutableCopy];

    NSMutableArray *rearrangedContacts=[@[] mutableCopy];

    // get the top contacts
    NSPredicate *topContactsPredicate=[NSPredicate predicateWithFormat:@"contactOrderWeight.doubleValue != %f",0.0];
    NSArray *topContacts=[sortedContacts filteredArrayUsingPredicate:topContactsPredicate];
    if (topContacts.count) {
        [rearrangedContacts addObject:topContacts];
        [sortedContacts removeObjectsInArray:topContacts];
    }

    // arrange the left contacts
    NSMutableArray *contactsInSameSection=[@[] mutableCopy];
    for (int i =0 ; i<sortedContacts.count; i++) {
        Contact *contactToBeArranged=sortedContacts[i];
        if (contactToBeArranged.contactIsDeleted.boolValue) {
            continue;
        }
        NSString *firstLetter=[self firstLetter:contactToBeArranged];
        NSString *sectionLetter=[self firstLetter:[contactsInSameSection lastObject]];
        if (![firstLetter isEqualToString:sectionLetter]) {
            contactsInSameSection =[@[] mutableCopy];
            [rearrangedContacts addObject:contactsInSameSection];
        }
        [contactsInSameSection addObject:contactToBeArranged];
    }

    return rearrangedContacts;
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

#pragma mark - properties of contact

-(NSString *)contactNameForDisplay:(Contact *)contact{

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

-(ABRecordRef)personOfContact:(Contact *)contact{

//    __block ABRecordRef person;
//    [self executeBlockOnABQueue:^{
    ABRecordRef    person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
//    }];
    return person;
}
-(NSString *)contactNameForOrdering:(Contact *)contact{

    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        NSLog(@"person not ok");
        return nil;
    }
    NSString *name;
    // middle name ,suffix, prefix, are not involved in ordering
    if (ABPersonGetSortOrdering() == kABPersonSortByLastName) {
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

-(NSComparisonResult)compareResult:(Contact *)contact1 contact2:(Contact *)contact2{

    NSComparisonResult result=[contact1.contactOrderWeight compare:contact2.contactOrderWeight];
    if (result != NSOrderedSame) {
        return  result;
    }

    ABRecordRef person1=[self personOfContact:contact1];
    ABRecordRef person2=[self personOfContact:contact2];
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
    NSString *name=[self contactNameForOrdering:contact];
    if (!name) {
        return @"#";
    }
    return [name firstLetterOfString];
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
    return phonesMA.count ? phonesMA : nil;
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

    return emailsMA.count ? emailsMA : nil;
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

    NSArray *events=[contact.attendWhichEvents allObjects];
    for (Event *event in events) {
        if ([self string:event.event conformKeywords:keywords]) {
            return YES;
        }
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
            if (contact.contactIsDeleted.boolValue) {
                continue;
            }
            if ([self doesContact:contact conformKeywords:keywords]) {
                // if conform , it is one of the adviced contacts
                [advicedContacts addObject:contact];
                [conformedSubContacts addObject:contact];
                NSLog(@"contact name:%@",contact.contactName);
            }
            [relatedTags addObjectsFromArray:[contact.underWhichTags allObjects]];
        }
        if (conformedSubContacts.count) {
            [resultContacts addObject:conformedSubContacts];
        }
    }
    
    for (Tag *tag in relatedTags) {
        if ([self string:tag.tagName conformKeywords:keywords]) {
            NSLog(@"tag name:%@",tag.tagName);
            [advicedTags addObject:tag];
        }
    }
    NSLog(@"%@,%@",advicedContacts,advicedTags);
    return @{AdvicedContactsKey:advicedContacts,
             AdvicedTagsKey:advicedTags,
             SearchResultContactsKey:resultContacts};

}

-(void)createDefaultTags{

    [Tag getTagWithTagName:RootTagName];
    [Tag getTagWithTagName:@"朋友"];
    [Tag getTagWithTagName:@"家人"];
}

-(void)updateCoreData{

    // if first launch ,then create default tags
    Tag *rootTag=[Tag rootTag];
    if (!rootTag) {
        [self createDefaultTags];
    }

    // if keep syn with ab
//    __block
    NSArray *peopleInAddressBook;
//    [self executeBlockOnABQueue:^{
        peopleInAddressBook =(__bridge NSArray *) ABAddressBookCopyArrayOfAllPeople(self.addressBook);
//    }];
    NSMutableSet *peopleRecordIDs=[[NSMutableSet alloc]init];
    for (signed long i= 0; i< peopleInAddressBook.count; i++) {
        ABRecordRef recordRef=(__bridge ABRecordRef)peopleInAddressBook[i];
        ABRecordID recordID=ABRecordGetRecordID(recordRef);
        [peopleRecordIDs addObject:@(recordID)];
        Contact *contact=[Contact contactOfContactID:recordID];
        if (contact) {
            // update contact name in core data , because it may have been changed ( id wouldn't change ? )
            contact.contactName=[self contactNameForDisplay:contact];
        }else{
            // add contact that is not in core data but in ab
            contact=[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.context];
            contact.contactID=@(recordID);
            contact.contactName=[self contactNameForDisplay:contact];
            contact.contactIsDeleted=@(NO);
            [rootTag addOwnedContactsObject:contact];
            NSString *companyName=(__bridge NSString*)ABRecordCopyValue(recordRef, kABPersonOrganizationProperty);
            if (companyName.length) {
                // if comanpy property exists, then create this company tag
                Tag *tag=[Tag getTagWithTagName:companyName];
                [tag addOwnedContactsObject:contact];
            }
        }
//        CFRelease(recordRef);
    }
    // delete any contact in core data which is not included in ab
//    [Contact deleteContactsWhoseIDNotIn:peopleRecordIDs];
    [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];

}
-(void)loadContacts{

    ABAddressBookRef addressBook= ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        ABAuthorizationStatus authorizationStatus=ABAddressBookGetAuthorizationStatus();
        if (authorizationStatus != kABAuthorizationStatusAuthorized) {
            return ; // not authorizated
        }
        // load update CoreData
        self.addressBook=addressBook;
        [self updateCoreData];

        // tell observers update finished
        [[NSNotificationCenter defaultCenter] postNotificationName:ContactManagerDidFinishUpdatingCoreData object:nil];
    });
}
#pragma  mark - edit

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

//    __block bool success;
//    [self executeBlockOnABQueue:^{
      bool  success =  ABAddressBookSave(self.addressBook, NULL);
//    }];
    return success;
}

-(Contact *)createPerson:(NSDictionary *)personInfo{

    NSString *name= personInfo[@"name"];
    NSString *company=personInfo[@"company"];
    NSString *department=personInfo[@"department"];
    NSString *jobTitle=personInfo[@"jobTitle"];
    NSArray *contactsInfo=personInfo[@"contactsInfo"];

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
        switch ([contactInfo[@"ContactInfoType"] integerValue]) {
            case ContactInfoTypePhone:{
                ABMultiValueAddValueAndLabel(phones, (__bridge CFStringRef)contactInfo[@"ContactInfoValue"], (__bridge CFStringRef)contactInfo[@"ContactInfoLabel"], NULL);
                break;
            }
            case ContactInfoTypeEmail:{
                ABMultiValueAddValueAndLabel(emails, (__bridge CFStringRef)contactInfo[@"ContactInfoValue"], (__bridge CFStringRef)contactInfo[@"ContactInfoLabel"], NULL);
                break;
            }
        }
    }

    ABRecordSetValue(person,kABPersonPhoneProperty,phones,NULL);
    ABRecordSetValue(person,kABPersonEmailProperty,emails,NULL);

    __block bool flag1;
    __block bool flag2;
    [self executeBlockOnABQueue:^{
        flag1= ABAddressBookAddRecord(self.addressBook,person,NULL);
        flag2= ABAddressBookSave(self.addressBook, NULL);
    }];

    if (flag1 && flag2) {
        // create person in core data
        Contact * contact=[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.context];
        contact.contactID=@(ABRecordGetRecordID(person));
        contact.contactName=[self contactNameForDisplay:contact];
        contact.contactIsDeleted=@(NO);
        [[Tag rootTag] addOwnedContactsObject:contact];

        NSString *firstLetter= [self firstLetter:contact];
        NSInteger possibleIndex=[self.indexTitlesOfAllContacts indexOfObject:firstLetter];
        if (possibleIndex == NSNotFound) {
            // update indexTitlesOfAllContacts
            [self.indexTitlesOfAllContacts addObject:firstLetter];
            [self.indexTitlesOfAllContacts sortUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
                return [obj1 localizedCaseInsensitiveCompare:obj2];
            }];
            if ([self.indexTitlesOfAllContacts containsObject:@"☆"]) {
                [self.indexTitlesOfAllContacts removeObject:@"☆"];
                [self.indexTitlesOfAllContacts insertObject:@"☆" atIndex:0];
            }
            possibleIndex=[self.indexTitlesOfAllContacts indexOfObject:firstLetter];
            //update arrangedContact
            NSMutableArray *newSubContacts=[@[] mutableCopy];
            [newSubContacts addObject:contact];
            [self.arrangedAllContacts insertObject:newSubContacts atIndex:possibleIndex];

        }else{
            NSMutableArray *subcontacts = self.arrangedAllContacts[possibleIndex];
            [subcontacts addObject:contact];
            self.arrangedAllContacts[possibleIndex]=[[subcontacts sortedArrayUsingComparator:^NSComparisonResult(Contact * obj1, Contact * obj2) {
                return [self compareResult:obj1 contact2:obj2];
            }] mutableCopy];
        }
        return contact;
    }

    return nil;

}

-(void)removePerson:(Contact*)contact{

    ABRecordRef person=[self personOfContact:contact];

    [self executeBlockOnABQueue:^{
        ABAddressBookRemoveRecord(self.addressBook, person, NULL);
        ABAddressBookSave(self.addressBook, NULL);
    }];
}

-(void)addRelation:(NSString *)relationName forContact:(Contact *)contact otherContacts:(NSArray *)contacts{

    for (Contact *otherContact in contacts) {
        // update core data
        Relation *relation=[NSEntityDescription insertNewObjectForEntityForName:@"Relation" inManagedObjectContext:self.context];
        relation.relationName=relationName;
        relation.whoseRelation=contact;
        relation.otherContact=otherContact;
    }
    [self updateABRelationForContact:contact];

}
-(void)removeRelation:(Relation *)relation{

    [relation.whoseRelation removeRelationsWithOtherPeopleObject:relation];
    [self.context deleteObject:relation];
    [self updateABRelationForContact:relation.whoseRelation];
}

-(void)updateABRelationForContact:(Contact *)contact{
    ABRecordRef person=[self personOfContact:contact];
    if (!person) {
        return;
    }
    ABMutableMultiValueRef multiValue=ABMultiValueCreateMutable(kABMultiStringPropertyType);
    for (Relation *relation in contact.relationsWithOtherPeople) {
        ABMultiValueAddValueAndLabel(multiValue, (__bridge CFStringRef)relation.otherContact.contactName, (__bridge CFStringRef)relation.relationName, NULL);
    }
    ABRecordSetValue(person, kABPersonRelatedNamesProperty,multiValue,NULL);
    [self executeBlockOnABQueue:^{
        ABAddressBookSave(self.addressBook, NULL);
    }];
}










@end
