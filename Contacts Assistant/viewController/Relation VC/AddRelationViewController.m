
//
//  AddRelationViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/26/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "AddRelationViewController.h"
#import "Contact+Utility.h"
#import "AddContactsToRelationViewController.h"
#import "ContactsManager.h"
#import "Relation.h"
#import "defines.h"
#import "NSString+ContactsAssistant.h"
#import "NSString+ContactsAssistant.h"
@interface AddRelationViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableview;

@property(strong,nonatomic)NSMutableArray *relationContacts;

@property(weak,nonatomic)UIView *relationContactsView;
@property(weak,nonatomic)UILabel *isLabel;
@property(weak,nonatomic)UITextField *relationTF;

@end

@implementation AddRelationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableview.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;

    [self configureNavigationBar];
    [self configureTableHeaderView];
    // Do any additional setup after loading the view.
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - navigation bar items and actions
-(void)configureNavigationBar{

    UIBarButtonItem *cancelItem=[[UIBarButtonItem alloc]initWithTitle:@"取消"
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(dismiss:)];
    self.navigationItem.leftBarButtonItem=cancelItem;

    UIBarButtonItem *finishItem=[[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];
    self.navigationItem.rightBarButtonItem=finishItem;
    finishItem.enabled=NO;

    self.navigationItem.title=@"创建关联";

}
-(void)dismiss:(UIBarButtonItem *)barbutton{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
-(void)finish:(UIBarButtonItem *)barbutton{

    [self.contact addRelation:[self.relationTF.text whiteSpaceAtEndsTrimmedString] WithContacts:self.relationContacts];
    [self performSegueWithIdentifier:@"finishAddRelation" sender:nil];
}

#pragma mark - property
-(NSMutableArray *)relationContacts{
    if (!_relationContacts) {
        _relationContacts=[@[] mutableCopy];
    }
    return _relationContacts;
}

#pragma mark -table header view
-(void)configureTableHeaderView{

    UIView *tableHearderView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, MAX(400, CGRectGetHeight(self.view.bounds)))];
    self.tableview.tableHeaderView=tableHearderView;
    // contact view
    UIView *contactView=[[UIView alloc]initWithFrame:CGRectMake(8, 8, 80, 80)];
    [tableHearderView addSubview:contactView];
    contactView.backgroundColor=[UIColor orangeColor];
    contactView.layer.cornerRadius=CGRectGetWidth(contactView.bounds)/2;
    UILabel *contactLabel=[[UILabel alloc]initWithFrame:contactView.bounds];
    contactLabel.textAlignment=NSTextAlignmentCenter;
    contactLabel.text=self.contact.contactName;
    contactLabel.textColor=[UIColor whiteColor];
    [contactView addSubview:contactLabel];

    // connecting line
    UIView *connectionView=[[UIView alloc]initWithFrame:CGRectMake(CGRectGetMidX(contactView.frame), CGRectGetMaxY(contactView.frame), 1, 100)];
    connectionView.backgroundColor=[UIColor lightGrayColor];
    [tableHearderView addSubview:connectionView];

    // 的label;
    UILabel *label1=[[UILabel alloc]initWithFrame:CGRectMake(0,0,30, 30)];
    label1.center=CGPointMake(CGRectGetMaxX(connectionView.frame)+8+CGRectGetWidth(label1.bounds)/2, CGRectGetMidY(connectionView.frame));
    label1.text=@"的";
    label1.textColor=[UIColor lightGrayColor];
    label1.font=[UIFont systemFontOfSize:20 weight:UIFontWeightLight];
    [tableHearderView addSubview:label1];

    // relation TF
    UITextField *tf=[[UITextField alloc]initWithFrame:CGRectMake(CGRectGetMaxX(label1.frame)+8, CGRectGetMinY(label1.frame), 200, 30)];
    tf.placeholder=@"什么关系?";
    tf.delegate=self;
    tf.font=[UIFont systemFontOfSize:18];
    tf.textColor=[UIColor orangeColor];
    [tableHearderView addSubview:tf];
    self.relationTF=tf;
    // tf line view
    UIView *tfUnderlineView=[[UIView alloc]initWithFrame:CGRectMake(CGRectGetMinX(tf.frame), CGRectGetMaxY(tf.frame), CGRectGetWidth(tf.frame), 0.5)];
    tfUnderlineView.backgroundColor=[UIColor lightGrayColor];
    [tableHearderView addSubview:tfUnderlineView];

    // 是label
    UILabel *label2=[[UILabel alloc]initWithFrame:CGRectMake(0,0,30,30)];
    self.isLabel=label2;
    label2.center=CGPointMake(label1.center.x, CGRectGetMaxY(connectionView.frame));
    label2.text=@"是";
    label2.textColor=[UIColor lightGrayColor];
    label2.font=[UIFont systemFontOfSize:20 weight:UIFontWeightLight];
    [tableHearderView addSubview:label2];

    //relationContactsView
    UIView *relationContactsView=[[UIView alloc]initWithFrame:CGRectMake(CGRectGetMinX(connectionView.frame), CGRectGetMaxY(label2.frame)+8, 200, 200)];
    [tableHearderView addSubview: relationContactsView];
    self.relationContactsView=relationContactsView;

    [self contigureRelationContactsView];

}

