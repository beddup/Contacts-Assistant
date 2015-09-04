//
//  ActionsView.m
//  Contacts Assistant
//
//  Created by Amay on 7/22/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ActionsView.h"

@interface ActionsView()



@end

@implementation ActionsView

- (IBAction)actionButtonTapped:(UIButton *)sender {

    [self.delegate actionView:self actionButtonTapped:sender.tag];
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
