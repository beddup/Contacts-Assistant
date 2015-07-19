//
//  Contact.h
//  
//
//  Created by Amay on 7/16/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Relation, Tag;

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSString * contactName;
@property (nonatomic, retain) NSNumber * contactID;
@property (nonatomic, retain) NSSet *directUnderWhichTags;
@property (nonatomic, retain) NSSet *relationsWithOtherPeople;
@property (nonatomic, retain) NSSet *belongWhichRelations;
@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addDirectUnderWhichTagsObject:(Tag *)value;
- (void)removeDirectUnderWhichTagsObject:(Tag *)value;
- (void)addDirectUnderWhichTags:(NSSet *)values;
- (void)removeDirectUnderWhichTags:(NSSet *)values;

- (void)addRelationsWithOtherPeopleObject:(Relation *)value;
- (void)removeRelationsWithOtherPeopleObject:(Relation *)value;
- (void)addRelationsWithOtherPeople:(NSSet *)values;
- (void)removeRelationsWithOtherPeople:(NSSet *)values;

- (void)addBelongWhichRelationsObject:(Relation *)value;
- (void)removeBelongWhichRelationsObject:(Relation *)value;
- (void)addBelongWhichRelations:(NSSet *)values;
- (void)removeBelongWhichRelations:(NSSet *)values;

@end
