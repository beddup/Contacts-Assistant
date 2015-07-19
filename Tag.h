//
//  Tag.h
//  
//
//  Created by Amay on 7/15/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact, Tag;

@interface Tag : NSManagedObject

@property (nonatomic, retain) NSString * tagName;
@property (nonatomic, retain) NSNumber * tagID;
@property (nonatomic, retain) NSSet *directlyOwnedContacts;
@property (nonatomic, retain) NSSet *childrenTags;
@property (nonatomic, retain) Tag *parentTag;
@end

@interface Tag (CoreDataGeneratedAccessors)

- (void)addDirectlyOwnedContactsObject:(Contact *)value;
- (void)removeDirectlyOwnedContactsObject:(Contact *)value;
- (void)addDirectlyOwnedContacts:(NSSet *)values;
- (void)removeDirectlyOwnedContacts:(NSSet *)values;

- (void)addChildrenTagsObject:(Tag *)value;
- (void)removeChildrenTagsObject:(Tag *)value;
- (void)addChildrenTags:(NSSet *)values;
- (void)removeChildrenTags:(NSSet *)values;

@end
