//
//  NavigationTitleView.m
//  Contacts Assistant
//
//  Created by Amay on 8/24/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "NavigationTitleView.h"
@interface NavigationTitleView()

@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet UIImageView *accessoryImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation NavigationTitleView
-(void)setEnabled:(BOOL)enabled{
    _enabled=enabled;
    self.titleButton.enabled=enabled;
    self.titleLabel.enabled=enabled;
}
-(void)setTitle:(NSString *)title{

    _title=title;
    self.titleLabel.text=title;    
}

-(void)setAccessoryImage:(UIImage *)accessoryImage{

    _accessoryImage=accessoryImage;
    self.accessoryImageView.image=accessoryImage;

}

- (IBAction)titleTouched:(id)sender {

    self.navigationTitlePressed();
    
}

@end
