//
//  AddContactsToTagViewController.h
//  Contacts Assistant
//
//  Created by Amay on 9/8/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChooseContactsViewController.h"
#import "Tag.h"
@interface AddContactsToTagViewController : ChooseContactsViewController

@property(strong,nonatomic)Tag * tag;

@end
