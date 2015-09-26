//
//  EventDisplayView.h
//  Contacts Assistant
//
//  Created by Amay on 8/10/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Event;
@interface EventDisplayView : UIView

@property(strong,nonatomic)Event *event;
@property(copy) void(^SMSToRelatedPeople)(NSArray *contacts);
@property(copy) void(^EmailToRelatedPeople)(NSArray *contacts);

-(NSDictionary *)eventDescriptionAttributes;
-(CGFloat)minHeightWithMaxWidth:(CGFloat)width;
@end
