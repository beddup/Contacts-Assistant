//
//  SMSReceiversView.m
//  Contacts Assistant
//
//  Created by Amay on 7/24/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "SMSReceiversView.h"
NSString * const ReceiversContactIndex=@"ReceiversContactIndex";
NSString * const ReceiversNameKey=@"ReceiversNameKey";
NSString * const ReceiversNumbersKey=@"ReceiversNumbersKey";

@interface SMSReceiversView()

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property(strong,nonatomic)NSMutableArray *receivers; // of contact and numbers

@end


@implementation SMSReceiversView


- (IBAction)receiversDetermined:(id)sender {

}

- (IBAction)cancelSeletion:(id)sender {

    self.cancelSMSHandler();

}

-(void)updateTextView{
    if (!self.receivers.count) {
        self.textView.text=@"暂未选择联系人";
        return;
    }

    NSString *contentString=@"";
    for (NSDictionary *contactDic in self.receivers) {
        NSString *contactInfo=[NSString stringWithFormat:@"%@: %@\n",contactDic[ReceiversNameKey],[contactDic[ReceiversNumbersKey] componentsJoinedByString:@","]];
        contentString =[contentString stringByAppendingString:contactInfo];
    }
    self.textView.text=contentString;

    [self updateTitle];


}
-(void)updateTitle{
    if (!self.receivers.count) {
    self.title.text=@"请选择联系人";
        return;
    }
    NSInteger phoneCount=0;
    for (NSDictionary *dic in self.receivers) {
        NSArray *numbersArray=dic[ReceiversNumbersKey];
        phoneCount+=numbersArray.count;
    }
    self.title.text=[NSString stringWithFormat:@"%@个联系人，%@个电话",@(self.receivers.count),@(phoneCount)];

}
-(void)removeContactAtIndex:(NSInteger)index{

    NSArray *indexes=[self.receivers valueForKey:ReceiversContactIndex];
    NSInteger i= [indexes indexOfObject:@(index)];
    [self.receivers removeObjectAtIndex:i];

    [self updateTextView];

}


-(void)addContactAtIndex:(NSInteger)index withName:(NSString *)name andPhoneNumbers:(NSArray *)numbers{
    if (!self.receivers.count) {
        self.textView.text=@"";
    }

    [self.receivers insertObject:@{ReceiversContactIndex:@(index),
                                   ReceiversNameKey:name,
                                   ReceiversNumbersKey:numbers} atIndex:0];

    [self updateTextView];




}

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.receivers= [@[] mutableCopy];

}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}


@end
