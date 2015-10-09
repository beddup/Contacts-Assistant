//
//  AddContactsToTagViewController.m
//  Contacts Assistant
//
//  Created by Amay on 9/8/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "AddContactsToTagViewController.h"
#import "AppDelegate.h"
@interface AddContactsToTagViewController()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end


@implementation AddContactsToTagViewController

-(void)viewDidLoad{

    [super viewDidLoad];
    [self configureNavigaitonBar];

}
-(void)setTag:(Tag *)tag{
    _tag=tag;
    self.contactsSelected=[[tag.ownedContacts allObjects] mutableCopy];
    [self.tableView reloadData];

}
-(void)configureNavigaitonBar{

    self.title=self.tag.tagName;
    UIBarButtonItem *barbutton=[[UIBarButtonItem alloc]initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(done:)];
    self.navigationItem.rightBarButtonItem=barbutton;

}


-(void)done:(UIBarButtonItem *)barbutton{

    self.tag.ownedContacts=[NSSet setWithArray:self.contactsSelected];

    [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
    [self performSegueWithIdentifier:@"AddContactsDone" sender:nil];
    
}

@end
