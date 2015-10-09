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
#import "NSString+ContactsAssistant.h"
#import "defines.h"
#import "AppDelegate.h"
#import "UIWindow+Hierarchy.h"
#import "MBProgressHUD+ContactsAssistant.h"
#import "UIViewController+SendSMSOrEmail.h"
#import <MessageUI/MessageUI.h>

@interface ContactCell()

@property(copy,nonatomic)NSArray *phonesInfo;
@property(copy,nonatomic)NSArray *emailsInfo;

@property(weak,nonatomic)UIButton *phoneButton;
@property(weak,nonatomic)UIButton *smsButton;
@property(weak,nonatomic)UIButton *emailButton;

@property(strong,nonatomic)Event *mostRecentEvent; //of Events
@property(strong,nonatomic)UIColor *contentBKGColor;

@end

@implementation ContactCell
#pragma mark - properties


-(void)setContact:(Contact *)contact{
    _contact=contact;

    self.phonesInfo=[[ContactsManager sharedContactManager]phoneNumbersOfContact:contact];
    self.emailsInfo=[[ContactsManager sharedContactManager]emailsOfContact:contact];
    [self checkPhoneSMSEmailButtonsState];

    self.mostRecentEvent=[contact mostRecentEvent];
    [self setNeedsDisplay];

}
-(void)setMode:(ContactCellMode )mode{
    _mode=mode;
    [self checkPhoneSMSEmailButtonsState];
    [self setNeedsDisplay];
}
-(void)checkPhoneSMSEmailButtonsState{
    self.phoneButton.hidden = self.mode || !self.phonesInfo.count;
    self.smsButton.hidden   = self.phoneButton.hidden || ![MFMessageComposeViewController canSendText];
    self.emailButton.hidden = self.mode || !self.emailsInfo.count || ![MFMailComposeViewController canSendMail];
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
#pragma mark -button Action
-(void)phone:(UIButton *)button{

    UIAlertController *phoneAlertController=[self alertControllerPhonesOrEmails:self.phonesInfo actionHandler:^(UIAlertAction *action,NSString *phoneNumberOrEmailAddress) {
        NSString *urlString=[NSString stringWithFormat:@"tel://%@",phoneNumberOrEmailAddress];
        NSURL *url=[NSURL URLWithString:urlString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    } cancelHandler:nil];
    phoneAlertController.message=[NSString stringWithFormat:@"给 %@ 打电话",self.contact.contactName];
    UIViewController *currentVC=[[[UIApplication sharedApplication] keyWindow]  currentViewController];
    [currentVC presentViewController:phoneAlertController animated:YES completion:nil];

}

-(void)SMS:(UIButton *)button{

    UIViewController *currentVC=[[[UIApplication sharedApplication] keyWindow]  currentViewController];

    UIAlertController *phoneAlertController=[self alertControllerPhonesOrEmails:self.phonesInfo
                                                                  actionHandler:^(UIAlertAction *action,NSString *phoneNumberOrEmailAddress) {
                                                                      UIViewController *vc=[[[UIApplication sharedApplication] keyWindow]  currentViewController];
                                                                      [vc SMSTo:@[phoneNumberOrEmailAddress]];
                                                                  }
                                                                  cancelHandler:nil];
    phoneAlertController.message=[NSString stringWithFormat:@"给 %@ 发短信",self.contact.contactName];
    [currentVC presentViewController:phoneAlertController animated:YES completion:nil];

}

-(void)email:(UIButton *)button{

    UIViewController *currentVC=[[[UIApplication sharedApplication] keyWindow]  currentViewController];
    UIAlertController *phoneAlertController=[self alertControllerPhonesOrEmails:self.emailsInfo actionHandler:^(UIAlertAction *action,NSString *phoneNumberOrEmailAddress) {
        UIViewController *vc=[[[UIApplication sharedApplication] keyWindow]  currentViewController];
        [vc emailTo:@[phoneNumberOrEmailAddress] cc:nil bcc:nil];
    }cancelHandler:nil];
    phoneAlertController.message=[NSString stringWithFormat:@"给 %@ 发邮件",self.contact.contactName];
    [currentVC presentViewController:phoneAlertController animated:YES completion:nil];
    
}

-(UIAlertController *)alertControllerPhonesOrEmails:(NSArray *)infos
                                      actionHandler:(void(^)(UIAlertAction *action,NSString *phoneNumberOrEmailAddress))handler
                                      cancelHandler:(void(^)(UIAlertAction *action))cancleHandler{

    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSDictionary *info in infos) {
        NSString *title=[NSString stringWithFormat:@"%@: %@", info[ContactInfoLabelKey],info[ContactInfoValueKey]];
        UIAlertAction *action=[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            handler(action,info[ContactInfoValueKey]);
        }];
        [alertController addAction:action];
    }

    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:cancleHandler];
    [alertController addAction:cancelAction];
    return alertController;
    
}


#pragma mark -draw
static CGFloat const ContentInsetX=4;
static CGFloat const ContentInsetY=4;
static CGFloat const ContactNameOffsetX=12;
static CGFloat const ContactNameOffsetY=8;
static CGFloat const VerticalSpace=4;
static CGFloat const HorizontalSpace=8;
static CGFloat const ButtonHeight=44;
static CGFloat const EventHeight=16;
static CGFloat const EventIndicatorHeight=8; // also width

