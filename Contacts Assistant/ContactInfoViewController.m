//
//  ContactInfoViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ContactInfoViewController.h"
#import "ContactsManager.h"

@interface ContactInfoViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *contactInfoTF;
@property (weak, nonatomic) IBOutlet UITextField *contactTypeTF;

@property(nonatomic)BOOL isPhone;

@property(strong,nonatomic)UIActivityViewController *activityVC;


@end

@implementation ContactInfoViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    [self configureTF];
    [self configureNavigationBar];
    [self configureActivityVC];
}

-(UIButton *)shareButton{
    UIButton *shareContact=[[UIButton alloc]initWithFrame:CGRectMake(0,0,0,44)];
    [shareContact setTitle:@"共享联系方式" forState:UIControlStateNormal];
    [shareContact.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [shareContact setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [shareContact addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    return shareContact;
}
-(UIButton *)deleteButton{
    UIButton *deleteButton=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 0, 44)];
    [deleteButton setTitle:@"删除联系方式" forState:UIControlStateNormal];
    [deleteButton.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
    return deleteButton;
}

-(void)configureTabelFooterView{
    self.tableView.tableFooterView=[self shareButton];
}

-(void)configureActivityVC{

    dispatch_queue_t activityQueue = dispatch_queue_create("activityQueue", NULL);
    dispatch_async(activityQueue, ^{
        NSString *contactInfo=[NSString stringWithFormat:@"姓名:%@, ",self.contact.contactName];
        contactInfo=[contactInfo stringByAppendingString:self.contactInfo[ContactInfoValueKey]];
        UIActivityViewController *activityVC=[[UIActivityViewController alloc]initWithActivityItems:@[contactInfo] applicationActivities:nil];
        self.activityVC=activityVC;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureTabelFooterView];
        });
    });

}
-(void)share:(UIButton *)button{

    [self presentViewController:self.activityVC animated:YES completion:nil];

}

-(void)configureNavigationBar{
    self.title=@"联系方式";
    UIBarButtonItem *editBarButton=[[UIBarButtonItem alloc]initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(edit:)];
    self.navigationItem.rightBarButtonItem=editBarButton;
}
-(void)configureTF{

    self.contactTypeTF.text=self.contactInfo[ContactInfoLabelKey];
    self.contactTypeTF.placeholder=self.contactTypeTF.text;
    self.contactTypeTF.delegate=self;
    self.contactTypeTF.returnKeyType=UIReturnKeyNext;
    self.contactTypeTF.enabled=NO;

    self.contactInfoTF.text=self.contactInfo[ContactInfoValueKey];
    self.contactInfoTF.placeholder=self.contactInfoTF.text;
    self.contactInfoTF.delegate=self;
    self.contactInfoTF.enabled=NO;
    
}

-(void)setContactInfo:(NSDictionary *)contactInfo{
    _contactInfo=contactInfo;

    self.contactTypeTF.text=contactInfo[ContactInfoTypeKey];
    self.contactInfoTF.text=contactInfo[ContactInfoValueKey];

    self.contactTypeTF.placeholder=self.contactTypeTF.text;
    self.contactInfoTF.placeholder=self.contactInfoTF.text;

    self.isPhone= [self.contactInfo[ContactInfoTypeKey] integerValue]==ContactInfoTypePhone;
}
- (void)delete:(UIButton *)button {

    [self.contactTypeTF resignFirstResponder];
    [self.contactInfoTF resignFirstResponder];

    NSString *message=[NSString stringWithFormat:@"确定要删除%@的%@联系方式吗?",self.contact.contactName,self.contactInfo[ContactInfoLabelKey]];
    UIAlertController *deleteAlert=[UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleActionSheet];
    [deleteAlert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"删除 %@",self.contactInfoTF.text] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[ContactsManager sharedContactManager] deleteContactInfo:self.contactInfo contact:self.contact];
        self.navigationItem.rightBarButtonItem=nil;
        self.contactInfoTF.text=nil;
        self.contactTypeTF.text=nil;
        self.contactInfoTF.enabled=NO;
        self.contactTypeTF.enabled=NO;
        [button setTitle:@"已删除" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor clearColor]];

    }]];
    [deleteAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel  handler:nil]];

    [self presentViewController:deleteAlert animated:YES completion:nil];

}

- (void)edit:(UIBarButtonItem *)sender {

    self.tableView.tableFooterView=[self deleteButton];
    sender.title=@"完成";
    sender.action=@selector(finishEditing:);

    self.contactTypeTF.text=nil;
    self.contactTypeTF.enabled=YES;
    
    if (self.isPhone) {
        self.contactInfoTF.keyboardType=UIKeyboardTypePhonePad;
    }else{
        self.contactInfoTF.keyboardType=UIKeyboardTypeEmailAddress;
    }
    self.contactInfoTF.text=nil;
    self.contactInfoTF.enabled=YES;
    [self.contactInfoTF becomeFirstResponder];
}
-(void)finishEditing:(UIBarButtonItem *)sender{

    sender.title=@"编辑";
    sender.action=@selector(edit:);

    self.tableView.tableFooterView=[self shareButton];
    [self.contactTypeTF resignFirstResponder];
    [self.contactInfoTF resignFirstResponder];

    [self saveModifiedContact];

    self.contactTypeTF.enabled=NO;
    self.contactInfoTF.enabled=NO;

}
-(void)saveModifiedContact{

    NSString *label=[self.contactTypeTF.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *value=[self.contactInfoTF.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSDictionary *modifiedContactInfo=@{ContactInfoIndexKey : self.contactInfo[ContactInfoIndexKey],
                                        ContactInfoTypeKey  : self.contactInfo[ContactInfoTypeKey],
                                        ContactInfoLabelKey : label.length ? label : self.contactInfo[ContactInfoLabelKey],
                                        ContactInfoValueKey : value.length ? value : self.contactInfo[ContactInfoValueKey]};

    [[ContactsManager sharedContactManager] modifyContactInfo:modifiedContactInfo contact:self.contact];
    self.contactInfo=modifiedContactInfo;
}
#pragma mark - text field delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == self.contactTypeTF) {
        [self.contactInfoTF becomeFirstResponder];
    }
    return YES;
}
#pragma mark - table view


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
