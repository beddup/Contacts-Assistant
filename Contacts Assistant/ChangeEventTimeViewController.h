//
//  ChangeEventTimeViewController.h
//  Contacts Assistant
//
//  Created by Amay on 8/1/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

@protocol EventContentUpdatingDelegate;

@interface ChangeEventTimeViewController : UIViewController

@property(strong,nonatomic)NSDate *date;
@property(strong,nonatomic)NSMutableArray *repeatedDays;

@property(weak,nonatomic)id<EventContentUpdatingDelegate>delegate;

@end