-(void)drawRect:(CGRect)rect{

    CGRect contentRect=CGRectInset(rect, ContentInsetX, ContentInsetY);
    contentRect=CGRectOffset(contentRect, CGRectGetMinX(self.contentView.frame), 0);

    // draw content area
    UIBezierPath *roundedRectPath=[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:3];
    [self.contentBKGColor setFill];

    [roundedRectPath fill];
    [roundedRectPath addClip];

    // draw Name
    NSAttributedString *contactName=[[NSAttributedString alloc]initWithString:self.contact.contactName attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}];
    CGRect contactNameRect;
    contactNameRect.origin=CGPointMake(CGRectGetMinX(contentRect)+ContactNameOffsetX, CGRectGetMinY(contentRect)+ContactNameOffsetY);
    contactNameRect.size=contactName.size;
    [contactName drawAtPoint:contactNameRect.origin];

    //draw department
    CGRect compantAndDepartmentRect=CGRectMake(CGRectGetMaxX(contactNameRect)+8, CGRectGetMinY(contactNameRect), CGRectGetWidth(contentRect)-ContactNameOffsetX-CGRectGetWidth(contactNameRect)-HorizontalSpace, CGRectGetHeight(contactNameRect));
    [self drawCompantAndDepartmentInfoInRect:compantAndDepartmentRect];

    // draw contact info or layout buttons
    CGPoint startPoint=CGPointMake(CGRectGetMinX(contactNameRect), CGRectGetMaxY(contactNameRect)+VerticalSpace);
    if (self.mode == ContactCellModeSMS) {
        [self drawContactInfos:self.phonesInfo AtPoint:startPoint];
    }else if (self.mode == ContactCellModeEmail){
        [self drawContactInfos:self.emailsInfo AtPoint:startPoint];
        return;
    }else if (self.mode == ContactCellModeNormal){
        [self layoutPhoneSMSEmailButtonsAtPoint:startPoint];
        // draw event
        CGRect eventRect=CGRectMake(CGRectGetMinX(contactNameRect), CGRectGetMaxY(contentRect)-ContactNameOffsetY-EventHeight, CGRectGetWidth(contentRect)-ContactNameOffsetX, EventHeight);
        [self drawDisplayedEventInRect:eventRect];
    }

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
        [companyAndDepartment drawAtPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect)-companyAndDepartment.size.height/2)];
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
    CGRect buttonRect=CGRectMake(point.x,point.y, ButtonHeight, ButtonHeight);
    if (!self.phoneButton.hidden) {
        self.phoneButton.frame=buttonRect;
        buttonRect=CGRectOffset(buttonRect,ButtonHeight+HorizontalSpace, 0);
    }
    if (!self.smsButton.hidden) {
        self.smsButton.frame=buttonRect;
        buttonRect=CGRectOffset(buttonRect, ButtonHeight+HorizontalSpace, 0);
    }
    if (!self.emailButton.hidden) {
        self.emailButton.frame=buttonRect;
        return;
    }

    if (self.phoneButton.hidden && self.emailButton.hidden && self.smsButton.hidden) {

        NSAttributedString *noWayToContact=[[NSAttributedString alloc]initWithString:@"无联系方式" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightLight],NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
        CGPoint startPoint=CGPointMake(point.x, point.y+ButtonHeight/2-noWayToContact.size.height/2);
        [noWayToContact drawAtPoint:startPoint];
    }
}
-(void)drawDisplayedEventInRect:(CGRect)rect{

    if (!self.mostRecentEvent ) {
        return;
    }
    CGRect indicatorCirleRect=CGRectMake(CGRectGetMinX(rect), CGRectGetMidY(rect)-EventIndicatorHeight/2, EventIndicatorHeight, EventIndicatorHeight);
    UIBezierPath *cirle=[UIBezierPath bezierPathWithOvalInRect:indicatorCirleRect];

    if ([self.mostRecentEvent passed]) {
        [[UIColor darkGrayColor]setFill];
    }else{
        [[UIColor orangeColor]setFill];
    }
    [cirle fill];

    NSString *displayedEventString=[self.mostRecentEvent displayedEventString];
    if ([[self.contact unfinishedOwnedEvents] count] > 1) {
        displayedEventString=[NSString stringWithFormat:@"%lu个联系事项: %@; ...",(unsigned long)[[self.contact unfinishedOwnedEvents] count],displayedEventString];
    }

    NSAttributedString *eventAS=[[NSAttributedString alloc]initWithString:displayedEventString attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightLight],NSForegroundColorAttributeName:[UIColor darkGrayColor],NSParagraphStyleAttributeName:[self paragraphStyle]}];

    [eventAS drawInRect:CGRectMake(CGRectGetMaxX(indicatorCirleRect)+HorizontalSpace, CGRectGetMidY(rect)-eventAS.size.height/2, CGRectGetWidth(rect)-ContactNameOffsetX-EventIndicatorHeight-HorizontalSpace, CGRectGetHeight(rect))];
}
#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.contentMode=UIViewContentModeRedraw;
    self.contentBKGColor=[UIColor colorWithWhite:0.85 alpha:1];
    self.backgroundColor=[UIColor clearColor];
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
