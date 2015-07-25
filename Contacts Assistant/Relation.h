//
//  Relation.h
//  Contacts Assistant
//
//  Created by Amay on 7/24/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface Relation : NSManagedObject

@property (nonatomic, retain) NSString * relationName;
@property (nonatomic, retain) Contact *otherContact;
@property (nonatomic, retain) Contact *whoseRelation;

@end
