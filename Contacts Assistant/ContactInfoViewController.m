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

@property (weak, nonatomic) IBOutlet UILabel *contactTypeLabel;
@property (weak, nonatomic) IBOutlet UITextField *contactInfoTF;

@property(nonatomic) NSString *contactType;
@property(nonatomic) NSString *contactValue;

@end

@implementation ContactInfoViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    self.navigationController.toolbarHidden=NO;

    self.contactType=self.contactInfo[PhoneLabel] ? PhoneLabel : EmailLabel;
    self.contactTypeLabel.text=self.contactInfo[self.contactType];

    self.contactValue=self.contactInfo[PhoneNumber] ? self.contactInfo[PhoneNumber] :self.contactInfo[EmailValue];
    self.contactInfoTF.text=self.contactValue;
    self.contactInfoTF.placeholder=self.contactInfoTF.text;
    self.contactInfoTF.delegate=self;

    self.title=@"联系方式";

    //configure tool bar
    UIBarButtonItem *deleteButton=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(delete:)];
    UIBarButtonItem *space=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *modifyBarButton=[[UIBarButtonItem alloc]initWithTitle:@"更新" style:UIBarButtonItemStylePlain target:self action:@selector(modify:)];

    self.toolbarItems=@[deleteButton,space,modifyBarButton];


    // Do any additional setup after loading the view.
}
-(void)setContactInfo:(NSDictionary *)contactInfo{
    _contactInfo=contactInfo;
    self.contactTypeLabel.text=self.contactInfo[self.contactType];
}

- (void)delete:(UIBarButtonItem *)sender {

    NSString *message=[NSString stringWithFormat:@"确定要%@的%@联系方式吗?",self.contact.contactName,self.contactInfo[self.contactType]];
    UIAlertController *deleteAlert=[UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleActionSheet];
    [deleteAlert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"删除 %@",self.contactInfoTF.text] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteContactInfo];
    }]];
    [deleteAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel  handler:^(UIAlertAction *action) {

    }]];

    [self presentViewController:deleteAlert animated:YES completion:nil];


}
-(void)deleteContactInfo{
    NSLog(@"delete info");
}

- (void)modify:(UIBarButtonItem *)sender {

    if ([self.contactType isEqualToString:PhoneLabel]) {
        self.contactInfoTF.keyboardType=UIKeyboardTypePhonePad;

    }else{
        self.contactInfoTF.keyboardType=UIKeyboardTypeEmailAddress;
    }
    self.contactInfoTF.text=nil;
    self.contactInfoTF.enabled=YES;
    [self.contactInfoTF becomeFirstResponder];
}

#pragma mark - text field delegate
-(void)textFieldDidEndEditing:(UITextField *)textField{

}

#pragma mark - table view


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
