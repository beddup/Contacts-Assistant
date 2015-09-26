//
//  Event+Utility.h
//  Contacts Assistant
//
//  Created by Amay on 7/24/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "Event.h"

@interface Event (Utility)

-(NSDate *)nextEventDate;
-(BOOL)passed;
-(NSString *)displayedEventString;

-(void)scheduleLocalNotification;
-(void)cancelLocalNotification;
@end
