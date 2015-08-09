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
#import "Event+Utility.h"
#import "ContactsManager.h"

@interface ContactCell()

@property(strong,nonatomic)NSDictionary *availabelSNS;

@property(strong,nonatomic)NSDictionary *availabelCommuniations;


@property(weak,nonatomic)UIButton *putTopButton;
@property(weak,nonatomic)UIButton *phoneButton;

@property(weak,nonatomic)UIButton *smsButton;

@property(weak,nonatomic)UIButton *emailButton;

//@property(weak,nonatomic)UIButton *addEventButton;
//
//@property(weak,nonatomic)UIButton *eventDetailButton;

@property(strong,nonatomic)NSArray *events; //of Events

@end

@implementation ContactCell
#pragma mark - properties


-(void)setContact:(Contact *)contact{
    _contact=contact;


    self.events = [[_contact.attendWhichEvents allObjects] sortedArrayUsingComparator:^NSComparisonResult(Event * obj1, Event * obj2) {
        return [obj1.date compare:obj2.date];
    }];

    [self checkAvailableCommunications];

    [self checkAvailableSNS];

    [self setNeedsDisplay];

}
-(void)setMode:(ContactCellMode )mode{
    _mode=mode;

    self.phoneButton.hidden=mode || ![self.availabelCommuniations.allKeys containsObject:CommunicationPhones];
    self.smsButton.hidden=self.phoneButton.hidden;
    self.emailButton.hidden= mode || ![self.availabelCommuniations.allKeys containsObject:CommunicationEmails];
//    self.addEventButton.hidden=mode;
//    self.eventDetailButton.hidden=mode;

    [self setNeedsDisplay];
}
-(void)checkAvailableCommunications{

    NSDictionary *availabelCommuniations=[self.contact avaibleCommunications];
    self.availabelCommuniations=availabelCommuniations;

    [self setNeedsDisplay];

}
-(void)checkAvailableSNS{
  // check sns
}
-(void)phone:(UIButton *)button{

    [self.delegate phone:self.contact availableNumbers:self.availabelCommuniations[CommunicationPhones]];

}

-(void)SMS:(UIButton *)button{

    [self.delegate sms:self.contact availableNumbers:self.availabelCommuniations[CommunicationPhones]];

}

-(void)email:(UIButton *)button{

    [self.delegate email:self.contact availableEmails:self.availabelCommuniations[CommunicationEmails]];
    
}
-(void)top:(UIButton *)button{

    self.contact.contactOrderWeight=@([[NSDate date]timeIntervalSince1970]);
    [self.delegate putToTop:self];
}

-(void)displayEvent:(UIButton *)button{
    if (!self.events.count) {
        return;
    }
    //
}
-(void)setEditing:(BOOL)editing animated:(BOOL)animated{
    [super setEditing:editing animated:animated];
    [self setNeedsDisplay];
}

static CGFloat const ContentInsetX=4;
static CGFloat const ContentInsetY=4;


