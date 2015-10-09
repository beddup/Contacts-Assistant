//
//  EventDisplayView.m
//  Contacts Assistant
//
//  Created by Amay on 8/10/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "EventDisplayView.h"
#import "Event+Utility.h"
#import "NSString+ContactsAssistant.h"
#import "defines.h"
@interface EventDisplayView()

@property(strong,nonatomic) NSAttributedString *attributedEventDescription;
@property(strong,nonatomic)NSAttributedString *attributedDateString;
@property(strong,nonatomic)NSAttributedString *attributedRepeatedDaysString;
@property(strong,nonatomic)NSAttributedString *attributedPeopleString;

@property(weak,nonatomic)UIButton *groupSMSButton;
@property(weak,nonatomic)UIButton *groupEmailButton;


@end

@implementation EventDisplayView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
-(void)setEvent:(Event *)event{
    _event=event;

    UIFont *detailFont=[UIFont systemFontOfSize:14 weight:UIFontWeightLight];
    UIColor *detailColor=[UIColor lightGrayColor];
    if (event.eventDescription) {
        self.attributedEventDescription=[[NSAttributedString alloc]initWithString:event.eventDescription attributes:[self eventDescriptionAttributes]];
    }
    if (event.eventDate) {
        NSString *dateString=[NSDateFormatter localizedStringFromDate:event.eventDate
                                                            dateStyle:event.eventRepeatedDays ? NSDateFormatterNoStyle:NSDateFormatterMediumStyle
                                                            timeStyle:NSDateFormatterShortStyle];
        self.attributedDateString=[[NSAttributedString alloc]initWithString:dateString attributes:@{NSFontAttributeName:detailFont,NSForegroundColorAttributeName:detailColor}];
    }
    if (event.eventRepeatedDays) {
        //draw event repeated days
        NSArray *repeatedDays=[event.eventRepeatedDays componentsSeparatedByString:@","];
        NSString *repeatedDaysString=[NSString repeatedDaySymbols:repeatedDays];
        self.attributedRepeatedDaysString=[[NSAttributedString alloc]initWithString:repeatedDaysString attributes:@{NSForegroundColorAttributeName:detailColor,NSFontAttributeName:[UIFont systemFontOfSize:10 weight:UIFontWeightLight]}];
    }
    if (event.otherContacts.count) {
        // draw related people
        NSString *peopleString=[[[event.otherContacts allObjects] valueForKey:@"contactName"] componentsJoinedByString:@", "];
        self.attributedPeopleString=[[NSAttributedString alloc]initWithString:peopleString attributes:@{NSFontAttributeName:detailFont,NSForegroundColorAttributeName:detailColor}];
    }

    self.groupEmailButton.hidden=!self.event.otherContacts.count;
    self.groupSMSButton.hidden=!self.event.otherContacts.count;

    [self setNeedsDisplay];
}
#pragma mark - attributes
-(NSParagraphStyle *)eventDescriptionParaStyle{
    NSMutableParagraphStyle *paraStyle=[[NSMutableParagraphStyle alloc]init];
    paraStyle.lineSpacing=1;
    paraStyle.paragraphSpacing=2;
    return paraStyle;

}
-(NSDictionary *)eventDescriptionAttributes{
    return @{NSParagraphStyleAttributeName:[self eventDescriptionParaStyle],NSFontAttributeName:[UIFont systemFontOfSize:17 weight:UIFontWeightLight]};
}

#pragma mark - geometry calculate
-(CGFloat)minHeightWithMaxWidth:(CGFloat)width{

    CGFloat descriptionAreaHeight=16+CGRectGetHeight([self boundsOfAttributedString:self.attributedEventDescription maxWidth:width])+20;
    CGFloat peopleStringAreaHeight=CGRectGetHeight([self boundsOfAttributedString:self.attributedPeopleString maxWidth:width]);
    CGFloat dateStringAreaHeight=self.attributedDateString.size.height+8;
    CGFloat repeatedDaysString=self.attributedRepeatedDaysString.size.height+16;

    CGFloat buttonAreaHeight=self.event.otherContacts.count ? 96 : 0;

    return descriptionAreaHeight+peopleStringAreaHeight+dateStringAreaHeight+repeatedDaysString+buttonAreaHeight;

}
-(CGRect)boundsOfAttributedString:(NSAttributedString *)attributedString maxWidth:(CGFloat)maxWidth{

    CGFloat contentXOffSet=8;
    CGRect boundingRect=[attributedString
                         boundingRectWithSize:CGSizeMake(maxWidth-2*contentXOffSet, 0)
                         options:NSStringDrawingUsesLineFragmentOrigin
                         context:nil];
    return boundingRect;
}

