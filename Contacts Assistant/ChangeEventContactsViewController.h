//
//  ChangeEventContactsViewController.h
//  Contacts Assistant
//
//  Created by Amay on 8/1/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"
#import "Event.h"
#import "ChooseContactsViewController.h"

@interface ChangeEventContactsViewController : ChooseContactsViewController

@property(strong,nonatomic)Event *event;

@end
