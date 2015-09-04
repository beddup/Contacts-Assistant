
//
//  ChooseContactsViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/26/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ChooseContactsViewController.h"
#import "ContactsManager.h"
#import "Contact.h"

NSString *const CellIdentifier=@"contact cell";

@interface ChooseContactsViewController ()


@end

@implementation ChooseContactsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.contacts=[ContactsManager sharedContactManager].arrangedAllContacts;
    self.indexTitles=[[ContactsManager sharedContactManager] indexTitleOfContact:self.contacts];

    // Do any additional setup after loading the view.
}
-(NSMutableArray *)contactsSelected{
    if (!_contactsSelected) {
        _contactsSelected=[@[] mutableCopy];
    }
    return _contactsSelected;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.indexTitles.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.contacts[section] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Contact *contact=[self.contacts[indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.text=contact.contactName;

    if ( [self.contactsSelected containsObject:contact] ) {

        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        cell.accessoryType=UITableViewCellAccessoryCheckmark;

    }else{

        cell.accessoryType=UITableViewCellAccessoryNone;

    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Contact *contact=[self.contacts[indexPath.section] objectAtIndex:indexPath.row];
    [self.contactsSelected addObject:contact];

    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryCheckmark;

}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{

    Contact *contact=[self.contacts[indexPath.section] objectAtIndex:indexPath.row];
    [self.contactsSelected removeObject:contact];

    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryNone;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{

    NSString *title=self.indexTitles[section];

    if ([title isEqualToString:@"☆"]) {
        NSMutableString *string=[@"" mutableCopy];
        for (int i =0 ; i< [(NSArray *)self.contacts[1] count]; i++) {
            [string appendString:title];
        }
        return string;
    }
    return title;
}
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    return self.indexTitles;
}
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    return index;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
