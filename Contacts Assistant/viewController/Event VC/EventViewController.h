//
//  AddEventViewController.h
//  Contacts Assistant
//
//  Created by Amay on 7/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"
@protocol ContactDetailsUpdatingDelegate;

@protocol EventContentUpdatingDelegate <NSObject>

-(void)eventDateChanged:(NSDate *)eventDate repeatedDays:(NSArray *)repeatedDays;
-(void)eventRelatedPeopleChanged:(NSArray *)relatedPeople;

@end

@interface EventViewController : UIViewController<EventContentUpdatingDelegate>

@property(strong,nonatomic) Event * event;

@property(nonatomic)BOOL forDisplay;
@property(weak,nonatomic)id<ContactDetailsUpdatingDelegate>delegate;

@end
