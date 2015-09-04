//
//  ReceiversView.m
//  Contacts Assistant
//
//  Created by Amay on 9/1/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ReceiversView.h"
#import "Contact.h"
#import "ContactsManager.h"

NSString * const ReceiversContactKey=@"ReceiversContactKey";
NSString * const ReceiversContactInfosKey=@"ReceiversContactInfoKey";

@interface ReceiversView()

@end

@implementation ReceiversView
-(void)updateTextView{
//override
}
-(void)updateTitle{
    //override
}
-(void)removeContactInfosOfContact:(Contact *)contact{


}
-(void)addContactInfosToReceivers:(NSArray *)contactInfos contact:(Contact *)contact{
}
-(void)removeAllContactInfos{

}
-(NSString *)contactInfosStringOfReceivers:(NSArray *)receivers{
    NSString *contentString=@"";
    for (NSDictionary *receiver in receivers) {

        NSString *contactName=[receiver[ReceiversContactKey] contactName];
        NSString *contactInfoString=[[receiver[ReceiversContactInfosKey] valueForKey:ContactInfoValueKey] componentsJoinedByString:@", "];
        contentString =[contentString stringByAppendingString:[NSString stringWithFormat:@"%@: %@\n",contactName,contactInfoString]];
    }
    return contentString;

}
-(NSArray *)phoneNumbersOrEmailOfReceivers:(NSArray *)receivers{
    NSMutableArray *allPhoneNumber=[@[] mutableCopy];
    for (NSDictionary *receiver in receivers) {
        [allPhoneNumber addObjectsFromArray:[receiver[ReceiversContactInfosKey] valueForKey:ContactInfoValueKey]];
    }
    return allPhoneNumber;
}

-(void)awakeFromNib{
    [self setup];
}

-(void)setup{
}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

@end
