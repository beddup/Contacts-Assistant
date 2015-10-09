//
//  TagsTableViewController.m
//  Contacts Assistant
//
//  Created by Amay on 9/6/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ManageTagsTableViewController.h"
#import "Tag+Utility.h"
#import "TagCell.h"
#import "AppDelegate.h"
#import "AddContactsToTagViewController.h"
#import "NSString+ContactsAssistant.h"
@interface ManageTagsTableViewController()<UITextFieldDelegate>

@property(strong,nonatomic)NSMutableArray *tags;

@property(strong,nonatomic)UITableViewRowAction *renameAction;
@property(strong,nonatomic)UITableViewRowAction *deleteAction;
@property(strong,nonatomic)UIAlertAction *renameOkAlertAction;
@property(weak,nonatomic)UITextField *renameTF;

@end


@implementation ManageTagsTableViewController
-(void)viewDidLoad{
    [super viewDidLoad];
    [self configureNavigationBar];
}

-(void)configureNavigationBar{
    self.title=@"管理标签";
    UIBarButtonItem *barButton=[[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(finished:)];
    self.navigationItem.rightBarButtonItem=barButton;
}

-(void)finished:(UIBarButtonItem *)barbutton{

    [self performSegueWithIdentifier:@"FinishManagingTags" sender:nil];
}

-(CGFloat)heightOfTableHeaderView{
    return 80;
}

-(void)TFChanged:(UITextField *)tf{
    if (tf == self.renameTF) {
        self.renameOkAlertAction.enabled=[tf.text whiteSpaceTrimmedLength];
    }
}

-(void)didCreateNewTag:(Tag *)tag{
    [self.tags insertObject:tag atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

}


-(NSMutableArray *)tags{
    if (!_tags) {
        _tags = [[Tag allTagsSortedByOwnedContactsCountAndTagName]mutableCopy];
        [_tags removeObject:[Tag rootTag]];
    }
    return _tags;
}

#pragma  mark - table view
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.tags.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier=@"Tag Cell Identifier";

    TagCell *cell=(TagCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell=[[TagCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    [(TagCell *)cell setHasCloseButton:NO];
    cell.myTag = self.tags[indexPath.row];

    return cell;

}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 54.0;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"所有标签";
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Contact *contact= self.tags[indexPath.row];
    [self performSegueWithIdentifier:@"AddContacts" sender:contact];

}
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //To enable the swipe-to-delete feature of table views (wherein a user swipes horizontally across a row to display a Delete button), you must implement this method
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @[self.deleteAction,self.renameAction];
}
-(UITableViewRowAction *)renameAction{
    if (!_renameAction) {
        _renameAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"重命名" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            Tag *tag=self.tags[indexPath.row];
            UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"请输入标签新名称" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {

                textField.placeholder=tag.tagName;
                textField.font=[UIFont systemFontOfSize:17];
                self.renameTF=textField;
            }];

            UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self.renameTF resignFirstResponder];
            }];
            UIAlertAction *okAction=[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                UITextField *textField=[alertController.textFields firstObject];
                tag.tagName=textField.text;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
            }];
            self.renameOkAlertAction=okAction;
            okAction.enabled=NO;
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];

            [self presentViewController:alertController animated:YES completion:nil];
        }];
        _renameAction.backgroundColor=[UIColor orangeColor];
    }
    return _renameAction;
}

-(UITableViewRowAction *)deleteAction{
    if (!_deleteAction) {
        _deleteAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            Tag *tag=self.tags[indexPath.section];
            [self.tags removeObjectAtIndex:indexPath.row];
            [tag.managedObjectContext deleteObject:tag];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
        }];
    }
    return _deleteAction;
}

#pragma  mark - navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"AddContacts"]) {
        AddContactsToTagViewController *dsvc=segue.destinationViewController;
        Tag *tag=(Tag *)sender;
        dsvc.tag=tag;
    }

}
-(IBAction)addContactsDone:(UIStoryboardSegue *)segue{

    AddContactsToTagViewController *svc=(AddContactsToTagViewController *)segue.sourceViewController;
    Tag *tag=svc.tag;
    NSInteger row=[self.tags indexOfObject:tag];
    NSIndexPath *indexPath=[NSIndexPath indexPathForItem:row inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];


}
@end
