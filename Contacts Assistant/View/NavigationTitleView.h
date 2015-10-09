//
//  NavigationTitleView.h
//  Contacts Assistant
//
//  Created by Amay on 8/24/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NavigationTitleView : UIView

@property(copy,nonatomic)NSString *title;
@property(strong,nonatomic)UIImage *accessoryImage;
@property(nonatomic)BOOL enabled;

@property(copy) void(^navigationTitlePressed)();

@end
