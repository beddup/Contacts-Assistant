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

@property(strong,nonatomic)Tag *currentTag;

@property(strong,nonatomic)UITableViewRowAction *deleteAction;
@property(strong,nonatomic)UITableViewRowAction *renameAction;
@property(strong,nonatomic)UITableViewRowAction *moreAction;
@property(strong,nonatomic)UITableViewRowAction *shareAction;

@property(weak,nonatomic)UITableView *tableView;


@end

@implementation ContactsManager
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
;
    }
    return _contacts;
}
#pragma  mark - tableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (!self.tableView) {
        self.tableView=tableView;
    }
    return 2;
}

static BOOL DisplayMoreTagCell = YES;
-(NSInteger)countOfTagsSectionCells{
    if (!self.tags.count) {
        return 1;
    }
    if (!DisplayMoreTagCell) {
        return self.tags.count;
    }
    if (self.tags.count > 3) {
        return 3+1; // 1 is for showing more
    }
    return self.tags.count <=3 ? self.tags.count : 4 ;
}

-(CellType)cellTypeAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1) {
        return self.contacts.count ? CellTypeContactCellNormal : CellTypeAddNewContact;

    }else{

        if (!self.tags.count) {
            return CellTypeAddNewTag;
        }

        if (DisplayMoreTagCell && self.tags.count > 3 && indexPath.row == 3 ) {
            return CellTypeShowMoreTag;
        }

        return CellTypeTagCellNormal;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return [self countOfTagsSectionCells];
    }
    return self.contacts.count ? self.contacts.count : 1 ;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell;
    switch ([self cellTypeAtIndexPath:indexPath]) {
        case CellTypeAddNewContact:{
            cell=[tableView dequeueReusableCellWithIdentifier:@"No Result Cell"];
            cell.textLabel.text= @"无联系人";
            break;
        }
        case CellTypeAddNewTag:{
            cell=[tableView dequeueReusableCellWithIdentifier:@"No Result Cell"];
            cell.textLabel.text=@"无标签";
            break;
        }
        case CellTypeContactCellNormal:{
            cell=[tableView dequeueReusableCellWithIdentifier:@"Contact Cell"];
            Contact *contact=self.contacts[indexPath.row];
            cell.textLabel.text=contact.contactName;
            break;
        }
        case CellTypeTagCellNormal:{
            cell=[tableView dequeueReusableCellWithIdentifier:@"Tag Cell"];
            Tag *tag=self.tags[indexPath.row];
            ((TagCell *)cell).tagName=tag.tagName;
            break;
        }
        case CellTypeShowMoreTag:{
            cell=[tableView dequeueReusableCellWithIdentifier:@"More Tags Cell"];
            cell.textLabel.text=@"Show More";
            break;
        }
    }

    return cell;

}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{

     HeaderView *headerView=(HeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"Header_View"];
    if (!headerView) {
        headerView=[[HeaderView alloc]initWithReuseIdentifier:@"Header_View"];
        headerView.delegate=self;
    }
    headerView.type=section ? HeaderTypeContacts :HeaderTypeTags;
    headerView.textLabel.text=section ? @"Contacts (...)":@"Tags (...)";
    return headerView;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    switch ([self cellTypeAtIndexPath:indexPath]) {
        case CellTypeContactCellNormal:
            return YES;
        case CellTypeTagCellNormal:
            return YES;
        default:
            return NO;
    }
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
    if (tableView.isEditing) {
        if (!(DisplayMoreTagCell && indexPath.row == 3)) {
            return;
        }
    }
    if (indexPath.section == 0) {
        if (DisplayMoreTagCell && indexPath.row == 3) {
            DisplayMoreTagCell=NO;
            NSMutableArray *indexPathsToInsert=[@[] mutableCopy];
            for (int row = 3; row < self.tags.count; row++) {
                [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:row inSection:0]];
            }
            [tableView beginUpdates];
            [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            [tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationBottom];
            [tableView endUpdates];
            return;
        }
        NSArray *indexPathsBeforeUpdate=[tableView indexPathsForRowsInRect:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), tableView.contentSize.height)];
        NSLog(@"cell counts:%@",indexPathsBeforeUpdate);

        Tag *tag=self.tags[indexPath.row];
        self.currentTag=tag;
        self.tags=[[tag.childrenTags allObjects] sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
            return [obj1.tagName compare:obj2.tagName];
        }];
        self.contacts=[[tag.directlyOwnedContacts allObjects] sortedArrayUsingComparator:^NSComparisonResult(Contact * obj1, Contact * obj2) {
            return [obj1.contactName compare:obj2.contactName];
        }];
        DisplayMoreTagCell=YES;

        NSArray *cellCountsAfterUpdate=@[@([self tableView:tableView numberOfRowsInSection:0]),@([self tableView:tableView numberOfRowsInSection:1])];
        NSLog(@"cell counts:%@",cellCountsAfterUpdate);

        [tableView beginUpdates];

        [tableView deleteRowsAtIndexPaths:indexPathsBeforeUpdate withRowAnimation:UITableViewRowAnimationLeft];
        for (int section =0 ; section<2; section++) {
            for (int row = 0; row<[cellCountsAfterUpdate[section] integerValue]; row++) {
                NSLog(@"section :%@,row:%@",@(section),@(row));
                [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:section]] withRowAnimation:UITableViewRowAnimationRight];
            }
        }
        [tableView endUpdates];
        [tableView reloadData];

    }
    else{
        Contact *contact=self.contacts[indexPath.row];
        self.tags=@[];
        self.contacts=[contact.relationsWithOtherPeople valueForKey:@"otherContact"];
        [tableView reloadData];
    }

}
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
// 必须实现该方法，edit action 才有效果
//    To enable the swipe-to-delete feature of table views (wherein a user swipes horizontally across a row to display a Delete button), you must implement this method
}
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {

    switch ([self cellTypeAtIndexPath:indexPath]) {
        case CellTypeAddNewContact:
            return nil;
        case CellTypeAddNewTag:
            return nil;
        case CellTypeShowMoreTag:
            return nil;
        case CellTypeContactCellNormal:{
            return @[self.deleteAction,self.shareAction,self.moreAction];
        }
        case CellTypeTagCellNormal:
            return @[self.deleteAction,self.renameAction,self.moreAction];
    }
}


-(UIImage *)thumbnailOfContact:(Contact *)contact{

    ABRecordRef person= ABAddressBookGetPersonWithRecordID(self.addressBook,(int32_t)contact.contactID.intValue);
    NSData *data=(__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
    UIImage *image=[UIImage imageWithData:data];
    return image;

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
//            NSLog(@"name:%@",[self nameOfPerson:recordRef]);
            [allPeopleRecordIDs addObject:@(recordID)];
            Contact *contact=[self contactOfRecord:recordRef];
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
            CFRelease(recordRef);
        }
        CFRelease(allPeopleRecords);
        // Remove the contacts in core data which are not included in the addressbook
        NSPredicate *removePredicator=[NSPredicate predicateWithFormat:@"NOT contactID IN %@",allPeopleRecordIDs];
        NSArray *objectsToBeRemoved=[allContactsInCoreData filteredArrayUsingPredicate:removePredicator];
        NSLog(@"objectsToBeRemoved:%@",objectsToBeRemoved);
        for (Contact * contact in objectsToBeRemoved) {
            [self.context deleteObject:contact];
        }

        self.currentTag=[self tagWithName:@"RootTag"];
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
