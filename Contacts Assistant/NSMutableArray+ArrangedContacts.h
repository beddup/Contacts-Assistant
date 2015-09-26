//
//  NSMutableArray+ArrangedContacts.h
//  Contacts Assistant
//
//  Created by Amay on 8/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"
@class  NSIndexPath;
@interface NSMutableArray (ArrangedContacts)

-(void)removeContactAtIndexPath:(NSIndexPath *)indexPath;
//-(void)removeContact:(Contact *)contact;

-(NSMutableArray *)contactsWhichHasPhones;
-(NSMutableArray *)contactsWhichHasEmail;


@end
