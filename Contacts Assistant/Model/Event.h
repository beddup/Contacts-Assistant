//
//  Event.h
//  
//
//  Created by Amay on 9/17/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSDate * eventDate;
@property (nonatomic, retain) NSString * eventDescription;
@property (nonatomic, retain) NSNumber * eventID;
@property (nonatomic, retain) NSString * eventPlace;
@property (nonatomic, retain) NSString * eventRepeatedDays;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longtitude;
@property (nonatomic, retain) NSNumber * finished;
@property (nonatomic, retain) NSSet *otherContacts;
@property (nonatomic, retain) Contact *contactWhoOwnThisEvent;
@end

@interface Event (CoreDataGeneratedAccessors)

- (void)addOtherContactsObject:(Contact *)value;
- (void)removeOtherContactsObject:(Contact *)value;
- (void)addOtherContacts:(NSSet *)values;
- (void)removeOtherContacts:(NSSet *)values;

@end
