//
//  ContactView.m
//  Contacts Assistant
//
//  Created by Amay on 7/17/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ContactCell.h"
#import "Contact+Utility.h"
#import "Event.h"

static NSString *const ButtonKeyPhone=@"ButtonKeyPhone";
static NSString *const ButtonKeySMS=@"ButtonKeySMS";
static NSString *const ButtonKeyEmail=@"ButtonKeyEmail";

@interface ContactCell()

@property(strong,nonatomic)NSDictionary *availabelSNS;

@property(strong,nonatomic)NSDictionary *availabelCommuniations;

@property(weak,nonatomic)UIButton *phoneButton;

@property(weak,nonatomic)UIButton *smsButton;

@property(weak,nonatomic)UIButton *emailButton;

@property(weak,nonatomic)UIButton *addEventButton;

@property(weak,nonatomic)UIButton *eventDetailButton;


@property(strong,nonatomic)NSArray *eventsStrings ; //of NSString;
@property(strong,nonatomic)NSArray *event; //of Events

@end

@implementation ContactCell
#pragma mark - properties


-(void)setContact:(Contact *)contact{
    _contact=contact;


    self.event = [[_contact.attendWhichEvents allObjects] sortedArrayUsingComparator:^NSComparisonResult(Event * obj1, Event * obj2) {
        return [obj1.date compare:obj2.date];
    }];

    self.eventsStrings=[self.event valueForKey:@"event"] ;

    [self checkAvailableCommunications];

    [self checkAvailableSNS];

    [self setNeedsDisplay];

}
-(void)checkAvailableCommunications{

    NSDictionary *availabelCommuniations=[self.contact avaibleCommunications];

    NSArray *allKeys=availabelCommuniations.allKeys;
    NSLog(@"self:%@,all keys:%@",self.contact.contactName, allKeys);
    BOOL hasPhone=[allKeys containsObject:CommunicationPhones];
    self.phoneButton.hidden=!hasPhone;
    self.smsButton.hidden=!hasPhone;

    BOOL hasEmail=[allKeys containsObject:CommunicationEmails];
    self.emailButton.hidden=!hasEmail;
    [self setNeedsDisplay];

}
-(void)checkAvailableSNS{
  // check sns
}
-(void)phone:(UIButton *)button{
    NSLog(@"phone");
}

-(void)SMS:(UIButton *)button{
    NSLog(@"SMS");

}

-(void)email:(UIButton *)button{
    NSLog(@"email");
}
-(void)addEvent:(UIButton *)button{
    NSLog(@"add event");
}
-(void)displayEvent:(UIButton *)button{
    NSLog(@"display event");

}
static CGFloat const ContentInsetX=4;
static CGFloat const ContentInsetY=4;


