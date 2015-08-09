//
//  ChangeEventTimeViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/1/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ChangeEventTimeViewController.h"

@interface ChangeEventTimeViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) UIDatePicker *datePicker;

@property(strong,nonatomic)NSMutableArray *repeatedDays;

@property(strong,nonatomic)NSArray *days;

@end

@implementation ChangeEventTimeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.days=[[NSCalendar currentCalendar] weekdaySymbols];
    [self configureTableHeaderView];

    if (self.event.repeatedDays.length) {
        self.repeatedDays=[[[self.event.repeatedDays componentsSeparatedByString:@","] valueForKey:@"integerValue"] mutableCopy];
    }else{
        self.repeatedDays=[@[] mutableCopy];
    }

    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    self.datePicker.frame=CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 180);

}

-(void)configureTableHeaderView{

    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 180)];
    UIDatePicker *datePicker=[[UIDatePicker alloc]init];
    [view addSubview:datePicker];
    self.datePicker=datePicker;
    if (self.event.date) {
        self.datePicker.date=self.event.date;
    }
    self.tableView.tableHeaderView=view;

}

- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - tableview

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 7;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    if (!cell) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }

    cell.textLabel.text=self.days[indexPath.row];

    if ([self.repeatedDays containsObject:@(indexPath.row)]) {
        
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        cell.accessoryType=UITableViewCellAccessoryCheckmark;

    }else{

        cell.accessoryType=UITableViewCellAccessoryNone;

    }

    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"重复";
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{

    [self.repeatedDays removeObject:@(indexPath.row)];
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryNone;

}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    [self.repeatedDays addObject:@(indexPath.row)];
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryCheckmark;

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"timesettingdone"]) {

        self.event.date=self.datePicker.date;
        if (self.repeatedDays.count) {
            self.event.repeatedDays=[[self.repeatedDays valueForKey:@"stringValue"] componentsJoinedByString:@","];
        }else{
            self.event.repeatedDays=nil;
        }

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
