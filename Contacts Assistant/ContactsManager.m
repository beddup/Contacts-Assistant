//
//  ContactsManager.m
//  Contacts Assistant
//
//  Created by Amay on 7/15/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ContactsManager.h"
#import "AppDelegate.h"
#import "Contact.h"
#import "Relation.h"
#import "Tag.h"
#import "HeaderView.h"
#import "TagCell.h"
#import "ContactCell.h"

#import <AddressBook/AddressBook.h>

#import <CoreData/CoreData.h>

NSString *const FetchResultContactsKey=@"Contacts";
NSString *const FetchResultTagsKey=@"Tags";
NSString *const ContactManagerDidFinishUpdatingCoreData=@"ContactManagerDidFinishUpdatingCoreData";

typedef enum : NSUInteger {
    CellTypeTagCellNormal,
    CellTypeContactCellNormal,
    CellTypeAddNewTag,
    CellTypeAddNewContact,
    CellTypeShowMoreTag,
} CellType;

@interface ContactsManager()<HeaderViewDelegate>

@property(weak,nonatomic)NSManagedObjectContext *context;
@property(strong,nonatomic)NSArray *allContacts;
@property(nonatomic,assign)ABAddressBookRef addressBook;

@property(strong,nonatomic)NSArray *tags;
@property(strong,nonatomic)NSArray *contacts;
@property(strong,nonatomic)NSArray *cellHeightArray;

@property(strong,nonatomic)Tag *currentTag;

@property(strong,nonatomic)UITableViewRowAction *deleteAction;
@property(strong,nonatomic)UITableViewRowAction *renameAction;
@property(strong,nonatomic)UITableViewRowAction *moreAction;
@property(strong,nonatomic)UITableViewRowAction *shareAction;

@property(weak,nonatomic)UITableView *tableView;


@end

@implementation ContactsManager

@synthesize contacts=_contacts;

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


-(UITableViewRowAction *)deleteAction{
    if (!_deleteAction) {
        _deleteAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"delete");
        }];
    }
    return _deleteAction;
}
-(UITableViewRowAction *)renameAction{
    if (!_renameAction) {
        _renameAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"重命名" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"Rename");
        }];
        _renameAction.backgroundColor=[UIColor orangeColor];
    }
    return _renameAction;
}
-(UITableViewRowAction *)moreAction{
    if (!_moreAction) {
        _moreAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"更多" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"more");
        }];
        _moreAction.backgroundColor=[UIColor lightGrayColor];
    }
    return _moreAction;
}
-(UITableViewRowAction *)shareAction{
    if (!_shareAction) {
        _shareAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"分享" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"share");
        }];
        _shareAction.backgroundColor=[UIColor orangeColor];

    }
    return _shareAction;
}

-(NSArray *)tags{
    if (!_tags) {
        _tags=[[self.currentTag.childrenTags allObjects] sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
            return [obj1.tagName compare:obj2.tagName];
        }];
;
    }
    return _tags;
}
-(NSArray *)contacts{
    if (!_contacts) {
        _contacts=[[self.currentTag.directlyOwnedContacts allObjects]sortedArrayUsingComparator:^NSComparisonResult(Contact * obj1, Contact * obj2) {
            return [obj1.contactName compare:obj2.contactName];
        }];
    }
    return _contacts;
}
-(void)setContacts:(NSArray *)contacts{
    _contacts=contacts;
    [self.tableView reloadData];

}
#pragma  mark - tableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{

    return 1;

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSLog(@"count:%@",@(self.contacts.count));
    return self.contacts.count;

}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    ContactCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Contact Cell"];
    if (!cell) {
        cell=[[ContactCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Contact Cell"];
    }

    cell.contact=self.contacts[indexPath.row];

    return cell;

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 120;
}


-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
#pragma  mark HeaderViewDelegate
-(void)addNewContact{
    [self.delegate addNewContactUnderTag:self.currentTag];
}
-(void)addNewTagNamed:(NSString *)tagName{
    Tag *tag=[self createTagWithTagName:tagName];
    tag.parentTag=self.currentTag;
    NSLog(@"add :%lu",(unsigned long)self.currentTag.childrenTags.count);
    self.tags=nil;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationNone];
    [self saveContext];
}
-(BOOL)tagNameExists:(NSString *)tagName{
    if ([self tagWithName:tagName]) {
        return YES;
    }
    return NO;
}
#pragma mark - tableviewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

}
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
// 必须实现该方法，edit action 才有效果
//    To enable the swipe-to-delete feature of table views (wherein a user swipes horizontally across a row to display a Delete button), you must implement this method
}
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @[self.deleteAction,self.shareAction,self.moreAction];
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
    NSArray *phonesArray =(__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(phones);
    return phonesArray.count ? phonesArray : nil;

}
-(NSArray *)emailsOfContact:(Contact *)contact{
    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    ABMultiValueRef emails=ABRecordCopyValue(person, kABPersonEmailProperty);
    NSArray *emailsArray =(__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emails);

    return emailsArray.count ? emailsArray : nil;

}
-(NSArray *)addressesOfContact:(Contact *)contact{

    return nil;
}

