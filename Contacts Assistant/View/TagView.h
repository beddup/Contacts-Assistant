//
//  TagView.h
//  Contacts Assistant
//
//  Created by Amay on 7/17/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ElementView.h"
@interface TagView : UIView

@property(copy,nonatomic)NSString *tagName;
@property(nonatomic) BOOL isChosen;

-(CGSize)suggestedSize;


@end
