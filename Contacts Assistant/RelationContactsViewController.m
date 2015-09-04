
//
//  RelationContactsTableViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/26/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "RelationContactsViewController.h"
#import "Contact+Utility.h"
@interface RelationContactsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation RelationContactsViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    [self configureNavigationBar];

}

-(void)configureNavigationBar{
    UIBarButtonItem *barbutton=[[UIBarButtonItem alloc]initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(contactsSelected:)];
    self.navigationItem.rightBarButtonItem=barbutton;
    self.title=@"选择联系人";
}

-(void)contactsSelected:(UIBarButtonItem *)barbutton{
    [self performSegueWithIdentifier:@"relationContactsSelected" sender:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
