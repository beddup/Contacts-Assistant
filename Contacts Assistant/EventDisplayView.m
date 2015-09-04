//
//  EventDisplayView.m
//  Contacts Assistant
//
//  Created by Amay on 8/10/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "EventDisplayView.h"
#import "Event.h"
@implementation EventDisplayView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
-(void)setEvent:(Event *)event{
    _event=event;
    [self setNeedsDisplay];
}

-(NSParagraphStyle *)eventDescriptionParaStyle{
    NSMutableParagraphStyle *paraStyle=[[NSMutableParagraphStyle alloc]init];
    paraStyle.lineSpacing=1;
    paraStyle.paragraphSpacing=2;
    return paraStyle;

}
-(NSDictionary *)eventDescriptionAttributes{
    return @{NSParagraphStyleAttributeName:[self eventDescriptionParaStyle],NSFontAttributeName:[UIFont systemFontOfSize:17 weight:UIFontWeightLight]};
}

- (void)drawRect:(CGRect)rect {
    // Drawing code

    CGRect contentRect= CGRectInset(rect, 8, 16);
    CGFloat minY= CGRectGetMinY(contentRect);
    CGFloat minX=CGRectGetMinX(contentRect);


    // draw event content
    if (self.event.event) {
        NSAttributedString *eventAttributedDescription=[[NSAttributedString alloc]initWithString:self.event.event attributes:[self eventDescriptionAttributes]];
        CGRect boundingRect=[eventAttributedDescription
                             boundingRectWithSize:CGSizeMake(CGRectGetWidth(contentRect), CGRectGetHeight(contentRect))
                             options:NSStringDrawingUsesLineFragmentOrigin
                             context:nil];
        CGRect desRect=CGRectMake(minX, minY, CGRectGetWidth(boundingRect), CGRectGetHeight(boundingRect));
        [eventAttributedDescription drawWithRect:desRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        minY += CGRectGetHeight(boundingRect)+20;
    }

    UIFont *detailFont=[UIFont systemFontOfSize:14 weight:UIFontWeightLight];
    UIColor *detailColor=[UIColor lightGrayColor];
    if (self.event.date) {
        // draw event date
        NSString *dateString=[NSDateFormatter localizedStringFromDate:self.event.date
                                                            dateStyle:self.event.repeatedDays ? NSDateFormatterNoStyle:NSDateFormatterMediumStyle
                                                            timeStyle:NSDateFormatterMediumStyle];
        NSAttributedString *attributedDateString=[[NSAttributedString alloc]initWithString:dateString attributes:@{NSFontAttributeName:detailFont,NSForegroundColorAttributeName:detailColor}];
        [attributedDateString drawAtPoint:CGPointMake(minX, minY)];
        minY += attributedDateString.size.height;

        if (self.event.repeatedDays) {
            //draw event repeated days
            NSString *repeatedDaysString;
            NSArray *repeatedDayIndexes=[[self.event.repeatedDays componentsSeparatedByString:@","] valueForKey:@"integerValue"];
            if (repeatedDayIndexes.count < 7) {
                NSArray *weekSymbols=[[NSCalendar currentCalendar]weekdaySymbols];
                NSMutableArray *symbols=[@[] mutableCopy];
                for (NSNumber * index in repeatedDayIndexes) {
                    [symbols addObject:weekSymbols[index.integerValue]];
                }
                repeatedDaysString=[symbols componentsJoinedByString:@","];

            }else{
                repeatedDaysString=@"每天";
            }
            NSAttributedString *attributedRepeatedDaysString=[[NSAttributedString alloc]initWithString:repeatedDaysString attributes:@{NSForegroundColorAttributeName:detailColor,NSFontAttributeName:[UIFont systemFontOfSize:10 weight:UIFontWeightLight]}];
            [attributedRepeatedDaysString drawAtPoint:CGPointMake(minX, minY)];
            minY += attributedRepeatedDaysString.size.height;
        }
        minY +=8;
    }

    if (self.event.place) {
        //draw event place
        NSAttributedString *attributedPlaceString=[[NSAttributedString alloc]initWithString:self.event.place attributes:@{NSFontAttributeName:detailFont,NSForegroundColorAttributeName:detailColor}];
        CGRect boundingRect=[attributedPlaceString boundingRectWithSize:CGSizeMake(CGRectGetWidth(contentRect), CGRectGetHeight(contentRect)) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        [attributedPlaceString drawWithRect:CGRectOffset(boundingRect, 8, minY) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        minY += CGRectGetHeight(boundingRect)+8;
    }
    if (self.event.contactsWhichAttend.count) {
        // draw related people
        NSString *peopleString=[[[self.event.contactsWhichAttend allObjects] valueForKey:@"contactName"] componentsJoinedByString:@", "];
        NSAttributedString *attributedPeopleString=[[NSAttributedString alloc]initWithString:peopleString attributes:@{NSFontAttributeName:detailFont,NSForegroundColorAttributeName:detailColor,NSParagraphStyleAttributeName:[self eventDescriptionParaStyle]}];
        CGRect boundingRect=[attributedPeopleString boundingRectWithSize:CGSizeMake(CGRectGetWidth(contentRect), CGRectGetHeight(contentRect)) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        [attributedPeopleString drawWithRect:CGRectOffset(boundingRect, 8, minY) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    }
}
#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{
    self.backgroundColor=[UIColor clearColor];
}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}


@end
