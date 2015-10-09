//
//  ContactDetailsViewController.h
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"

@protocol ContactDetailsUpdatingDelegate <NSObject>

@optional
-(void)contactInfoChanged;
-(void)relationsChanged;
-(void)eventsChanged;

@end

@interface ContactDetailsViewController : UIViewController <ContactDetailsUpdatingDelegate>

@property(strong,nonatomic)Contact *contact;
@property(copy,nonatomic)NSIndexPath *indexPath;




@end
