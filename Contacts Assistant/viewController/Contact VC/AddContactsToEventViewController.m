//
//  ChangeEventContactsViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/1/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "AddContactsToEventViewController.h"
#import "NSMutableArray+ArrangedContacts.h"
#import "ContactsManager.h"
#import "Contact+Utility.h"
#import "EventViewController.h"


@interface AddContactsToEventViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *selectedContactNamesTextView;

@end

@implementation AddContactsToEventViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    [self confirgureDataSource];
    [self configureSelectedContactsTextView];

    // Do any additional setup after loading the view.
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)confirgureDataSource{
    
    self.contacts=[[ContactsManager sharedContactManager] arrangedAllContacts];
    self.indexTitles=[[ContactsManager sharedContactManager] indexTitleOfContacts:self.contacts];

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

# pragma mark - table view
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[super tableView:tableView cellForRowAtIndexPath:indexPath];
    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    if ([contact.contactID isEqualToNumber:self.whoseEvent.contactID]) {
        cell.textLabel.textColor=[UIColor lightGrayColor];
    }else{
        cell.textLabel.textColor=[UIColor blackColor];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    if ([contact.contactID isEqualToNumber:self.whoseEvent.contactID]) {
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self updateSelectedContactNamesTV];

}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{

    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    if ([contact.contactID isEqualToNumber:self.whoseEvent.contactID]) {
        return;
    }
    [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
    [self updateSelectedContactNamesTV];

}


- (IBAction)addContactsDone:(id)sender {
    
    [self.delegate eventRelatedPeopleChanged:self.contactsSelected];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