-(void)drawRect:(CGRect)rect{

    CGRect contentRect=CGRectInset(rect, ContentInsetX, ContentInsetY);
    contentRect=CGRectOffset(contentRect, CGRectGetMinX(self.contentView.frame), 0);

    // draw content area
    UIBezierPath *roundedRectPath=[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:3];
    [[UIColor lightGrayColor]setFill];
    [roundedRectPath fill];
    [roundedRectPath addClip];


    // draw Name
    NSAttributedString *contactName=[[NSAttributedString alloc]initWithString:self.contact.contactName attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}];
    CGRect contactNameRect;
    contactNameRect.origin=CGPointMake(CGRectGetMinX(contentRect)+12, CGRectGetMinY(contentRect)+8);
    contactNameRect.size=contactName.size;
    [contactName drawInRect:contactNameRect];

    // put top button
    self.putTopButton.frame=CGRectMake(CGRectGetWidth(contentRect)-55, CGRectGetMidY(contactNameRect)-15, 44, 30);

    //draw department
    NSString *companyString=[self.contact companyAndDepartment];
    if (companyString) {
        NSAttributedString *companyAndDepartment=[[NSAttributedString alloc]initWithString:companyString
                                                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightLight],
                                                                                             NSForegroundColorAttributeName:[UIColor darkGrayColor]}];

        CGRect companyAndDepartmentRect;
        companyAndDepartmentRect.origin=CGPointMake(CGRectGetMaxX(contactNameRect)+8,CGRectGetMidY(contactNameRect)-companyAndDepartment.size.height/2);
        companyAndDepartmentRect.size=CGSizeMake(CGRectGetMinX(self.putTopButton.frame)-CGRectGetMaxX(contactNameRect)-8, companyAndDepartment.size.height);
        [companyAndDepartment drawInRect:companyAndDepartmentRect];
    }
    self.putTopButton.hidden = self.mode != ContactCellModeNormal;
    if (self.mode == ContactCellModeSMS) {
        CGRect phoneNumberRect=CGRectMake(CGRectGetMinX(contactNameRect), CGRectGetMaxY(contactNameRect), CGRectGetWidth(contentRect), 13);
        for (NSDictionary *phoneNumber in self.availabelCommuniations[CommunicationPhones]) {
            NSAttributedString *ASphonernNumber=[[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@: %@",phoneNumber[PhoneLabel],phoneNumber[PhoneNumber]]
                                                                              attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightLight],
                                                                                           NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
            [ASphonernNumber drawInRect:phoneNumberRect];
            phoneNumberRect=CGRectOffset(phoneNumberRect, 0, 15);
        }
        return ;
    }
    if (self.mode == ContactCellModeEmail) {
        CGRect emailRect=CGRectMake(CGRectGetMinX(contactNameRect), CGRectGetMaxY(contactNameRect), CGRectGetWidth(contentRect), 13);
        for (NSDictionary *email in self.availabelCommuniations[CommunicationEmails]) {
            NSAttributedString *ASEmail=[[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@: %@",email[EmailLabel],email[EmailValue]]

                                                                               attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightLight],
                                                                                            NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
            [ASEmail drawInRect:emailRect];
            emailRect=CGRectOffset(emailRect, 0, 15);
        }
        return ;

    }

    //  buttons frame
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
        NSLog(@"email:%@",self.availabelCommuniations[CommunicationEmails]);
        self.emailButton.frame=buttonRect;
    }

    if (self.phoneButton.hidden && self.emailButton.hidden && self.smsButton.hidden) {
        NSAttributedString *noWayToContact=[[NSAttributedString alloc]initWithString:@"无联系方式"
                                                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightLight],
                                                                                             NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
        [noWayToContact drawAtPoint:buttonRect.origin];
    }

    // draw event
    Event *recentEvent=[self.contact recentEvent];
    if (!recentEvent) {
        return;
    }
    CGRect indicatorCirleRect=CGRectMake(CGRectGetMinX(contactNameRect), CGRectGetMaxY(buttonRect)+8, 8, 8);
    UIBezierPath *cirle=[UIBezierPath bezierPathWithOvalInRect:indicatorCirleRect];

    if ([recentEvent passed]) {
        [[UIColor darkGrayColor]setFill];
    }else{
        [[UIColor orangeColor]setFill];
    }
    [cirle fill];

    NSAttributedString *eventAS=[[NSAttributedString alloc]initWithString:recentEvent.event
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightLight],
                                                                                       NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
    CGRect eventASRect;
    eventASRect.size=CGSizeMake(CGRectGetWidth(contentRect)-60, 36);
    eventASRect.origin=CGPointMake(CGRectGetMaxX(indicatorCirleRect)+8, CGRectGetMidY(indicatorCirleRect)-eventAS.size.height/2);
    [eventAS drawInRect:eventASRect];

}
#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.backgroundColor=[UIColor clearColor];
    self.selectionStyle=UITableViewCellSelectionStyleNone;
    self.highlighted=NO;
    UIView *view=[[UIView alloc]init];
    view.backgroundColor=[UIColor clearColor];
    self.multipleSelectionBackgroundView=view;

    UIButton *putTop=[[UIButton alloc]init];
    [self addSubview:putTop];
    self.putTopButton=putTop;
    [putTop setTitle:@"Top" forState:UIControlStateNormal];
    [putTop addTarget:self action:@selector(top:) forControlEvents:UIControlEventTouchUpInside];


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

//    UIButton *addEventButton=[[UIButton alloc]init];
//    [self addSubview:addEventButton];
//    addEventButton.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightLight];
//    self.addEventButton=addEventButton;
//    [self.addEventButton setTitle:@"新增事项" forState:UIControlStateNormal];
//    [addEventButton addTarget:self action:@selector(addEvent:) forControlEvents:UIControlEventTouchUpInside];
//
//    UIButton *eventDetailButton=[[UIButton alloc]init];
//    [self addSubview:eventDetailButton];
//    self.eventDetailButton=eventDetailButton;
//    [eventDetailButton addTarget:self action:@selector(displayEvent:) forControlEvents:UIControlEventTouchUpInside];
//


}
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;

}


@end