-(void)drawRect:(CGRect)rect{
    CGRect contentRect=CGRectInset(rect, ContentInsetX, ContentInsetY);

    // draw content area
    UIBezierPath *roundedRectPath=[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:3];
    [[UIColor lightGrayColor]setFill];
    [roundedRectPath fill];
    [roundedRectPath addClip];

    // draw Name
    NSAttributedString *contactName=[[NSAttributedString alloc]initWithString:self.contact.contactName ? self.contact.contactName : @"Unknow" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}];
    CGRect contactNameRect;
    contactNameRect.origin=CGPointMake(CGRectGetMinX(contentRect)+12, CGRectGetMinY(contentRect)+8);
    contactNameRect.size=contactName.size;
    [contactName drawInRect:contactNameRect];

    //draw department
    NSString *companyString=[self.contact companyAndDepartment];
    if (companyString) {
        NSAttributedString *companyAndDepartment=[[NSAttributedString alloc]initWithString:companyString
                                                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightLight],
                                                                                             NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
        NSLog(@"companyAndDepartment:%@",companyString);
        CGRect companyAndDepartmentRect;
        companyAndDepartmentRect.origin=CGPointMake(CGRectGetMaxX(contactNameRect)+8,CGRectGetMidY(contactNameRect)-companyAndDepartment.size.height/2);
        companyAndDepartmentRect.size=companyAndDepartment.size;
        [companyAndDepartment drawInRect:companyAndDepartmentRect];
    }

    // draw buttons
    CGRect buttonRect=CGRectMake(CGRectGetMinX(contactNameRect), CGRectGetMaxY(contactNameRect)+8, 44, 44);
    if (!self.phoneButton.hidden) {
        self.phoneButton.frame=buttonRect;
        buttonRect=CGRectOffset(buttonRect, 44, 0);
    }
    if (!self.smsButton.hidden) {
        self.smsButton.frame=buttonRect;
        buttonRect=CGRectOffset(buttonRect, 44, 0);
    }
    if (!self.emailButton.hidden) {
        self.emailButton.frame=buttonRect;
    }
    if (self.phoneButton.hidden && self.emailButton.hidden && self.smsButton.hidden) {
        NSAttributedString *noWayToContact=[[NSAttributedString alloc]initWithString:@"无联系方式"
                                                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightLight],
                                                                                             NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
        [noWayToContact drawAtPoint:buttonRect.origin];
    }
    self.eventDetailButton.frame=CGRectMake(CGRectGetMinX(contactNameRect), CGRectGetMaxY(buttonRect), CGRectGetWidth(contentRect)-24-70, 36);
    self.addEventButton.frame=CGRectMake(CGRectGetWidth(contentRect)-70, CGRectGetMaxY(buttonRect), 70, 36);
    // draw event
    CGRect indicatorCirleRect=CGRectMake(CGRectGetMinX(contactNameRect), CGRectGetMidY(self.addEventButton.frame)-4, 8, 8);
    UIBezierPath *cirle=[UIBezierPath bezierPathWithOvalInRect:indicatorCirleRect];

    NSString *eventString;
    if (self.eventsStrings.count) {
        [[UIColor orangeColor]setFill];
        eventString=[self.eventsStrings firstObject];
    }else{
        [[UIColor darkGrayColor]setFill];
        eventString=@"没有与之相关的事项";
    }
    [cirle fill];

    NSAttributedString *eventAS=[[NSAttributedString alloc]initWithString:eventString
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightLight],
                                                                                       NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
    CGRect eventASRect;
    eventASRect.size=CGSizeMake(CGRectGetWidth(contentRect)-60, 36);
    eventASRect.origin=CGPointMake(CGRectGetMaxX(indicatorCirleRect)+8, CGRectGetMidY(self.addEventButton.frame)-eventAS.size.height/2);
    [eventAS drawInRect:eventASRect];



//    UIBezierPath *centerLine=[UIBezierPath bezierPath];
//    [centerLine moveToPoint:CGPointMake(CGRectGetMinX(contentRect)+12, CGRectGetMidY(contentRect))];
//    [centerLine addLineToPoint:CGPointMake(CGRectGetMaxX(contentRect)-12, CGRectGetMidY(contentRect))];
//    [centerLine closePath];
//    [[UIColor whiteColor]setStroke];
//    [centerLine stroke];
}
#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.backgroundColor=[UIColor clearColor];

    UIButton *phoneButton=[[UIButton alloc]init];
    [self addSubview:phoneButton];
    self.phoneButton=phoneButton;
    self.phoneButton.hidden=YES;
    [phoneButton setBackgroundImage:[UIImage imageNamed:@"phone"] forState:UIControlStateNormal];
    [phoneButton addTarget:self action:@selector(phone:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *smsButton=[[UIButton alloc]init];
    [self addSubview:smsButton];
    self.smsButton=smsButton;
    self.smsButton.hidden=YES;
    [smsButton setBackgroundImage:[UIImage imageNamed:@"text"] forState:UIControlStateNormal];
    [smsButton addTarget:self action:@selector(SMS:) forControlEvents:UIControlEventTouchUpInside];


    UIButton *emailButton=[[UIButton alloc]init];
    [self addSubview:emailButton];
    self.emailButton=emailButton;
    self.emailButton.hidden=YES;
    [emailButton setBackgroundImage:[UIImage imageNamed:@"email"] forState:UIControlStateNormal];
    [emailButton addTarget:self action:@selector(email:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *addEventButton=[[UIButton alloc]init];
    [self addSubview:addEventButton];
    addEventButton.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightLight];
    self.addEventButton=addEventButton;
    [self.addEventButton setTitle:@"新增事项" forState:UIControlStateNormal];
    [addEventButton addTarget:self action:@selector(addEvent:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *eventDetailButton=[[UIButton alloc]init];
    [self addSubview:eventDetailButton];
    self.eventDetailButton=eventDetailButton;
    [eventDetailButton addTarget:self action:@selector(displayEvent:) forControlEvents:UIControlEventTouchUpInside];

}
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;

}


@end
