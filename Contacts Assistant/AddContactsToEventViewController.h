//
//  ChangeEventContactsViewController.h
//  Contacts Assistant
//
//  Created by Amay on 8/1/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"
#import "ChooseContactsViewController.h"
@protocol EventContentUpdatingDelegate;

@interface AddContactsToEventViewController : ChooseContactsViewController

@property(strong,nonatomic)Contact *whoseEvent;
@property(weak,nonatomic)id<EventContentUpdatingDelegate>delegate;

@end
