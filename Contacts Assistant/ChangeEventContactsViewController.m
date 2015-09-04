//
//  ChangeEventContactsViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/1/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ChangeEventContactsViewController.h"
#import "ContactsManager.h"
#import "Contact+Utility.h"

@interface ChangeEventContactsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *selectedContactNamesTextView;

@end

@implementation ChangeEventContactsViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.contacts=[ContactsManager sharedContactManager].arrangedAllContacts;
    self.indexTitles=[[ContactsManager sharedContactManager] indexTitleOfContact:self.contacts];
    self.contactsSelected=[[self.event.contactsWhichAttend allObjects] mutableCopy];

    self.tableView.tableHeaderView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 75)];
    [self configureSelectedContactsTextView];

    // Do any additional setup after loading the view.
}

-(void)configureSelectedContactsTextView{

    self.selectedContactNamesTextView.textContainerInset=UIEdgeInsetsMake(8, 8, 0, 0);
    self.tableView.sectionIndexBackgroundColor=[UIColor clearColor];
    [self updateSelectedContactNamesTV];

}
-(void)updateSelectedContactNamesTV{

    if (!self.contactsSelected.count) {
        self.selectedContactNamesTextView.text=@"无相关人员";
    }else{
        NSArray *selectedNames=[self.contactsSelected valueForKey:@"contactName"];
        NSString *string=[@"已选择的相关人员:\n" stringByAppendingString:[selectedNames componentsJoinedByString:@", "]];
        self.selectedContactNamesTextView.text=string;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - table view

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self updateSelectedContactNamesTV];

}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{

    [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
    [self updateSelectedContactNamesTV];

}


- (IBAction)addContactsDone:(id)sender {
    
    self.event.contactsWhichAttend = [NSSet setWithArray:self.contactsSelected];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
