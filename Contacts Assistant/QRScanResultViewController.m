//
//  QRScanResultViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/3/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "QRScanResultViewController.h"
#import "ContactsManager.h"
#import "Contact+Utility.h"
#import "defines.h"
#import "MBProgressHUD.h"

@interface QRScanResultViewController ()

@property(strong,nonatomic)NSArray *contactsInfo;

@property(weak,nonatomic)UIButton *addToAdressBook;
@end

@implementation QRScanResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"扫描结果";
    [self configureTableFooterView];

    // Do any additional setup after loading the view.
}

-(void)viewDidLayoutSubviews{

    self.addToAdressBook.bounds=CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 44);
    self.addToAdressBook.center=CGPointMake(CGRectGetMidX(self.tableView.tableFooterView.bounds), CGRectGetMidY(self.tableView.tableFooterView.bounds));
}
- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)configureTableFooterView{
    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 80)];

    UIButton *addToAdressBook=[[UIButton alloc]init];
    self.addToAdressBook=addToAdressBook;
    [addToAdressBook setTitle:@"添加到通讯录" forState:UIControlStateNormal];
    [addToAdressBook setTitleColor:IconColor
                          forState:UIControlStateNormal];
    [addToAdressBook addTarget:self action:@selector(addToAB:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview: addToAdressBook];

    self.tableView.tableFooterView=view;

}
-(void)addToAB:(UIButton *)button{

    MBProgressHUD *hud=[[MBProgressHUD alloc]initWithView:self.navigationController.view];
    hud.removeFromSuperViewOnHide=YES;
    [self.navigationController.view addSubview:hud];
    hud.mode=MBProgressHUDModeText;
    hud.labelText=@"正在添加...";
    [hud show:YES];

    [[ContactsManager sharedContactManager] createPerson:self.personInfo];
    

    hud.labelText=@"已添加";
    [hud hide:YES afterDelay:0.8];

    [button setTitle:@"已添加到通讯录中" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    button.enabled=NO;
}

-(void)setPersonInfo:(NSDictionary *)personInfo{
    _personInfo=personInfo;
    self.contactsInfo=self.personInfo[PersonInfoContactInfoKey];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
//    NSLog(@"qrvc memory warning");
    // Dispose of any resources that can be recreated.
}

#pragma mark - tableview
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return 1;
    }else{
        return self.contactsInfo.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (indexPath.section ==0 ) {
        cell.textLabel.text=self.personInfo[PersonInfoNameKey];
        cell.detailTextLabel.text=nil;
    }else{
        NSDictionary *contactInfo =self.contactsInfo[indexPath.row];
        cell.textLabel.text=contactInfo[ContactInfoLabelKey];
        cell.detailTextLabel.text=contactInfo[ContactInfoValueKey];
    }
    return cell;

}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section ==0 ) {
        return @"姓名";
    }else{
        return @"联系信息";
    }
}

@end
