//
//  NSMutableArray+ArrangedContacts.m
//  Contacts Assistant
//
//  Created by Amay on 8/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "NSMutableArray+ArrangedContacts.h"
#import "Contact+Utility.h"
#import <UIKit/UITableView.h>

@implementation NSMutableArray (ArrangedContacts)

-(void)removeContactAtIndexPath:(NSIndexPath *)indexPath{

    Contact *contact= self[indexPath.section][indexPath.row];
    contact.contactIsDeleted=@(YES);
    NSMutableArray *subContacts=self[indexPath.section];
    [subContacts removeObjectAtIndex:indexPath.row];
    if (!subContacts.count) {
        [self removeObjectAtIndex:indexPath.section];
    }
}

-(NSMutableArray *)contactsWhichHasPhones{
    return [self contactsWhichHasContactInfo:YES];
}
-(NSMutableArray *)contactsWhichHasEmail{
    return [self contactsWhichHasContactInfo:NO];
}

-(NSMutableArray *)contactsWhichHasContactInfo:(BOOL)hasPhone{
    NSMutableArray *array=[@[] mutableCopy];

    for (int section = 0; section < self.count; section++) {
        NSMutableArray *subArray=[@[] mutableCopy];
        NSMutableArray *sectionArray=self[section];
        for (int row=0 ; row < sectionArray.count; row++) {
            Contact *contact = sectionArray[row];
            BOOL hasContactInfo=hasPhone ?  [contact hasPhone] : [contact hasEmail];
            if (hasContactInfo) {
                [subArray addObject:contact];
            }
        }
        if (subArray.count > 0) {
            [array addObject:subArray];
        }
    }
    return array;


}

@end
