//
//  AddEventViewController.h
//  Contacts Assistant
//
//  Created by Amay on 7/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

@interface EventViewController : UIViewController

@property(strong,nonatomic) Event * event;

@property(nonatomic)BOOL forDisplay;

@end
