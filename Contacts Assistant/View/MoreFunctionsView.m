//
//  ActionsView.m
//  Contacts Assistant
//
//  Created by Amay on 7/22/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "MoreFunctionsView.h"

@interface MoreFunctionsView()



@end

@implementation MoreFunctionsView

- (IBAction)groupSMS:(id)sender {
    [self.delegate groupSMS];
}
- (IBAction)groupEmail:(id)sender {
    [self.delegate groupEmail];
}
- (IBAction)scanContactQR:(id)sender {
    [self.delegate scanContactQR];
}
- (IBAction)addContactManually:(id)sender {
    [self.delegate addContactManually];
}

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}
-(void)setup{
    self.layer.cornerRadius=3.0;

}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

@end
