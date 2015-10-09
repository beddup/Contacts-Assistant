//
//  Tag.h
//  Contacts Assistant
//
//  Created by Amay on 8/7/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface Tag : NSManagedObject

@property (nonatomic, retain) NSNumber * tagID;
@property (nonatomic, retain) NSString * tagName;
@property (nonatomic, retain) NSSet *ownedContacts;
@end

@interface Tag (CoreDataGeneratedAccessors)

- (void)addOwnedContactsObject:(Contact *)value;
- (void)removeOwnedContactsObject:(Contact *)value;
- (void)addOwnedContacts:(NSSet *)values;
- (void)removeOwnedContacts:(NSSet *)values;

@end
