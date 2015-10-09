//
//  EmailReceiversView.m
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "EmailReceiversView.h"
#import "Contact.h"
#import "ContactsManager.h"
#import "UIViewController+SendSMSOrEmail.h"
#import "UIWindow+Hierarchy.h"
NSString * const ContentContactIndex=@"ContentContactIndex";
NSString * const ContentNameKey=@"ContentNameKey";
NSString * const ContentEmailsKey=@"ContentEmailsKey";

NSString * const ReceiversToKey=@"ReceiversToKey";
NSString * const ReceiversCCKey=@"ReceiversCCKey";
NSString * const ReceiversBCCKey=@"ReceiversBCCKey";

@interface EmailReceiversView()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *indicateView;

@property(strong,nonatomic) NSDictionary *allThreeKindReceivers;

@property(nonatomic)NSString *currentField;

@property(strong,nonatomic)NSDictionary *defaultContent;
@property(strong,nonatomic)NSDictionary *defaultTitle;

@end


@implementation EmailReceiversView
-(void)indicatorMoveToButton:(UIButton *)button{

    CGRect oldIndicatorFrame=self.indicateView.frame;
    [UIView animateWithDuration:0.3 animations:^{
        self.indicateView.frame=CGRectOffset(oldIndicatorFrame, 0, -CGRectGetMinY(oldIndicatorFrame)+CGRectGetMinY(button.frame));
    }];

}

-(void)updateTitle{
    NSArray *currentFieldReceivers=self.allThreeKindReceivers[self.currentField];
    if (!currentFieldReceivers.count) {
        self.titleLabel.text=self.defaultTitle[self.currentField];
        return;
    }
    self.titleLabel.text=[NSString stringWithFormat:@"%@个收件人，%@抄送，%@密送",@([(NSArray *)self.allThreeKindReceivers[ReceiversToKey] count]),@([(NSArray *)self.allThreeKindReceivers[ReceiversCCKey] count]),@([(NSArray*)self.allThreeKindReceivers[ReceiversBCCKey] count])];
}

-(void)updateTextView{

    if (![self.allThreeKindReceivers[self.currentField] count]) {
        self.textView.text=self.defaultContent[self.currentField];
        return;
    }
    self.textView.text=[self contactInfosStringOfReceivers:self.allThreeKindReceivers[self.currentField]];

}
-(void)addContactInfosToReceivers:(NSArray *)contactInfos contact:(Contact *)contact{

    [self.allThreeKindReceivers[self.currentField] insertObject:@{ReceiversContactKey:contact,
                                                       ReceiversContactInfosKey:[contactInfos mutableCopy]}
                         atIndex:0];

    [self updateTextView];
    [self updateTitle];

}

-(void)removeContactInfosOfContact:(Contact *)contact{
    for (NSString *key in self.allThreeKindReceivers.allKeys) {

         NSMutableArray* receivers=self.allThreeKindReceivers[key];
        for (int index=0; index<receivers.count; index++) {
            NSDictionary *receiver=receivers[index];
            Contact *possibleContact=receiver[ReceiversContactKey];
            if (possibleContact.contactID.integerValue == contact.contactID.integerValue) {
                [receivers removeObjectAtIndex:index];
            }
        }
    }

    [self updateTextView];
    [self updateTitle];

}
-(void)removeAllContactInfos{
    self.textView.text=self.textView.text=self.defaultContent[self.currentField];
    self.allThreeKindReceivers=nil;
}
-(BOOL)hasContactInfo{
    for (NSString *key in self.allThreeKindReceivers.allKeys) {
        NSMutableArray* receivers=self.allThreeKindReceivers[key];
        if (receivers.count) {
            return YES;
        }
    }
    return NO;
}
-(NSArray *)selectedContactInfosOfContact:(Contact *)contact{

    NSMutableArray *marray=[@[] mutableCopy];
    for (NSString *key in self.allThreeKindReceivers.allKeys) {
        NSMutableArray* receivers=self.allThreeKindReceivers[key];
        for (NSDictionary *receiver in receivers) {
            Contact *possibleContact=receiver[ReceiversContactKey];
            if (possibleContact.contactID.integerValue == contact.contactID.integerValue) {
                [marray addObjectsFromArray:receiver[ReceiversContactInfosKey]];
            }
        }
    }
        return nil;

}


- (IBAction)receversDetermined:(UIButton *)sender {
    UIViewController *currentVC=[[[UIApplication sharedApplication] keyWindow]  currentViewController];
    NSArray *ToEmail=[self phoneNumbersOrEmailOfReceivers:self.allThreeKindReceivers[ReceiversToKey]];
    NSArray *CCEmail=[self phoneNumbersOrEmailOfReceivers:self.allThreeKindReceivers[ReceiversCCKey]];
    NSArray *BCCEmail=[self phoneNumbersOrEmailOfReceivers:self.allThreeKindReceivers[ReceiversBCCKey]];
    [currentVC emailTo:ToEmail cc:CCEmail bcc:BCCEmail];
}

- (IBAction)cancelSelection:(UIButton *)sender {
    self.cancelHandler();
}


- (IBAction)selectTos:(UIButton *)sender {

    [self indicatorMoveToButton:sender];

    self.currentField=ReceiversToKey;

    [self updateTextView];
    [self updateTitle];


}

- (IBAction)selectCCs:(UIButton *)sender {

    [self indicatorMoveToButton:sender];

    self.currentField=ReceiversCCKey;

    [self updateTextView];
    [self updateTitle];



}

- (IBAction)selectBCCs:(UIButton *)sender {

    [self indicatorMoveToButton:sender];
    self.currentField=ReceiversBCCKey;
    [self updateTextView];
    [self updateTitle];


}
#pragma  mark - setup
-(NSDictionary *)allThreeKindReceivers{
    if (!_allThreeKindReceivers) {
        _allThreeKindReceivers=@{ReceiversToKey:[@[] mutableCopy],
                                     ReceiversCCKey:[@[] mutableCopy],
                                     ReceiversBCCKey:[@[] mutableCopy]};
    }
    return _allThreeKindReceivers;
}
-(void)setup{

    self.defaultContent=@{ReceiversToKey:@"未添加收件人",
                          ReceiversCCKey:@"未添加抄送人",
                          ReceiversBCCKey:@"未添加密送人"};

    self.defaultTitle=@{ReceiversToKey:@"请选择收件人",
                        ReceiversCCKey:@"请选择抄送人",
                        ReceiversBCCKey:@"请选择密送人"};

    self.currentField=ReceiversToKey;

    self.layer.cornerRadius=3.0;
    self.textView.font=[UIFont systemFontOfSize:14];
    [self updateTextView];
    [self updateTitle];



}



@end
