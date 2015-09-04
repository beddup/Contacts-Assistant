//
//  NSMutableArray+ArrangedContacts.m
//  Contacts Assistant
//
//  Created by Amay on 8/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "NSMutableArray+ArrangedContacts.h"
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
//-(NSMutableArray *)indexTitlesInTableView{
//
//    NSMutableArray *indexTitles=[@[] mutableCopy];
//    for (int section=0; section<self.count; section++) {
//        NSArray *contactsInSection=self[section];
//        Contact *contact=[contactsInSection firstObject];
//        if (contact.contactOrderWeight.doubleValue != 0.0) {
//            [indexTitles addObject:@"☆"];
//        }else{
//            NSString *firstLetter=[self firstLetter:contact];
//            if (firstLetter) {
//                [indexTitles addObject:firstLetter];
//            }
//        }
//    }
//    return indexTitles;
//
//}

@end
