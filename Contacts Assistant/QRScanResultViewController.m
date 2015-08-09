//
//  QRScanResultViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/3/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "QRScanResultViewController.h"
#import "ContactsManager.h"

@interface QRScanResultViewController ()

@property(strong,nonatomic)NSMutableArray *contactInfo;
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
    [addToAdressBook setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [addToAdressBook addTarget:self action:@selector(addToAB:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview: addToAdressBook];

    self.tableView.tableFooterView=view;

}
-(void)addToAB:(UIButton *)button{
    NSLog(@"添加到通讯录中");
}
-(NSMutableArray *)contactInfo{
    if (!_contactInfo) {
        _contactInfo=[@[] mutableCopy];
    }
    return _contactInfo;
}
-(void)setResultInfo:(NSDictionary *)resultInfo{
    _resultInfo=resultInfo;
    [self.contactInfo addObjectsFromArray:self.resultInfo[@"C"][CommunicationPhones]];
    [self.contactInfo addObjectsFromArray:self.resultInfo[@"C"][CommunicationEmails]];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return 1;
    }else{
        return self.contactInfo.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (indexPath.section ==0 ) {
        cell.textLabel.text=self.resultInfo[@"N"];
        cell.detailTextLabel.text=nil;
    }else{
        NSDictionary *contactInfo =self.contactInfo[indexPath.row];
        cell.textLabel.text=contactInfo[PhoneLabel] ?  contactInfo[PhoneLabel] : contactInfo[EmailLabel];
        cell.detailTextLabel.text=contactInfo[PhoneNumber] ? contactInfo[PhoneNumber] : contactInfo[EmailValue];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
