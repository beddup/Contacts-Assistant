//
//  AddTagViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/26/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "AddTagsToContactViewController.h"
#import "Tag+Utility.h"
#import "TagCell.h"
#import "AppDelegate.h"
@interface AddTagsToContactViewController ()

@property(strong,nonatomic)NSMutableArray *arrangedTags;

@property(weak,nonatomic)UIBarButtonItem *addTagButton;


@property(weak,nonatomic)UILabel *tagCountLabel;


@end

@implementation AddTagsToContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"请选择标签";

    [self configureNavigationBar];

    self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;
    // Do any additional setup after loading the view.
}
-(void)configureNavigationBar{

    UIBarButtonItem *barbutton=[[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    self.addTagButton=barbutton;
    self.navigationItem.rightBarButtonItem=barbutton;

    UIBarButtonItem *cancelbutton=[[UIBarButtonItem alloc]initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss:)];
    self.navigationItem.leftBarButtonItem=cancelbutton;


}


-(void)didCreateNewTag:(Tag *)tag{
    [self.arrangedTags[1] insertObject:tag atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
}

-(void)setContact:(Contact *)contact{

    _contact=contact;

    NSArray *allTags=[Tag allTags];
    NSMutableArray *selectedTags=[[[contact.underWhichTags allObjects] sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
        return  obj1.ownedContacts.count <= obj2.ownedContacts.count;
    }]mutableCopy];
    [selectedTags removeObject:[Tag rootTag]];

    NSArray *tagNames=[selectedTags valueForKey:@"tagName"];

    NSArray *otherTags = [[allTags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT tagName IN %@",tagNames]] mutableCopy];
    NSMutableArray *sortedOtherTags=[[otherTags sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
        return  obj1.ownedContacts.count <= obj2.ownedContacts.count;
    }] mutableCopy];
    [sortedOtherTags removeObject:[Tag rootTag]];

    self.arrangedTags= [@[selectedTags,sortedOtherTags] mutableCopy];

}

-(void)dismiss:(UIBarButtonItem *)barbutton{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
-(void)done:(UIBarButtonItem *)barbutton{

    self.contact.underWhichTags = [NSSet setWithArray:self.arrangedTags[0]];
    [self.contact addUnderWhichTagsObject:[Tag rootTag]];
    [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
    [self performSegueWithIdentifier:@"tagAdded" sender:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  mark - table

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.arrangedTags[section] count];

}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 60;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
    return [NSString stringWithFormat:@"%@的标签",self.contact.contactName];
    }else{
        return @"其他标签";
    }

}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    TagCell *cell=(TagCell *)[tableView dequeueReusableCellWithIdentifier:@"tag cell"];
    if (!cell) {
        cell=[[TagCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tag cell"];
        [(TagCell *)cell setHasCloseButton:NO];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
        cell.separatorInset=UIEdgeInsetsMake(0, 15, 0, 15);
    }
    cell.myTag = [self.arrangedTags[indexPath.section] objectAtIndex:indexPath.row];
    if (indexPath.section == 0) {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.section == 1) {
        NSMutableArray *selectedTags=self.arrangedTags[0];
        NSMutableArray *otherTags=self.arrangedTags[1];
        // update data source
        Tag *tag=otherTags[indexPath.row];
        [selectedTags insertObject:tag atIndex:0];
        [otherTags removeObjectAtIndex:indexPath.row];
        // update table view
        [tableView moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        self.tagCountLabel.text=[@([self.arrangedTags[0] count]) stringValue];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 ) {
        NSMutableArray *selectedTags=self.arrangedTags[0];
        NSMutableArray *otherTags=self.arrangedTags[1];
        // update datasource
        Tag *tag=selectedTags[indexPath.row];
        [otherTags insertObject:tag atIndex:0];
        [selectedTags removeObjectAtIndex:indexPath.row];
        // update table view

        [tableView moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        self.tagCountLabel.text=[@([self.arrangedTags[0] count]) stringValue];
    }
}



@end
