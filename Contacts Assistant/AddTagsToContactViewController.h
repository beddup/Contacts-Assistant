//
//  AddTagViewController.h
//  Contacts Assistant
//
//  Created by Amay on 7/26/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"
#import "TagsTableViewController.h"
@interface AddTagsToContactViewController : TagsTableViewController

@property(strong,nonatomic)Contact *contact;

@end
