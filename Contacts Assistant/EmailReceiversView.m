//
//  EmailReceiversView.m
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "EmailReceiversView.h"

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

@property(strong,nonatomic) NSDictionary *receivers;

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
-(NSString *)contentOfReceiversArray:(NSMutableArray *)array{

    NSString *content=@"";
    for (NSDictionary *contactDic in array) {
        NSString *contentString=[NSString stringWithFormat:@"%@: %@\n",contactDic[ContentNameKey],[contactDic[ContentEmailsKey] componentsJoinedByString:@","]];
        content =[content stringByAppendingString:contentString];
    }

    return content;

}

-(void)updateTitle{
    NSArray *currentFieldReceivers=self.receivers[self.currentField];
    if (!currentFieldReceivers.count) {
        self.titleLabel.text=self.defaultTitle[self.currentField];
        return;
    }
    self.titleLabel.text=[NSString stringWithFormat:@"%@个收件人，%@抄送，%@密送",@([(NSArray *)self.receivers[ReceiversToKey] count]),@([(NSArray *)self.receivers[ReceiversCCKey] count]),@([(NSArray*)self.receivers[ReceiversBCCKey] count])];
}

-(void)updateTextView{
    self.textView.text=[self contentOfReceiversArray:self.receivers[self.currentField]];
    if ([self.textView.text isEqualToString:@""]) {
        self.textView.text=self.defaultContent[self.currentField];
    }
    [self updateTitle];
}
-(void)addContactAtIndex:(NSInteger)index withName:(NSString *)name andEmails:(NSArray *)numbers{

    NSArray *currentFieldReceivers=self.receivers[self.currentField];
    if (!currentFieldReceivers.count) {
        self.textView.text=@"";
    }
    [self.receivers[self.currentField] insertObject:@{ContentNameKey:name,
                                                      ContentContactIndex:@(index),
                                                      ContentEmailsKey:numbers}
                                            atIndex:0 ];
    [self updateTextView];

}
-(void)removeContactAtIndex:(NSInteger)index{

    for (NSString *key in self.receivers.allKeys) {
        NSArray *indexes=[self.receivers[key] valueForKey:ContentContactIndex];
        NSInteger i =[indexes indexOfObject:@(index)];
        if (i!=NSNotFound) {
            [self.receivers[key] removeObjectAtIndex:i];
            break;
        }
    }
    [self updateTextView];

}

- (IBAction)receversDetermined:(UIButton *)sender {

}

- (IBAction)cancelSelection:(UIButton *)sender {
    self.cancelEmailHandler();
}


- (IBAction)selectTos:(UIButton *)sender {

    [self indicatorMoveToButton:sender];

    self.currentField=ReceiversToKey;

    [self updateTextView];

}

- (IBAction)selectCCs:(UIButton *)sender {

    [self indicatorMoveToButton:sender];

    self.currentField=ReceiversCCKey;

    [self updateTextView];


}

- (IBAction)selectBCCs:(UIButton *)sender {

    [self indicatorMoveToButton:sender];
    self.currentField=ReceiversBCCKey;
    [self updateTextView];


}
#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.receivers=@{ReceiversToKey:[@[] mutableCopy],
                     ReceiversCCKey:[@[] mutableCopy],
                     ReceiversBCCKey:[@[] mutableCopy]};

    self.defaultContent=@{ReceiversToKey:@"暂未添加收件人",
                          ReceiversCCKey:@"暂未添加抄送人",
                          ReceiversBCCKey:@"暂未添加密送人"};

    self.defaultTitle=@{ReceiversToKey:@"请选择收件人",
                        ReceiversCCKey:@"请选择抄送人",
                        ReceiversBCCKey:@"请选择密送人"};

    self.currentField=ReceiversToKey;



}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
