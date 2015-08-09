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

@interface ChangeEventContactsViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(strong,nonatomic)NSArray *contacts;

@property(strong,nonatomic)NSMutableArray *selectedContacts;

@end

@implementation ChangeEventContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contacts=[Contact allContacts];
    self.selectedContacts=[[self.event.contactsWhichAttend allObjects] mutableCopy];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
-(NSMutableArray *)selectedContacts{
    if (!_selectedContacts) {
        _selectedContacts=[@[] mutableCopy];
    }
    return _selectedContacts;
}

# pragma mark - table view
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.contacts.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"contact"];

    Contact *contact=self.contacts[indexPath.row];
    cell.textLabel.text=contact.contactName;

    if ([self.selectedContacts containsObject:contact] ) {

        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        cell.accessoryType=UITableViewCellAccessoryCheckmark;

    }else{

        cell.accessoryType=UITableViewCellAccessoryNone;

    }


    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    [self.selectedContacts addObject:self.contacts[indexPath.row]];

    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryCheckmark;

}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{

    [self.selectedContacts removeObject:self.contacts[indexPath.row]];

    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryNone;

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"contactsChangeDone"]) {

        self.event.contactsWhichAttend = [NSSet setWithArray:self.selectedContacts];

    }
}

/*

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
