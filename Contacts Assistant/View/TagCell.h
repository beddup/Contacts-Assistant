//
//  TagView.h
//  Contacts Assistant
//
//  Created by Amay on 7/17/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tag.h"
@interface TagCell : UITableViewCell

@property(copy,nonatomic)Tag *myTag;
@property(nonatomic)BOOL hasCloseButton;

@property(copy)void(^closeButtonTapped)(Tag *tag);

@end
