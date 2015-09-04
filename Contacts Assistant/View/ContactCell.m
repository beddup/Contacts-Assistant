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

@property(strong,nonatomic)NSArray *phonesInfo;
@property(strong,nonatomic)NSArray *emailsInfo;

@property(weak,nonatomic)UIButton *phoneButton;
@property(weak,nonatomic)UIButton *smsButton;
@property(weak,nonatomic)UIButton *emailButton;

@property(strong,nonatomic)Event *displayedEvent; //of Events
@property(strong,nonatomic)UIColor *contentBKGColor;

@end

@implementation ContactCell
#pragma mark - properties


-(void)setContact:(Contact *)contact{
    _contact=contact;

    self.phonesInfo=[[ContactsManager sharedContactManager]phoneNumbersOfContact:contact];
    self.emailsInfo=[[ContactsManager sharedContactManager]emailsOfContact:contact];
    [self checkPhoneSMSEmailButtonsState];

    self.displayedEvent=[contact mostRecentEvent];
    [self setNeedsDisplay];

}
-(void)setMode:(ContactCellMode )mode{
    _mode=mode;
    [self checkPhoneSMSEmailButtonsState];
    [self setNeedsDisplay];
}
-(void)checkPhoneSMSEmailButtonsState{
    self.phoneButton.hidden = self.mode || !self.phonesInfo.count;
    self.smsButton.hidden   = self.phoneButton.hidden;
    self.emailButton.hidden = self.mode || !self.emailsInfo.count;
}
#pragma mark - delegate
-(void)phone:(UIButton *)button{

    [self.delegate phone:self.contact phonesInfo:self.phonesInfo];

}

-(void)SMS:(UIButton *)button{

    [self.delegate sms:self.contact phonesInfo:self.phonesInfo];

}

