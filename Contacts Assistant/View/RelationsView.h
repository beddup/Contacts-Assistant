//
//  RelationsView.h
//  Contacts Assistant
//
//  Created by Amay on 8/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Contact,Relation;

@protocol RelationsViewDelegate <NSObject>

-(void)dismissRelationBetween:(Contact *)contact otherContact:(Contact *)otherContact;
-(void)showAllContactsWhoHaveSameTagWithContact:(Contact *)contact;

@end
@interface RelationsView : UIView

@property(strong,nonatomic)Contact *contact;

@property(weak,nonatomic)id<RelationsViewDelegate>delegate;

-(void)relationDeleted:(Relation *)relation;

-(void)update;
@end
