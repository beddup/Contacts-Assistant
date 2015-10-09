//
//  ContactsUnderSameTagViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/28/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ContactsUnderSameTagViewController.h"
#import "Contact.h"
#import "Tag+Utility.h"
#import "ContactsManager.h"
@interface ContactsUnderSameTagViewController ()

@property(copy,nonatomic)NSArray *contacts;
@property(copy,nonatomic)NSArray *tags;

@end

@implementation ContactsUnderSameTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureTableView];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)setContact:(Contact *)contact{
    _contact=contact;
    NSMutableArray *tagsOfContact=[[contact.underWhichTags allObjects] mutableCopy];
    [tagsOfContact removeObject:[Tag rootTag]];
    [self configureDateSource:tagsOfContact];
}

-(void)configureDateSource:(NSArray *)tags{

    NSMutableArray *otherContacts=[@[] mutableCopy];
    NSMutableArray *tagsWhichHasOtherContacts=[@[] mutableCopy];
    for (Tag *tag in tags) {
        NSMutableArray *contactsUnderTag=[[tag.ownedContacts allObjects] mutableCopy];
        [contactsUnderTag removeObject:self.contact];

        if (contactsUnderTag.count) {
            [contactsUnderTag sortUsingComparator:^NSComparisonResult(Contact * obj1, Contact * obj2) {
                return [[ContactsManager sharedContactManager]compareResult:obj1 contact2:obj2];
            }];
            [otherContacts addObject:contactsUnderTag];
            [tagsWhichHasOtherContacts addObject:tag];
        }
    }

    self.contacts=otherContacts;
    self.tags=tagsWhichHasOtherContacts;

}
-(void)configureTableView{
    if (!self.contacts.count) {
        UILabel *noResultLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, CGRectGetHeight(self.view.bounds)/2)];
        self.tableView.tableHeaderView=noResultLabel;
        noResultLabel.text=@"无联系人";
        noResultLabel.textColor=[UIColor lightGrayColor];
        noResultLabel.textAlignment=NSTextAlignmentCenter;
        noResultLabel.font=[UIFont systemFontOfSize:20];
        self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    }else{
        self.tableView.tableHeaderView=nil;
        self.tableView.separatorStyle=UITableViewCellSeparatorStyleSingleLine;
    }

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.contacts.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.contacts[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"contact cell"];
    if (!cell) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"contact cell"];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor=[UIColor grayColor];
    }
    Contact *contact= self.contacts[indexPath.section][indexPath.row];
    cell.textLabel.text=contact.contactName;
    return cell;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    Tag *tag=self.tags[section];
    return tag.tagName;
}



@end