#pragma mark RelationContactsView
static CGFloat RelationContactViewSideLength = 70;
-(void)contigureRelationContactsView{

    [self.relationContactsView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)
                                                        withObject:nil];
    CGRect frameOfContactsView=self.relationContactsView.frame;
    CGFloat maxX=CGRectGetWidth(self.tableview.bounds)-CGRectGetMinX(frameOfContactsView)-8;
    CGRect nextRelationContactViewRect=CGRectMake(0, 0, RelationContactViewSideLength, RelationContactViewSideLength);

    for (Contact *contact in self.relationContacts) {

        UIView *view=[[UIView alloc]initWithFrame:nextRelationContactViewRect];
        view.backgroundColor=[UIColor orangeColor];
        view.layer.cornerRadius=RelationContactViewSideLength/2;
        [self.relationContactsView addSubview:view];

        UILabel *label=[[UILabel alloc]initWithFrame:view.bounds];
        label.text=contact.contactName;
        label.textColor=[UIColor whiteColor];
        label.textAlignment=NSTextAlignmentCenter;
        label.numberOfLines=2;
        [view addSubview:label];

        nextRelationContactViewRect=CGRectMake(CGRectGetMaxX(nextRelationContactViewRect)+8, CGRectGetMinY(nextRelationContactViewRect), RelationContactViewSideLength, RelationContactViewSideLength);
        if (CGRectGetMaxX(nextRelationContactViewRect) > maxX) {
            nextRelationContactViewRect=CGRectMake(0, CGRectGetMaxY(view.frame)+8, RelationContactViewSideLength, RelationContactViewSideLength);
        }
    }
    // add contact button

    UIButton *addContactButton=[[UIButton alloc]initWithFrame:nextRelationContactViewRect];
    addContactButton.layer.cornerRadius=RelationContactViewSideLength/2;
    addContactButton.layer.borderWidth=1.0;
    addContactButton.layer.borderColor=[IconColor CGColor];
    [addContactButton setTitleColor:IconColor forState:UIControlStateNormal];
    addContactButton.titleLabel.numberOfLines=2;
    addContactButton.titleLabel.textAlignment=NSTextAlignmentCenter;
    addContactButton.titleLabel.font=[UIFont systemFontOfSize:15 weight:UIFontWeightLight];
    [addContactButton setTitle:@"选择\n联系人" forState:UIControlStateNormal];
    [addContactButton addTarget:self action:@selector(addContact:) forControlEvents:UIControlEventTouchUpInside];
    [self.relationContactsView addSubview:addContactButton];

    // change other view
    CGRect frameOfTableHeaderView=self.tableview.tableHeaderView.frame;

    self.tableview.tableHeaderView.frame=CGRectMake(CGRectGetMinX(frameOfTableHeaderView),CGRectGetMinY(frameOfTableHeaderView),CGRectGetWidth(frameOfTableHeaderView),CGRectGetMinY(frameOfContactsView)+CGRectGetMaxY(addContactButton.frame));
    self.tableview.tableHeaderView=self.tableview.tableHeaderView;

    self.isLabel.text=self.relationContacts.count>1 ?  @"有":@"是";


}

-(void)addContact:(UIButton *)button{
    [self performSegueWithIdentifier:@"relationContacts" sender:nil];
}


#pragma mark -navigation
-(BOOL)canFinish{
    if (![self.relationTF.text whiteSpaceTrimmedLength]) {
        return NO;
    }
    if (!self.relationContacts.count) {
        return NO;
    }
    return YES;
}
-(IBAction)relationContactsSelected:(UIStoryboardSegue *)segue{

    AddContactsToRelationViewController *dsvc=(AddContactsToRelationViewController *)segue.sourceViewController;
    self.relationContacts=dsvc.contactsSelected;
    [self.relationContacts removeObject:self.contact];
    self.navigationItem.rightBarButtonItem.enabled=[self canFinish];
    [self contigureRelationContactsView];

}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"relationContacts"]) {
        UINavigationController *nav=(UINavigationController *)segue.destinationViewController;
        AddContactsToRelationViewController *dsvc=[nav.viewControllers firstObject];
        dsvc.contactsSelected=[self.relationContacts mutableCopy];
    }
}

#pragma  mark -textFielDelegate
-(void)textFieldDidEndEditing:(UITextField *)textField{
    self.navigationItem.rightBarButtonItem.enabled=[self canFinish];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{

    [textField resignFirstResponder];
    return YES;

}
@end
