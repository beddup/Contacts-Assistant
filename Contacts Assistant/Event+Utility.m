//
//  Event+Utility.m
//  Contacts Assistant
//
//  Created by Amay on 7/24/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "Event+Utility.h"

@implementation Event (Utility)

-(NSDate *)nextdate{
    if (!self.repeatedDays) {
        return self.date;
    }

    NSDate *now=[NSDate date];
    NSCalendar *calendar=[NSCalendar currentCalendar];

    NSArray *repeatedDayIndexes=[[self.repeatedDays componentsSeparatedByString:@","] valueForKey:@"integerValue"];

    NSInteger weekday=[calendar component:NSCalendarUnitWeekday fromDate:now]-1;

    NSLog(@"%@",repeatedDayIndexes);
    NSLog(@"%@",@(weekday));

    NSInteger hourValuePointer;
    NSInteger minuteValuePointer;
    NSInteger secondValuePointer;
    [calendar getHour:&hourValuePointer minute:&minuteValuePointer second:&secondValuePointer nanosecond:NULL fromDate:self.date];

    NSInteger eraValuePointer;
    NSInteger yearValuePointer;
    NSInteger monthValuePointer;
    NSInteger dayValuePointer;
    [calendar getEra:&eraValuePointer year:&yearValuePointer month:&monthValuePointer day:&dayValuePointer fromDate:now];

    NSDate *todayTime=[calendar dateWithEra:eraValuePointer year:yearValuePointer month:monthValuePointer day:dayValuePointer hour:hourValuePointer minute:minuteValuePointer second:secondValuePointer nanosecond:0];

    if ([repeatedDayIndexes containsObject:@(weekday)] && [now timeIntervalSinceDate:todayTime] < 15*60) {
        return todayTime;
    }

    NSInteger increment=0;
    while (1) {
        weekday = weekday +1;
        increment ++;
        if (weekday == 7 ) {
            weekday =0;
        }

        if ([repeatedDayIndexes containsObject:@(weekday)]) {
            break;
        }
    }
    NSDate *date=[NSDate dateWithTimeInterval:increment*24*60*60 sinceDate:todayTime];
    return date;

}
-(BOOL)passed{
    if ([self.date timeIntervalSinceNow] < 0) {
        return YES;
    }
    return NO;
}



@end