-(void)email:(UIButton *)button{

    [self.delegate email:self.contact emailsInfo:self.emailsInfo];
    
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated{
    [super setEditing:editing animated:animated];
    [self setNeedsDisplay];
}
-(void)setSelected:(BOOL)selected animated:(BOOL)animated{
    if (selected) {
        self.contentBKGColor=[UIColor colorWithRed:81.0/255.0 green:167.0/255.0 blue:249.0/255.0 alpha:0.2];
    }else{
        self.contentBKGColor=[UIColor colorWithWhite:0.85 alpha:1];
    }
    [super setSelected:selected animated:animated];
    [self setNeedsDisplay];
}

static CGFloat const ContentInsetX=4;
static CGFloat const ContentInsetY=4;
static CGFloat const ContactNameOffsetX=12;
static CGFloat const ContactNameOffsetY=8;
static CGFloat const VerticalSpace=4;
static CGFloat const HorizontalSpace=8;
static CGFloat const ButtonHeigh=44;
static CGFloat const EventHeight=16;
static CGFloat const EventIndicatorHeight=8; // also width



//4+8+20+4+44+8+4=92
//4+8+20+4+44+16+8+4=108


-(void)drawRect:(CGRect)rect{

    CGRect contentRect=CGRectInset(rect, ContentInsetX, ContentInsetY);
    contentRect=CGRectOffset(contentRect, CGRectGetMinX(self.contentView.frame), 0);

    // draw content area
    UIBezierPath *roundedRectPath=[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:3];
    [self.contentBKGColor setFill];
//    [[UIColor colorWithWhite:0.85 alpha:1]setFill];
    [roundedRectPath fill];
    [roundedRectPath addClip];

    // draw Name
    NSAttributedString *contactName=[[NSAttributedString alloc]initWithString:self.contact.contactName attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}];
    CGRect contactNameRect;
    contactNameRect.origin=CGPointMake(CGRectGetMinX(contentRect)+ContactNameOffsetX, CGRectGetMinY(contentRect)+ContactNameOffsetY);
    contactNameRect.size=contactName.size;
    [contactName drawInRect:contactNameRect];

    //draw department
    CGRect compantAndDepartmentRect=CGRectMake(CGRectGetMaxX(contactNameRect)+8, CGRectGetMinY(contactNameRect), CGRectGetWidth(contentRect)-ContactNameOffsetX-CGRectGetWidth(contactNameRect)-HorizontalSpace, CGRectGetHeight(contactNameRect));
    [self drawCompantAndDepartmentInfoInRect:compantAndDepartmentRect];

    // draw contact info or layout buttons
    CGPoint startPoint=CGPointMake(CGRectGetMinX(contactNameRect), CGRectGetMaxY(contactNameRect)+VerticalSpace);
    if (self.mode == ContactCellModeSMS) {
        [self drawContactInfos:self.phonesInfo AtPoint:startPoint];
    }else if (self.mode == ContactCellModeEmail){
        [self drawContactInfos:self.emailsInfo AtPoint:startPoint];
    }else if (self.mode == ContactCellModeNormal){
        //layout button
        [self layoutPhoneSMSEmailButtonsAtPoint:startPoint];
    }

    // draw event
    CGRect eventRect=CGRectMake(CGRectGetMinX(contactNameRect), CGRectGetMaxY(contentRect)-ContactNameOffsetY-EventHeight, CGRectGetWidth(contentRect)-ContactNameOffsetX, EventHeight);
    [self drawDisplayedEventInRect:eventRect];

}
-(NSParagraphStyle *)paragraphStyle{
    NSMutableParagraphStyle *ps=[[NSMutableParagraphStyle alloc]init];
    ps.lineBreakMode=NSLineBreakByTruncatingTail;
    return ps;
}
-(void)drawCompantAndDepartmentInfoInRect:(CGRect)rect{
    NSString *companyString=[self.contact companyAndDepartment];
    if (companyString) {
        NSAttributedString *companyAndDepartment=[[NSAttributedString alloc]initWithString:companyString attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightLight], NSForegroundColorAttributeName:[UIColor darkGrayColor],NSParagraphStyleAttributeName:[self paragraphStyle]}];
        [companyAndDepartment drawInRect:CGRectMake(CGRectGetMinX(rect), CGRectGetMidY(rect)-companyAndDepartment.size.height/2, CGRectGetWidth(rect), CGRectGetHeight(rect))];
    }

}
-(void)drawContactInfos:(NSArray *)contactInfos AtPoint:(CGPoint)point{

    CGPoint startPoint=point;
    for (NSDictionary *contactInfo in contactInfos) {

        NSString *string=[NSString stringWithFormat:@"%@: %@",contactInfo[ContactInfoLabelKey],contactInfo[ContactInfoValueKey]];

        NSAttributedString *ASphonernNumber=[[NSAttributedString alloc]initWithString:string attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightLight],NSForegroundColorAttributeName:[UIColor darkGrayColor],NSParagraphStyleAttributeName:[self paragraphStyle]}];

        [ASphonernNumber drawAtPoint:startPoint];
        startPoint=CGPointMake(startPoint.x, startPoint.y+16);
    }
}
-(void)layoutPhoneSMSEmailButtonsAtPoint:(CGPoint)point{
    //  buttons frame
    CGRect buttonRect=CGRectMake(point.x,point.y, ButtonHeigh, ButtonHeigh);
    if (!self.phoneButton.hidden) {
        self.phoneButton.frame=buttonRect;
        buttonRect=CGRectOffset(buttonRect,ButtonHeigh+HorizontalSpace, 0);
    }
    if (!self.smsButton.hidden) {
        self.smsButton.frame=buttonRect;
        buttonRect=CGRectOffset(buttonRect, ButtonHeigh+HorizontalSpace, 0);
    }
    if (!self.emailButton.hidden) {
        self.emailButton.frame=buttonRect;
        return;
    }

    if (self.phoneButton.hidden && self.emailButton.hidden && self.smsButton.hidden) {

        NSAttributedString *noWayToContact=[[NSAttributedString alloc]initWithString:@"无联系方式" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightLight],NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
        [noWayToContact drawAtPoint:point];
    }
}
-(void)drawDisplayedEventInRect:(CGRect)rect{

    if (!self.displayedEvent ) {
        return;
    }
    CGRect indicatorCirleRect=CGRectMake(CGRectGetMinX(rect), CGRectGetMidY(rect), EventIndicatorHeight, EventIndicatorHeight);
    UIBezierPath *cirle=[UIBezierPath bezierPathWithOvalInRect:indicatorCirleRect];

    if ([self.displayedEvent passed]) {
        [[UIColor darkGrayColor]setFill];
    }else{
        [[UIColor orangeColor]setFill];
    }
    [cirle fill];
    NSAttributedString *eventAS=[[NSAttributedString alloc]initWithString:self.displayedEvent.event attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightLight],NSForegroundColorAttributeName:[UIColor darkGrayColor],NSParagraphStyleAttributeName:[self paragraphStyle]}];
    [eventAS drawInRect:CGRectMake(CGRectGetMaxX(indicatorCirleRect)+HorizontalSpace, CGRectGetMinY(rect), CGRectGetWidth(rect)-ContactNameOffsetX-EventIndicatorHeight-HorizontalSpace, CGRectGetHeight(rect))];

}
#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{
    self.contentBKGColor=[UIColor colorWithWhite:0.85 alpha:1];
    self.backgroundColor=[UIColor clearColor];
//    self.selectionStyle=UITableViewCellSelectionStyleBlue;
    UIView *view=[[UIView alloc]init];
    view.backgroundColor=[UIColor clearColor];
    self.multipleSelectionBackgroundView=view;
    self.selectedBackgroundView=view;

    UIButton *phoneButton=[[UIButton alloc]init];
    [self addSubview:phoneButton];
    self.phoneButton=phoneButton;
    self.phoneButton.hidden=YES;
    [phoneButton setBackgroundImage:[UIImage imageNamed:@"PhoneIcon"] forState:UIControlStateNormal];
    [phoneButton addTarget:self action:@selector(phone:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *smsButton=[[UIButton alloc]init];
    [self addSubview:smsButton];
    self.smsButton=smsButton;
    self.smsButton.hidden=YES;
    [smsButton setBackgroundImage:[UIImage imageNamed:@"SMSIcon"] forState:UIControlStateNormal];
    [smsButton addTarget:self action:@selector(SMS:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *emailButton=[[UIButton alloc]init];
    [self addSubview:emailButton];
    self.emailButton=emailButton;
    self.emailButton.hidden=YES;
    [emailButton setBackgroundImage:[UIImage imageNamed:@"EmailIcon"] forState:UIControlStateNormal];
    [emailButton addTarget:self action:@selector(email:) forControlEvents:UIControlEventTouchUpInside];


}
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;

}


@end
