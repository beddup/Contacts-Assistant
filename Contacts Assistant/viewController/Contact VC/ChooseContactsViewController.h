//
//  ChooseContactsViewController.h
//  Contacts Assistant
//
//  Created by Amay on 8/26/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const CellIdentifier;

@interface ChooseContactsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property(strong,nonatomic)NSMutableArray *contactsSelected;

@property(copy,nonatomic)NSArray *contacts;
@property(copy,nonatomic)NSArray *indexTitles;

@end
