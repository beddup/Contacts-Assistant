//
//  Contact.h
//  
//
//  Created by Amay on 9/17/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event, Relation, Tag;

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSNumber * contactID;
@property (nonatomic, retain) NSNumber * contactIsDeleted;
@property (nonatomic, retain) NSString * contactName;
@property (nonatomic, retain) NSNumber * contactOrderWeight;
@property (nonatomic, retain) NSSet *attendWhichEvents;
@property (nonatomic, retain) NSSet *belongWhichRelations;
@property (nonatomic, retain) NSSet *relationsWithOtherPeople;
@property (nonatomic, retain) NSSet *underWhichTags;
@property (nonatomic, retain) NSSet *ownedEvents;
@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addAttendWhichEventsObject:(Event *)value;
- (void)removeAttendWhichEventsObject:(Event *)value;
- (void)addAttendWhichEvents:(NSSet *)values;
- (void)removeAttendWhichEvents:(NSSet *)values;

- (void)addBelongWhichRelationsObject:(Relation *)value;
- (void)removeBelongWhichRelationsObject:(Relation *)value;
- (void)addBelongWhichRelations:(NSSet *)values;
- (void)removeBelongWhichRelations:(NSSet *)values;

- (void)addRelationsWithOtherPeopleObject:(Relation *)value;
- (void)removeRelationsWithOtherPeopleObject:(Relation *)value;
- (void)addRelationsWithOtherPeople:(NSSet *)values;
- (void)removeRelationsWithOtherPeople:(NSSet *)values;

- (void)addUnderWhichTagsObject:(Tag *)value;
- (void)removeUnderWhichTagsObject:(Tag *)value;
- (void)addUnderWhichTags:(NSSet *)values;
- (void)removeUnderWhichTags:(NSSet *)values;

- (void)addOwnedEventsObject:(Event *)value;
- (void)removeOwnedEventsObject:(Event *)value;
- (void)addOwnedEvents:(NSSet *)values;
- (void)removeOwnedEvents:(NSSet *)values;

@end