-(NSManagedObjectContext *)context{
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
}

-(void)saveContext{
    [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
}

-(NSDictionary *)searchResultByKeyword:(NSString *)string{
    if (!string) {
        return nil;
    }
    // get possible contacts
    NSArray *advicedContacts;
    if (self.addressBook) {
        NSMutableArray *advicedPersonIDs=[@[] mutableCopy];
        CFArrayRef allPeopleRecords = ABAddressBookCopyArrayOfAllPeople(self.addressBook);
        for (signed long i= 0; i< CFArrayGetCount(allPeopleRecords); i++) {
            ABRecordRef recordRef=CFArrayGetValueAtIndex(allPeopleRecords, i);
            NSString *compositeName=(__bridge NSString *)ABRecordCopyCompositeName(recordRef);
            if ([compositeName containsString:string]) {
                [advicedPersonIDs addObject:@(ABRecordGetRecordID(recordRef))];
                continue;
            }
        }
        advicedContacts=[self contactsOfRecordIDs:advicedPersonIDs];

    }else{
        NSFetchRequest *contactFectchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Contact"];
        contactFectchRequest.predicate=[NSPredicate predicateWithFormat:@"contactName CONTAINS %@",string];
        advicedContacts=[self.context executeFetchRequest:contactFectchRequest error:NULL];
    }
    //get possible tags
    NSFetchRequest *tagFectchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Tag"];
   tagFectchRequest.predicate=[NSPredicate predicateWithFormat:@"tagName CONTAINS %@",string];
    NSArray *advicedtags=[self.context executeFetchRequest:tagFectchRequest error:NULL];

    return @{FetchResultContactsKey:advicedContacts,FetchResultTagsKey:advicedtags};

}

-(NSDictionary *)elementsUnderTag:(Tag *)tag{
    if (!tag) {
        return nil;
    }
    return @{FetchResultContactsKey:tag.directlyOwnedContacts,FetchResultTagsKey:tag.childrenTags};

}

-(NSSet *)relationsUnderContact:(Contact *)contact{
    
    return contact.relationsWithOtherPeople;

}

-(NSArray *)fetchAllContacts{
    // prepare core data
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    [fetchRequest setFetchBatchSize:20];
    NSError *error = nil;
    NSArray *fetchedObjects = [self.context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"fetchedObjects nil");
    }
    NSLog(@"fetchedObjects:%@",fetchedObjects);
    self.allContacts=fetchedObjects;
    return fetchedObjects;
}
-(NSArray *)fetchAllTags{

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    NSError *error = nil;
    return [self.context executeFetchRequest:fetchRequest error:&error];

}

