//
//  EventsViewController.h
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"


@interface DisplayEventViewController : UIViewController

@property(strong,nonatomic)Contact *contact;
@property(strong,nonatomic)Event *event;


@end
