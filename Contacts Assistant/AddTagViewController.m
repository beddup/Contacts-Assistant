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
#import "AppDelegate.h"
@interface AddTagViewController ()<UITextFieldDelegate>

@property(strong,nonatomic)NSMutableArray *arrangedTags;

@property(weak,nonatomic)UIBarButtonItem *addTagButton;

@property(weak,nonatomic)UITextField *createNewTagTF;

@property(strong,nonatomic)UIImage *createNewTagTFBKGImage;

@property(weak,nonatomic)UILabel *tagCountLabel;

@property(strong,nonatomic)UITableViewRowAction *renameAction;
@property(strong,nonatomic)UIAlertAction *renameOkAlertAction;
@property(weak,nonatomic)UITextField *renameTF;

@property(strong,nonatomic)UITableViewRowAction *deleteAction;


@end

@implementation AddTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"请选择标签";

    [self configureNavigationBar];
    [self configureTableHeaderView];

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
-(UIImage *)createNewTagTFBKGImage{
    if (!_createNewTagTFBKGImage) {
        UIImage *image=[UIImage imageNamed:@"TagViewUnSelectedBKG"];
        _createNewTagTFBKGImage=[image resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 16) resizingMode:UIImageResizingModeStretch];
    }
    return _createNewTagTFBKGImage;
}
-(void)resetNewTagTF{
    self.createNewTagTF.text=nil;
    self.createNewTagTF.frame=[self frameOfNewTagTF];
}
-(CGRect)frameOfNewTagTF{

    NSAttributedString *attributedstring=self.createNewTagTF.attributedText;
    if (!attributedstring.length) {
       attributedstring =[[NSAttributedString alloc]initWithString:self.createNewTagTF.placeholder attributes:@{NSFontAttributeName:self.createNewTagTF.font}];
    }
    CGFloat width= attributedstring.size.width + 20 +16 ;
    width = width > CGRectGetWidth(self.tableView.bounds)-30 ? CGRectGetWidth(self.tableView.bounds)-30 : width;

    CGRect rect=CGRectMake(self.tableView.separatorInset.left, 8, width, 36);
    return rect;

}
-(void)configureTableHeaderView{
    // configure header view to create new tag
    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 36)];
    self.tableView.tableHeaderView=view;

    UITextField *createNewTagTF=[[UITextField alloc]init];
    [view addSubview:createNewTagTF];
    self.createNewTagTF=createNewTagTF;

    createNewTagTF.placeholder=@"创建一个标签";
    createNewTagTF.returnKeyType=UIReturnKeyDone;
    createNewTagTF.delegate=self;

    createNewTagTF.frame=[self frameOfNewTagTF];

    [self.createNewTagTF setBackground:self.createNewTagTFBKGImage];

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

    UITextField *textField=notificaiton.object;
    if (textField== self.createNewTagTF) {
        self.createNewTagTF.frame=[self frameOfNewTagTF];
    }else if (textField==self.renameTF){
        self.renameOkAlertAction.enabled=textField.text.length;
    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{

    if (textField == self.createNewTagTF) {
        NSString *newTagName=[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!newTagName.length) {
            return NO;
        }
        BOOL flag=[Tag tagExists:newTagName];
        if (flag) {
            return NO;
        }
        Tag *tag=[Tag getTagWithTagName:newTagName];
        [self.arrangedTags[1] insertObject:tag atIndex:0];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];

        [textField resignFirstResponder];
    }
    return YES;
}


-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.createNewTagTF) {
        [self resetNewTagTF];
    }
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
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];

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


-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //To enable the swipe-to-delete feature of table views (wherein a user swipes horizontally across a row to display a Delete button), you must implement this method
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @[self.deleteAction,self.renameAction];
}

-(UITableViewRowAction *)renameAction{
    if (!_renameAction) {
        _renameAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"重命名" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            Tag *tag=[self.arrangedTags[indexPath.section] objectAtIndex:indexPath.row];
            UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"请输入标签新名称" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {

                textField.borderStyle=UITextBorderStyleRoundedRect;
                textField.placeholder=tag.tagName;
                textField.font=[UIFont systemFontOfSize:17];
                self.renameTF=textField;
            }];

            UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [[alertController.textFields firstObject] resignFirstResponder];
            }];
            UIAlertAction *okAction=[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                UITextField *textField=[alertController.textFields firstObject];
                tag.tagName=textField.text;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
                Tag *tag=[self.arrangedTags[indexPath.section] objectAtIndex:indexPath.row];
//                if(indexPath.section == 0 ){
//                    [self.contact removeUnderWhichTagsObject:tag];
//                }
                [self.arrangedTags[indexPath.section] removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [tag.managedObjectContext deleteObject:tag];
            [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
        }];
    }
    return _deleteAction;
}


@end
