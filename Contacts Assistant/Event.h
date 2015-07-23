//
//  Event.h
//  
//
//  Created by Amay on 7/24/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSString * event;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSSet *contactsWhichAttend;
@end

@interface Event (CoreDataGeneratedAccessors)

- (void)addContactsWhichAttendObject:(Contact *)value;
- (void)removeContactsWhichAttendObject:(Contact *)value;
- (void)addContactsWhichAttend:(NSSet *)values;
- (void)removeContactsWhichAttend:(NSSet *)values;

@end