-(void)updateCoreDataBasedOnContacts{

    NSMutableArray *allContactsInCoreData=[[self fetchAllContacts]mutableCopy];

    // prepare all contacts
    ABAddressBookRef addressBook= ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        ABAuthorizationStatus authorizationStatus=ABAddressBookGetAuthorizationStatus();
        if (authorizationStatus != kABAuthorizationStatusAuthorized) {
            return ; // not authorizated
        }
        self.addressBook=addressBook;
        // Update Tags
        NSMutableArray *tags=[[self fetchAllTags] mutableCopy];
        BOOL isFirstLaunch=!tags.count;
        Tag *colleaguesTag;
        Tag *allContactsTag;
        if (isFirstLaunch) {
            // if first launch ,then create default tags
            Tag *RootTag=[self createTagWithTagName:@"RootTag"];
            colleaguesTag=[self createTagWithTagName:@"Colleagues"];
            allContactsTag=[self createTagWithTagName:@"All Contacts"];
            Tag *friendsTag=[self createTagWithTagName:@"Friends"];
            Tag *familyTag=[self createTagWithTagName:@"Family"];
            [tags addObject:RootTag];
            [tags addObject:friendsTag];
            [tags addObject:familyTag];
            [tags addObject:colleaguesTag];
            [tags addObject:allContactsTag];
            [RootTag addChildrenTagsObject:colleaguesTag];
            [RootTag addChildrenTagsObject:friendsTag];
            [RootTag addChildrenTagsObject:familyTag];
            [RootTag addChildrenTagsObject:allContactsTag];
        }

        CFArrayRef allPeopleRecords = ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSMutableSet *allPeopleRecordIDs=[[NSMutableSet alloc]init];
        for (signed long i= 0; i< CFArrayGetCount(allPeopleRecords); i++) {
            ABRecordRef recordRef=CFArrayGetValueAtIndex(allPeopleRecords, i);
            ABRecordID recordID=ABRecordGetRecordID(recordRef);
            [allPeopleRecordIDs addObject:@(recordID)];
            Contact *contact=[self contactOfRecord:recordRef];
            NSLog(@"id:%@,contact:%@",@(recordID),contact);

            if (contact) {
                // if contact exist in core data, update its info, because it may have been changed
                contact.contactName=[self nameOfPerson:recordRef];
            }else{
                // if contact doesn't exist in core data , then create contact
                contact=[NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:self.context];
                contact.contactID=@(recordID);
                contact.contactName=[self nameOfPerson:recordRef];
                [allContactsTag addDirectlyOwnedContactsObject:contact];
            }
            if (isFirstLaunch) {
                // if isFirstLaunch, then create company tag
                NSString *companyName=(__bridge NSString*)ABRecordCopyValue(recordRef, kABPersonOrganizationProperty);
                if (companyName.length) {
                    // if comanpy property exists, then create this company tag
                    Tag *tag=[self createTagWithTagName:companyName];
                    tag.parentTag=colleaguesTag;
                    [tag addDirectlyOwnedContactsObject:contact];
                    NSLog(@"tagname:%@",tag.tagName);
                }
            }
//            CFRelease(recordRef);
        }
//        CFRelease(allPeopleRecords);
        // Remove the contacts in core data which are not included in the addressbook
        NSPredicate *removePredicator=[NSPredicate predicateWithFormat:@"NOT contactID IN %@",allPeopleRecordIDs];
        NSArray *objectsToBeRemoved=[allContactsInCoreData filteredArrayUsingPredicate:removePredicator];
        NSLog(@"objectsToBeRemoved:%@",objectsToBeRemoved);
        for (Contact * contact in objectsToBeRemoved) {
            [self.context deleteObject:contact];
        }

        self.contacts=[self fetchAllContacts];
        NSLog(@"update %lu",(unsigned long)self.currentTag.childrenTags.count);
        [[NSNotificationCenter defaultCenter] postNotificationName:ContactManagerDidFinishUpdatingCoreData object:nil];

        [self saveContext];

    });
}

-(NSString *)nameOfPerson:(ABRecordRef)recordRef{
    NSString *firstName=(__bridge NSString *)ABRecordCopyValue(recordRef, kABPersonFirstNameProperty);
    NSString *lastName=(__bridge NSString *)ABRecordCopyValue(recordRef, kABPersonLastNameProperty);
    NSString *name=[lastName==nil ? @"" :lastName stringByAppendingString:firstName==nil ? @"" : firstName];
    return name;
}

-(Contact *)contactOfRecord:(ABRecordRef)recordRef{
    ABRecordID recordID=ABRecordGetRecordID(recordRef);
    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    fetchRequest.predicate=[NSPredicate predicateWithFormat:@"contactID == %@",@(recordID)];
    NSArray *contacts=[self.context executeFetchRequest:fetchRequest error:NULL];
    return  [contacts firstObject];
}

-(NSArray *)contactsOfRecordIDs:(NSArray *)recordIDs{
    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    fetchRequest.predicate=[NSPredicate predicateWithFormat:@"contactID IN %@",recordIDs];
    NSArray *contacts=[self.context executeFetchRequest:fetchRequest error:NULL];
    return  [contacts firstObject];
}

-(Tag *)tagWithName:(NSString *)name{
    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    fetchRequest.predicate=[NSPredicate predicateWithFormat:@"tagName == %@",name];
    NSArray *tags=[self.context executeFetchRequest:fetchRequest error:NULL];
    return  [tags firstObject];

}
-(Tag *)createTagWithTagName:(NSString *)name{

    Tag *tag=[self tagWithName:name];
    if (!tag) {
        tag=[NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.context];
        
        tag.tagName=name;
    }
    return tag;
}

@end
