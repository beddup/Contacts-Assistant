//
//  RelationsView.h
//  Contacts Assistant
//
//  Created by Amay on 8/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Contact,Relation;
@interface RelationsView : UIView

@property(strong,nonatomic)Contact *contact;

@property(copy) void(^relationSelected)(Contact *contact, Contact *otherContact);
@property(copy) void(^sameTagContactsSelected)(Contact *contact);

-(void)relationDeleted:(Relation *)relation;
-(void)updateRelationViews;
@end
