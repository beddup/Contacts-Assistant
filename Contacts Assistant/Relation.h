//
//  Relation.h
//  
//
//  Created by Amay on 7/15/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface Relation : NSManagedObject

@property (nonatomic, retain) NSString * relationName;
@property (nonatomic, retain) Contact *whoseRelation;
@property (nonatomic, retain) Contact *otherContact;

@end
