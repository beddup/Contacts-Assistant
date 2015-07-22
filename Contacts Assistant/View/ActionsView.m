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

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}
- (IBAction)actionButtonTapped:(UIButton *)sender {
    [self.delegate actionButtonTapped:sender.tag];
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
