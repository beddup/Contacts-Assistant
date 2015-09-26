//
//  ChangeEventTimeViewController.m
//  Contacts Assistant
//
//  Created by Amay on 8/1/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ChangeEventTimeViewController.h"
#import "Event+Utility.h"
#import "EventViewController.h"

@interface ChangeEventTimeViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) UIDatePicker *datePicker;

@property(strong,nonatomic)NSArray *days;

@end

@implementation ChangeEventTimeViewController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.days=[[NSCalendar currentCalendar] weekdaySymbols];
    [self configureTableHeaderView];
}

-(void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    self.datePicker.frame=CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 180);

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)timeSettingDone:(id)sender {

    self.repeatedDays=[[self.repeatedDays sortedArrayUsingComparator:^NSComparisonResult(NSNumber * obj1, NSNumber * obj2) {
        return [obj1 compare:obj2];
    }] mutableCopy];
    [self.delegate eventDateChanged:self.datePicker.date repeatedDays:self.repeatedDays.count ? self.repeatedDays : nil];
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark - table view header view
-(void)configureTableHeaderView{

    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 180)];
    self.tableView.tableHeaderView=view;

    dispatch_queue_t createDP = dispatch_queue_create("createDP", NULL);
    dispatch_async(createDP, ^{
        UIDatePicker *datePicker=[[UIDatePicker alloc]init];
        datePicker.minimumDate=[NSDate dateWithTimeInterval:5*60 sinceDate:[NSDate date]];
        if (self.repeatedDays.count) {
            datePicker.datePickerMode=UIDatePickerModeTime;
        }
        datePicker.minuteInterval=5;
        dispatch_async(dispatch_get_main_queue(), ^{

            self.datePicker=datePicker;
            [view addSubview:datePicker];
            if (self.date) {
                [self.datePicker setDate:self.date animated:NO];
            }
        });
    });
}



#pragma mark - tableview
-(NSMutableArray *)repeatedDays{
    if (!_repeatedDays) {
        _repeatedDays=[@[] mutableCopy];
    }
    return _repeatedDays;
}

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

    // in NSCalendar, weekday from 1 to 7
    if ([self.repeatedDays containsObject:@(indexPath.row+1)]) {
        
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
    // in NSCalendar, weekday from 1 to 7
    [self.repeatedDays removeObject:@(indexPath.row+1)];
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryNone;
    if (self.repeatedDays.count == 0) {
        self.datePicker.datePickerMode=UIDatePickerModeDateAndTime;
    }

}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    [self.repeatedDays addObject:@(indexPath.row+1)];
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType=UITableViewCellAccessoryCheckmark;
    if (self.repeatedDays.count == 1) {
        self.datePicker.datePickerMode=UIDatePickerModeTime;
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
