//
//  Event.h
//  Contacts Assistant
//
//  Created by Amay on 8/7/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * event;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longtitude;
@property (nonatomic, retain) NSString * place;
@property (nonatomic, retain) NSString * repeatedDays;
@property (nonatomic, retain) NSSet *contactsWhichAttend;
@end

@interface Event (CoreDataGeneratedAccessors)

- (void)addContactsWhichAttendObject:(Contact *)value;
- (void)removeContactsWhichAttendObject:(Contact *)value;
- (void)addContactsWhichAttend:(NSSet *)values;
- (void)removeContactsWhichAttend:(NSSet *)values;

@end
