//
//  CreatePersonViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/16/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "CreatePersonViewController.h"
#import <AddressBook/AddressBook.h>
#import "ContactsManager.h"
#import "MBProgressHUD.h"
#import "NSString+ContactsAssistant.h"

@interface CreatePersonViewController ()<UITextFieldDelegate,MBProgressHUDDelegate>

@property(strong,nonatomic)NSMutableArray *contactsInfo; //dictionary : label + value
@property(copy,nonatomic)NSArray *baiscInfoPlaceHodlers;

@property(weak,nonatomic)UITextField *nameTF;

@property(weak,nonatomic)UITextField *phoneLabelTF;
@property(weak,nonatomic)UITextField *emailLabelTF;
@property(weak,nonatomic)UITextField *phoneValueTF;
@property(weak,nonatomic)UITextField *emailValueTF;

@property(weak,nonatomic)UITextField *companyTF;
@property(weak,nonatomic)UITextField *departmentTF;
@property(weak,nonatomic)UITextField *jobTitleTF;

@end

@implementation CreatePersonViewController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.baiscInfoPlaceHodlers=@[@"公司",@"部门",@"职称"];
    [self configureTableHV];
    // Do any additional setup after loading the view.
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TFChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  mark - MBProgressHUDDelegate
- (void)hudWasHidden:(MBProgressHUD *)hud{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
#pragma  mark - property
-(NSMutableArray *)contactsInfo{
    if (!_contactsInfo) {
        _contactsInfo=[@[]
                       mutableCopy];
    }
    return _contactsInfo;
}

#pragma mark - table view
-(void)configureTableHV{
    UITextField *textField=[[UITextField alloc]initWithFrame:CGRectMake(0, 0, 0, 50)];
    textField.placeholder=@"输入联系人姓名";
    textField.textAlignment=NSTextAlignmentCenter;
    self.tableView.tableHeaderView=textField;
    self.nameTF=textField;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2; // name ， contacts， company
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 1) {
        return self.baiscInfoPlaceHodlers.count;
    }else {
        return self.contactsInfo.count;
    }
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return  section == 1 ? @"工作信息" : @"联系方式";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"basic info"];
        UITextField *value=(UITextField *)[cell viewWithTag:105];
        value.placeholder=self.baiscInfoPlaceHodlers[indexPath.row];

        if (indexPath.row == 0) {
            self.companyTF=value;
        }else if (indexPath.row ==1){
            self.departmentTF=value;
        }else if (indexPath.row ==2){
            self.jobTitleTF=value;
        }

    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"contact info"];
        UITextField *type=(UITextField *)[cell viewWithTag:925];
        UITextField *value=(UITextField *)[cell viewWithTag:105];
        type.text=self.contactsInfo[indexPath.row][ContactInfoLabelKey];
        value.text=self.contactsInfo[indexPath.row][ContactInfoValueKey];
        type.enabled=NO;
        value.enabled=NO;
    }
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == 0) {
        return 88;
    }
    return 0;
}
-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == 0 ) {

        UIView *view =[[UIView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 90)];

        UITableViewCell *phoneNumber = [tableView dequeueReusableCellWithIdentifier:@"new contact info"];
        [view addSubview:phoneNumber];
        phoneNumber.backgroundColor=[UIColor whiteColor];
        phoneNumber.frame=CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 44);

        UITextField *phoneLabelTF=(UITextField *)[phoneNumber viewWithTag:925];
        phoneLabelTF.placeholder=@"电话";
        phoneLabelTF.returnKeyType=UIReturnKeyNext;
        phoneLabelTF.delegate=self;
        self.phoneLabelTF=phoneLabelTF;

        UITextField *phoneValueTF=(UITextField *)[phoneNumber viewWithTag:105];
        phoneValueTF.placeholder=@"请输入电话号码";
        phoneValueTF.delegate=self;
        phoneValueTF.keyboardType=UIKeyboardTypeNamePhonePad;
        phoneValueTF.returnKeyType=UIReturnKeyDone;
        self.phoneValueTF=phoneValueTF;


        UITableViewCell *emailAddress = [tableView dequeueReusableCellWithIdentifier:@"new contact info"];
        [view addSubview:emailAddress];
        emailAddress.frame=CGRectMake(0, 45, CGRectGetWidth(tableView.bounds), 44);
        emailAddress.backgroundColor=[UIColor whiteColor];

        UITextField *emailLabelTF=(UITextField *)[emailAddress viewWithTag:925];
        emailLabelTF.placeholder=@"邮箱";
        emailLabelTF.returnKeyType=UIReturnKeyNext;
        emailLabelTF.delegate=self;
        self.emailLabelTF=emailLabelTF;

        UITextField *emailValueTF=(UITextField *)[emailAddress viewWithTag:105];
        emailValueTF.placeholder=@"请输入邮箱地址";
        emailValueTF.delegate=self;
        emailValueTF.keyboardType=UIKeyboardTypeEmailAddress;
        self.emailValueTF=emailValueTF;

        return view;
    }
    return nil;
}

