//
//  Event+Utility.m
//  Contacts Assistant
//
//  Created by Amay on 7/24/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "Event+Utility.h"
#import "Contact.h"
#import "defines.h"
#import <UIKit/UIKit.h>

@implementation Event (Utility)

-(NSDate *)nextEventDate{
    if (!self.eventRepeatedDays) {
        // no repeat days
        return self.eventDate;
    }

    //has repeat days
    NSCalendar *calendar=[NSCalendar currentCalendar];
    NSDate *now=[NSDate date];
    NSArray *repeatedWeekDays=[self.eventRepeatedDays componentsSeparatedByString:@","];
    NSDateComponents *dateComponents=[calendar components:NSCalendarUnitCalendar | NSCalendarUnitTimeZone | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.eventDate];

    NSDate *date=[calendar nextDateAfterDate:now matchingComponents:dateComponents options:NSCalendarMatchStrictly|NSCalendarMatchPreviousTimePreservingSmallerUnits];
    if (repeatedWeekDays.count == 7) {
        // eveyday event
        return date;
    }

    NSInteger todayWeekDay=[calendar component:NSCalendarUnitWeekday fromDate:now];
    for (int i=0; i<repeatedWeekDays.count;i++) {
        NSInteger weekDay=[repeatedWeekDays[i] integerValue];
        if (todayWeekDay > weekDay) {
            continue;
        }

        dateComponents.weekday=weekDay;
        NSDate *date=[calendar nextDateAfterDate:now matchingComponents:dateComponents options:NSCalendarMatchStrictly|NSCalendarMatchPreviousTimePreservingSmallerUnits];
        if (todayWeekDay < weekDay) {
            return date;
        }

        if ([calendar component:NSCalendarUnitDay fromDate:date]==[calendar component:NSCalendarUnitDay fromDate:now]) {
            // today
            return date;
        }
    }

    // next week
    dateComponents.weekday=[[repeatedWeekDays firstObject] integerValue];
    return [calendar nextDateAfterDate:now matchingComponents:dateComponents options:NSCalendarMatchStrictly|NSCalendarMatchPreviousTimePreservingSmallerUnits];


}
-(BOOL)passed{
    if ([[self nextEventDate] timeIntervalSinceNow] < 0) {
        return YES;
    }
    return NO;
}
-(NSString *)displayedEventString{
    NSMutableString *aevent=[self.eventDescription mutableCopy];
    [aevent replaceOccurrencesOfString:@"\n" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, aevent.length)];
    return [aevent copy];
}

-(void)scheduleLocalNotificationWithFireDate:(NSDate*)date RepeatInterval:(NSCalendarUnit)repeatInterval{

    NSString *alertBody=[NSString stringWithFormat:@"联系事项提醒(%@):\n%@",self.contactWhoOwnThisEvent.contactName,[self displayedEventString]];
    NSDictionary *userInfo=@{LocalNotificationUserInfoIDKey:self.eventID,LocalNotificationUserInfoDescriptionKey:alertBody};

    UILocalNotification *localNotification=[[UILocalNotification alloc]init];
    localNotification.soundName=UILocalNotificationDefaultSoundName;
    localNotification.repeatCalendar=[NSCalendar currentCalendar];
    localNotification.timeZone=[[NSCalendar currentCalendar]timeZone];
    localNotification.userInfo=userInfo;
    localNotification.alertBody=alertBody;
    localNotification.repeatInterval=repeatInterval;
    localNotification.fireDate=date;

    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

}

-(void)scheduleLocalNotification{
    // cancel existing local notification
    [self cancelLocalNotification];
    
    if (!self.eventDate) {
        return;
    }

    // if has eventDate , then schedule local notification
    if (!self.eventRepeatedDays) {
        // no repeat days
        [self scheduleLocalNotificationWithFireDate:self.eventDate RepeatInterval:0];
        return;
    }

    //has repeat days
    NSCalendar *calendar=[NSCalendar currentCalendar];
    NSArray *repeatedWeekDays=[self.eventRepeatedDays componentsSeparatedByString:@","];
    NSDateComponents *dateComponents=[calendar components:NSCalendarUnitCalendar | NSCalendarUnitTimeZone | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.eventDate];
    if (repeatedWeekDays.count == 7) {
        [self scheduleLocalNotificationWithFireDate:self.eventDate RepeatInterval:NSCalendarUnitDay];
    }
    for (NSString *weekDay in repeatedWeekDays) {
        dateComponents.weekday=[weekDay integerValue];
        NSDate *nextDate=[calendar nextDateAfterDate:[NSDate date] matchingComponents:dateComponents options:NSCalendarMatchStrictly|NSCalendarMatchPreviousTimePreservingSmallerUnits];
        [self scheduleLocalNotificationWithFireDate:nextDate RepeatInterval:NSCalendarUnitWeekday];
    }

}

-(void)cancelLocalNotification{

    for (UILocalNotification *localNotification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        NSDictionary *userInfo=localNotification.userInfo;
        if ([userInfo[LocalNotificationUserInfoIDKey] isEqualToNumber:self.eventID]) {
            [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
        }
    }
}
@end