#pragma mark - draw
- (void)drawRect:(CGRect)rect {
    // Drawing code

    CGRect contentRect= CGRectInset(rect, 8, 16);
    CGFloat minY= CGRectGetMinY(contentRect);
    CGFloat minX=CGRectGetMinX(contentRect);
    CGFloat maxWidth=CGRectGetWidth(rect);

    // draw event content
    if (self.event.eventDescription) {
        CGRect boundingRect=[self boundsOfAttributedString:self.attributedEventDescription maxWidth:maxWidth];
        CGRect desRect=CGRectMake(minX, minY, CGRectGetWidth(boundingRect), CGRectGetHeight(boundingRect));
        [self.attributedEventDescription drawWithRect:desRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        minY += CGRectGetHeight(boundingRect)+20;
    }

    if (self.event.eventDate) {
        [self.attributedDateString drawAtPoint:CGPointMake(minX, minY)];
        minY += self.attributedDateString.size.height;

        if (self.event.eventRepeatedDays) {
            [self.attributedRepeatedDaysString drawAtPoint:CGPointMake(minX, minY)];
            minY += self.attributedRepeatedDaysString.size.height;
        }
        minY +=8;
    }
    if (self.event.otherContacts.count) {
        // draw related people
        CGRect boundingRect=[self boundsOfAttributedString:self.attributedPeopleString maxWidth:maxWidth];
        CGRect peopleRect=CGRectMake(minX, minY, CGRectGetWidth(boundingRect), CGRectGetHeight(boundingRect));

        [self.attributedPeopleString drawWithRect:peopleRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        minY+=CGRectGetHeight(peopleRect)+8;
        //
        UIBezierPath *smsLine=[UIBezierPath bezierPath];
        [smsLine moveToPoint:CGPointMake(minX, minY+48)];
        [smsLine addLineToPoint:CGPointMake(CGRectGetMaxX(rect),minY+48)];
        [[UIColor lightGrayColor] setStroke];
        smsLine.lineWidth=0.5;
        [smsLine stroke];
        self.groupSMSButton.frame=CGRectMake(minX+2, minY, CGRectGetWidth(rect)/3, 44);

        minY+=48;
        UIBezierPath *emailLine=[UIBezierPath bezierPath];
        [emailLine moveToPoint:CGPointMake(minX, minY+48)];
        [emailLine addLineToPoint:CGPointMake(CGRectGetMaxX(rect),minY+48)];
        [[UIColor lightGrayColor] setStroke];
        emailLine.lineWidth=0.5;
        [emailLine stroke];
        self.groupEmailButton.frame=CGRectMake(minX+2, minY, CGRectGetWidth(rect)/3, 44);

    }
}
-(void)groupSMS:(UIButton *)button{
    self.SMSToRelatedPeople([[self.event.otherContacts allObjects] arrayByAddingObject:self.event.contactWhoOwnThisEvent]);
}

-(void)groupEmail:(UIButton *)button{
    self.EmailToRelatedPeople([[self.event.otherContacts allObjects] arrayByAddingObject:self.event.contactWhoOwnThisEvent]);
}

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{
    self.backgroundColor=[UIColor clearColor];
    self.userInteractionEnabled=YES;
    UIButton *groupSMS=[[UIButton alloc]init];
    [groupSMS setTitle:@"群发短信" forState:UIControlStateNormal];
    [groupSMS setTitleColor:IconColor forState:UIControlStateNormal];
    groupSMS.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;
    groupSMS.contentVerticalAlignment=UIControlContentVerticalAlignmentBottom;
    self.groupSMSButton=groupSMS;
    [self addSubview:groupSMS];
    [groupSMS addTarget:self action:@selector(groupSMS:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *groupEmail=[[UIButton alloc]init];
    [groupEmail setTitle:@"群发邮件" forState:UIControlStateNormal];
    [groupEmail setTitleColor:IconColor forState:UIControlStateNormal];
    groupEmail.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;
    groupEmail.contentVerticalAlignment=UIControlContentVerticalAlignmentBottom;
    self.groupEmailButton=groupEmail;
    [self addSubview:groupEmail];
    [groupEmail addTarget:self action:@selector(groupEmail:) forControlEvents:UIControlEventTouchUpInside];

}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}


@end
