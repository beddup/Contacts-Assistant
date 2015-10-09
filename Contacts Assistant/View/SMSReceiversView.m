//
//  SMSReceiversView.m
//  Contacts Assistant
//
//  Created by Amay on 7/24/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "SMSReceiversView.h"
#import "ContactsManager.h"
#import "Contact.h"

@interface SMSReceiversView()

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property(strong,nonatomic)NSMutableArray *receivers; // of contact and contactInfo

@end


@implementation SMSReceiversView


- (IBAction)receiversDetermined:(id)sender {

    self.sendHandler([self phoneNumbersOrEmailOfReceivers:self.receivers]);
}

- (IBAction)cancelSeletion:(id)sender {

    self.cancelHandler();

}

-(void)updateTextView{

    if (!self.hasContactInfo) {
        self.textView.text=@"未选择联系人";
        return;
    }

    self.textView.text=[self contactInfosStringOfReceivers:self.receivers];

}
-(void)updateTitle{
    if (!self.hasContactInfo) {
        self.title.text=@"请选择联系人";
        return;
    }
    NSInteger phoneCount=0;
    for (NSDictionary *dic in self.receivers) {
        NSArray *numbersArray=dic[ReceiversContactInfosKey];
        phoneCount+=numbersArray.count;
    }
    self.title.text=[NSString stringWithFormat:@"%@个联系人",@(self.receivers.count)];

}

-(void)removeContactInfosOfContact:(Contact *)contact{

    for (int index=0; index<self.receivers.count; index++) {

        NSDictionary *receiver=self.receivers[index];
        Contact *possibleContact=receiver[ReceiversContactKey];
        if (possibleContact.contactID.integerValue == contact.contactID.integerValue) {
            [self.receivers removeObjectAtIndex:index];
            break;
        }
    }
    [self updateTextView];
    [self updateTitle];

}
-(void)addContactInfosToReceivers:(NSArray *)contactInfos contact:(Contact *)contact{
    [self.receivers insertObject:@{ReceiversContactKey:contact,
                                   ReceiversContactInfosKey:[contactInfos mutableCopy]}
                         atIndex:0];
    [self updateTextView];
    [self updateTitle];

}
-(BOOL)hasContactInfo{
    return self.receivers.count;
}
-(void)removeAllContactInfos{
    self.textView.text=@"未选择联系人";
    self.receivers=nil;
}
-(NSMutableArray *)receivers{
    if (!_receivers) {
        _receivers=[@[] mutableCopy];
    }
    return _receivers;
}

#pragma  mark - setup
-(void)setup{
    self.receivers= [@[] mutableCopy];
    self.layer.cornerRadius=3.0;
    self.textView.font=[UIFont systemFontOfSize:14];
    [self updateTextView];
    [self updateTitle];
}

@end
