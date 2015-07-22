//
//  TagNavigationView.h
//  Contacts Assistant
//
//  Created by Amay on 7/22/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tag.h"

@interface TagNavigationView : UIView

@property(strong,nonatomic)Tag * currentTag;

@property(copy)void(^didSelectTag)(Tag *selectedTag);
@property(copy)void(^manageTags)();

@end
