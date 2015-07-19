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
#import <AddressBook/AddressBook.h>

#import <CoreData/CoreData.h>

NSString *const FetchResultContactsKey=@"Contacts";
NSString *const FetchResultTagsKey=@"Tags";
NSString *const ContactManagerDidFinishUpdatingCoreData=@"ContactManagerDidFinishUpdatingCoreData";

@interface ContactsManager()

@property(weak,nonatomic)NSManagedObjectContext *context;
@property(strong,nonatomic)NSManagedObject *LatestFetchedObject;
@property(strong,nonatomic)NSArray *allContacts;
@property(nonatomic,assign)ABAddressBookRef addressBook;

@property(strong,nonatomic)id currentNode;// tag or contact
@property(strong,nonatomic)NSArray *tagElementsUnderCurrentNode;
@property(strong,nonatomic)NSArray *contactElementsUnderCurrentNode;


@end

@implementation ContactsManager
@synthesize currentNode=_currentNode;
#pragma mark - ContactNetViewDatasource
-(id)currentNode{
    if (!_currentNode) {
        _currentNode=[self tagWithName:@"RootTag"];
    }
    return _currentNode;
}
-(void)setCurrentNode:(id)currentNode{
    _currentNode=currentNode;
    self.tagElementsUnderCurrentNode=nil;
    self.contactElementsUnderCurrentNode=nil;
}
-(NSArray *)tagElementsUnderCurrentNode{
    if (!_tagElementsUnderCurrentNode && [self.currentNode isKindOfClass:[Tag class]]) {
        _tagElementsUnderCurrentNode=[((Tag*)self.currentNode).childrenTags allObjects];
    }
    return _tagElementsUnderCurrentNode;
}
-(NSArray *)contactElementsUnderCurrentNode{
    if (!_contactElementsUnderCurrentNode) {
        if ([self.currentNode isKindOfClass:[Tag class]]) {
            _contactElementsUnderCurrentNode=[((Tag *)self.currentNode).directlyOwnedContacts allObjects];

        }else if ([self.currentNode isKindOfClass:[Contact class]]){
            _contactElementsUnderCurrentNode=[((Contact *)self.currentNode).relationsWithOtherPeople allObjects];
        }
    }
    return _contactElementsUnderCurrentNode;
}

-(NSUInteger)numberOfTopElements{
    return 0;
}
-(NSString *)nameOfTopElement:(NSUInteger)topElementIndex{
    if ([self.currentNode isKindOfClass:[Tag class]]) {
        return ((Tag *)self.currentNode).tagName;
    }
    else if ([self.currentNode isKindOfClass:[Contact class]]){
        return ((Contact *)self.currentNode).contactName;
    }
    return @"我";
}
-(ElementViewType)typeOfTopElement:(NSUInteger)topElementIndex{
    if ([self.currentNode isKindOfClass:[Tag class]]) {
        return ElementViewTypeTag;
    }
    else if ([self.currentNode isKindOfClass:[Contact class]]){
        return ElementViewTypeContact;
    }
    return ElementViewTypeOwner;

}
-(UIImage *)imageOfTopElement:(NSUInteger)topElementIndex{
    if ([self.currentNode isKindOfClass:[Contact class]]){
        Contact *contact=(Contact *)self.currentNode;
        return [self thumbnailOfContact:contact];
    }
    return nil;

}

-(NSUInteger)numberOfElementsUnderTopElement:(NSUInteger)topElementIndex{

    return self.tagElementsUnderCurrentNode.count+self.contactElementsUnderCurrentNode.count;

}
-(NSString *)nameOfElement:(NSUInteger)elementIndex underTopElement:(NSUInteger)topElementIndex{
    if (elementIndex < self.tagElementsUnderCurrentNode.count) {
        Tag *tag=self.tagElementsUnderCurrentNode[elementIndex];
        return tag.tagName;
    }else{
        id element=self.contactElementsUnderCurrentNode[elementIndex-self.tagElementsUnderCurrentNode.count];
        if ([element isKindOfClass:[Contact class]]) {
            return ((Contact *)element).contactName;
        }else if ([element isKindOfClass:[Relation class]]){
            return ((Relation *)element).otherContact.contactName;
        }
        return nil;
    }
}
-(ElementViewType)typeOfElement:(NSUInteger)elementIndex underTopElement:(NSUInteger)topElementIndex{

    if (elementIndex<self.tagElementsUnderCurrentNode.count) {
        return ElementViewTypeTag;
    }else{
        return ElementViewTypeContact;
    }

}
-(UIImage *)imageOfElement:(NSUInteger)elementIndex underTopElement:(NSUInteger)topElementIndex{

    if (elementIndex >= self.tagElementsUnderCurrentNode.count) {
        id element=self.contactElementsUnderCurrentNode[elementIndex-self.tagElementsUnderCurrentNode.count];
        if ([element isKindOfClass:[Contact class]]) {
            return [self thumbnailOfContact:(Contact *)element];
        }else if ([element isKindOfClass:[Relation class]]){
            return [self thumbnailOfContact:((Relation *)element).otherContact];
        }
    }
    return nil;
}

-(NSString *)relationOfElementAtIndex:(NSUInteger)index1 isElementAtIndex:(NSUInteger)index2{
    return nil;
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
