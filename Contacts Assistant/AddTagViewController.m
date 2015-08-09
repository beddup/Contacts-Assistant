//
//  AddTagViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/26/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "AddTagViewController.h"
#import "Tag+Utility.h"
#import "TagCell.h"
@interface AddTagViewController ()<UITextFieldDelegate>

@property(strong,nonatomic)NSMutableArray *arrangedTags;

@property(weak,nonatomic)UIBarButtonItem *addTagButton;

@property(weak,nonatomic)UITextField *createNewTagTF;

@end

@implementation AddTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"请选择标签";

    UIBarButtonItem *barbutton=[[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    self.addTagButton=barbutton;
    self.navigationItem.rightBarButtonItem=barbutton;

    [self configureTableHeaderView];
    // Do any additional setup after loading the view.
}
-(void)configureTableHeaderView{
    // configure header view to create new tag
    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 44)];
    view.backgroundColor=[UIColor lightGrayColor];

    UITextField *createNewTagTF=[[UITextField alloc]initWithFrame:CGRectMake(self.tableView.separatorInset.left, 4, CGRectGetWidth(self.tableView.bounds)-self.tableView.separatorInset.left, 36)];

    [view addSubview:createNewTagTF];
    createNewTagTF.placeholder=@"新建标签";
    createNewTagTF.delegate=self;
    createNewTagTF.returnKeyType=UIReturnKeyDone;
    createNewTagTF.delegate=self;
    self.createNewTagTF=createNewTagTF;
    [self.createNewTagTF setBackground:[UIImage imageNamed:@"TagViewUnSelectedBKG"]];
    self.tableView.tableHeaderView=view;

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TFChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}
-(void)TFChanged:(NSNotification *)notificaiton{

}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    BOOL flag=[Tag tagExists:textField.text];
    if (flag) {
        return NO;
    }
    [textField resignFirstResponder];
    textField.text=@"";
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (![Tag tagExists:textField.text]) {
        Tag *tag=[Tag getTagWithTagName:textField.text];
        [self.arrangedTags[1] insertObject:tag atIndex:0];
    }
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];

}
-(void)setContact:(Contact *)contact{

    _contact=contact;

    NSArray *allTags=[Tag allTags] ;
    NSArray *selectedTags=[[[contact.underWhichTags allObjects] sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
        return  [obj1.tagName compare:obj2.tagName];
    }]mutableCopy];

    NSArray *tagNames=[selectedTags valueForKey:@"tagName"];
    NSArray *otherTags = [[allTags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT tagName IN %@",tagNames]] mutableCopy];
    NSArray *sortedOtherTags=[[otherTags sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
        return  [obj1.tagName compare:obj2.tagName];
    }] mutableCopy];

    self.arrangedTags= [@[selectedTags,sortedOtherTags] mutableCopy];

}


-(void)done:(UIBarButtonItem *)barbutton{

    self.contact.underWhichTags = [NSSet setWithArray:self.arrangedTags[0]];
    [self performSegueWithIdentifier:@"tagsAdded" sender:nil];

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

    NSMutableArray *selectedTags=self.arrangedTags[0];
    NSMutableArray *otherTags=self.arrangedTags[1];


    Tag *tag=otherTags[indexPath.row];
    [selectedTags insertObject:tag atIndex:0];
    [otherTags removeObjectAtIndex:indexPath.row];

    //re order
    self.arrangedTags[0]=[[selectedTags sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
        return [obj1.tagName compare:obj2.tagName];
    }] mutableCopy];
    NSInteger index=[self.arrangedTags[0] indexOfObject:tag];

    [tableView moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];

}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSMutableArray *selectedTags=self.arrangedTags[0];
    NSMutableArray *otherTags=self.arrangedTags[1];

    Tag *tag=selectedTags[indexPath.row];
    [otherTags insertObject:tag atIndex:0];
    [selectedTags removeObjectAtIndex:indexPath.row];
    //re order
    self.arrangedTags[1]=[[otherTags sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
        return [obj1.tagName compare:obj2.tagName];
    }] mutableCopy];
    NSInteger index=[self.arrangedTags[1] indexOfObject:tag];

    [tableView moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:index inSection:1]];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //To enable the swipe-to-delete feature of table views (wherein a user swipes horizontally across a row to display a Delete button), you must implement this method
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Tag *tag=[self.arrangedTags[indexPath.section] objectAtIndex:indexPath.row];
         if(indexPath.section == 0 ){
             [self.contact removeUnderWhichTagsObject:tag];
         }
        [self.arrangedTags[indexPath.section] removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
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
