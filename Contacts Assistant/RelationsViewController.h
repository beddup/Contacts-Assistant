//
//  RelationsViewController.h
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Contact;
@protocol ContactDetailsUpdatingDelegate;
@interface RelationsViewController : UIViewController

@property(strong,nonatomic)Contact *contact;
@property(weak,nonatomic)id<ContactDetailsUpdatingDelegate>delegate;

@end