#pragma mark- UITextFieldTextDidChangeNotification
-(void)TFChanged:(NSNotification *)notification{

    self.navigationItem.rightBarButtonItem.enabled=[self canCreatePerson];

}

-(BOOL)canCreatePerson{

    if ([self.nameTF.text whiteSpaceTrimmedLength] || self.contactsInfo.count) {
        return YES;
    }
    if ([self.companyTF.text whiteSpaceTrimmedLength] ||
        [self.departmentTF.text whiteSpaceTrimmedLength] ||
        [self.jobTitleTF.text whiteSpaceTrimmedLength] ) {
        return YES;
    }
    return NO;
}

#pragma  mark - text field delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == self.emailValueTF && ![textField.text containsString:@"@"]) {
        return NO;
    }

    if (textField == self.emailValueTF) {
        [self addContactInTF:textField];
        textField.text=nil;
        self.emailLabelTF.text=nil;
    }

    if (textField == self.phoneLabelTF) {
        [self.phoneValueTF becomeFirstResponder];
    }else if (textField == self.emailLabelTF){
        [self.emailValueTF becomeFirstResponder];
    }
    return  YES;
}

-(void)addContactInTF:(UITextField *)textField{
    if ([textField.text whiteSpaceTrimmedLength]) {
        ContactInfoType type;
        type =  textField == self.phoneValueTF ? ContactInfoTypePhone : ContactInfoTypeEmail;
        NSString *labelString;
        switch (type) {
            case ContactInfoTypePhone:{
                labelString =  [self.phoneLabelTF.text whiteSpaceTrimmedLength] ? self.phoneLabelTF.text : self.phoneLabelTF.placeholder;
                break;
            }
            case ContactInfoTypeEmail:{
                labelString = [self.emailLabelTF.text whiteSpaceTrimmedLength] ? self.emailLabelTF.text : self.emailLabelTF.placeholder;
                break;
            }
            default:{
                break;
            }
        }
        [self.contactsInfo insertObject:@{ContactInfoTypeKey:@(type),
                                          ContactInfoLabelKey:labelString,
                                          ContactInfoValueKey:textField.text}
                                atIndex:type == ContactInfoTypePhone ? 0 : self.contactsInfo.count];

        self.navigationItem.rightBarButtonItem.enabled=YES;

        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:type == ContactInfoTypePhone ? 0 : self.contactsInfo.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
}


-(void)textFieldDidEndEditing:(UITextField *)textField{

    if (textField == self.phoneValueTF || textField == self.emailValueTF) {
        [self addContactInTF:textField];
        self.phoneLabelTF.text=nil;
        self.emailLabelTF.text=nil;
        textField.text=nil;
    }

}

#pragma  mark - task finish or cancel
- (IBAction)done:(id)sender {

    [self.nameTF becomeFirstResponder];
    [self.nameTF resignFirstResponder];

    NSMutableDictionary *personInfo=[@{} mutableCopy];
    // get name
    if ([self.nameTF.text whiteSpaceTrimmedLength]) {
        [personInfo setObject:[self.nameTF.text whiteSpaceAtEndsTrimmedString]  forKey:PersonInfoNameKey];
    }

    // get company
    if ([self.companyTF.text whiteSpaceTrimmedLength]) {
        [personInfo setObject:[self.companyTF.text whiteSpaceAtEndsTrimmedString]  forKey:PersonInfoCompanyKey];
    }

    // get department
    if ([self.departmentTF.text whiteSpaceTrimmedLength]) {
        [personInfo setObject:[self.departmentTF.text whiteSpaceAtEndsTrimmedString] forKey:PersonInfoDepartmentKey];
    }

    //get jobTitle
    if ([self.jobTitleTF.text whiteSpaceTrimmedLength]) {
        [personInfo setObject:[self.jobTitleTF.text whiteSpaceAtEndsTrimmedString] forKey:PersonInfoJobTitleKey];
    }

    //get contactsInfo
    [personInfo setObject:self.contactsInfo forKey:PersonInfoContactInfoKey];

    Contact * newContact =[[ContactsManager sharedContactManager] createPerson:personInfo];

    if (!newContact) {
        MBProgressHUD *hud=[[MBProgressHUD alloc]initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
        hud.mode=MBProgressHUDModeText;
        hud.labelText = @"创建失败";
        [hud show:YES];
        [hud hide:YES afterDelay:1.0];
    }else{
        [self performSegueWithIdentifier:@"didCreatePerson" sender:nil];
    }
    
}

- (IBAction)dismiss:(id)sender {

    [self.nameTF resignFirstResponder];
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
