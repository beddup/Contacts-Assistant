//
//  AddEventViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "EventViewController.h"
#import "ChangeEventTimeViewController.h"
#import "ChangeEventContactsViewController.h"
#import "AppDelegate.h"
@interface EventViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) UITextView *descriptionTextView;
@property (weak, nonatomic) UIImageView *indicatorImageView;

@property(weak,nonatomic)UILabel *timeLabel;
@property(weak,nonatomic)UILabel *repeatLabel;

@property(weak,nonatomic)UITextField *placeTF;
@property(weak,nonatomic)UIView *contactsView;


@end

@implementation EventViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    [self configureTableHeaderView];
    self.title= self.forDisplay ? self.event.event : @"新事项";


}

-(void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];

    self.descriptionTextView.frame=CGRectInset(self.tableView.tableHeaderView.bounds, 4, 4);
    self.indicatorImageView.frame=CGRectMake(CGRectGetMinX(self.descriptionTextView.frame), CGRectGetMaxY(self.descriptionTextView.frame)-18, 18, 18);

}

-(void)setForDisplay:(BOOL)forDisplay{

    _forDisplay=forDisplay;

    if (forDisplay) {
        self.descriptionTextView.editable=NO;



    }else{
        UIBarButtonItem *cancel=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];
        self.navigationItem.leftBarButtonItem=cancel;

        UIBarButtonItem *done=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        self.navigationItem.rightBarButtonItem=done;

    }


}


-(void)configureTableHeaderView{

    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 200)];
    self.tableView.tableHeaderView=view;

    UIImageView *indicatorImageView=[[UIImageView alloc]init];
    indicatorImageView.image=[UIImage imageNamed:@"eventindicator"];
    self.indicatorImageView=indicatorImageView;
    [view addSubview:indicatorImageView];

    UITextView *textview=[[UITextView alloc]init];
    self.descriptionTextView=textview;
    textview.text=@"请描述事项";
    [view addSubview: textview];

}

- (void)dismiss:(id)sender {

    [self.descriptionTextView resignFirstResponder];
    [self.event.managedObjectContext deleteObject:self.event];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

}

- (void)done:(id)sender{

    [self.descriptionTextView resignFirstResponder];
    self.event.event=self.descriptionTextView.text;
    [self performSegueWithIdentifier:@"eventCreateFinished" sender:nil];

}

-(IBAction)timeDetermined:(UIStoryboardSegue *)segue{

    [self.descriptionTextView resignFirstResponder];

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];



}
-(IBAction)contactsDetermined:(UIStoryboardSegue *)segue{


    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:2 inSection:0];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell * cell =[self.tableView cellForRowAtIndexPath:indexPath];

    if (self.event.contactsWhichAttend.count) {
        NSArray *selectedContactNames=[[self.event.contactsWhichAttend allObjects] valueForKey:@"contactName"];
        cell.textLabel.text=[selectedContactNames componentsJoinedByString:@","];
    }else{
        cell.textLabel.text= @"添加相关人员";
    }

}

#pragma mark - table view
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"时间、地点、相关人";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell;
    if (indexPath.row == 0) {

        cell=[tableView dequeueReusableCellWithIdentifier:@"timecell"];
        if (self.event.repeatedDays) {
            cell.textLabel.text=self.event.date ? [NSDateFormatter localizedStringFromDate:self.event.date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle] : @"设置时间";
            NSArray *repeatedDayIndexes=[[self.event.repeatedDays componentsSeparatedByString:@","] valueForKey:@"integerValue"];
            if (repeatedDayIndexes.count < 7) {
                NSArray *weekSymbols=[[NSCalendar currentCalendar]weekdaySymbols];
                NSMutableArray *symbols=[@[] mutableCopy];
                for (NSNumber * index in repeatedDayIndexes) {
                    [symbols addObject:weekSymbols[index.integerValue]];
                }
                cell.detailTextLabel.text=[symbols componentsJoinedByString:@","];

            }else{

                cell.detailTextLabel.text=@"每天";

            }
        }else{
            cell.textLabel.text=self.event.date ? [NSDateFormatter localizedStringFromDate:self.event.date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle] : @"设置时间";
            cell.detailTextLabel.text=nil;

        }

    }else if (indexPath.row == 1 ){

        cell=[tableView dequeueReusableCellWithIdentifier:@"placecell"];
        cell.textLabel.text=@"设置地点";

    }else{
        cell=[tableView dequeueReusableCellWithIdentifier:@"placecell"];
        if (self.event.contactsWhichAttend.count) {
            NSString *contactNames=[[[self.event.contactsWhichAttend allObjects] valueForKey:@"contactName"] componentsJoinedByString:@","];
            cell.textLabel.text=contactNames;
        }else{
            cell.textLabel.text=@"添加相关人员";
        }
    }
//    cell.selectionStyle=UITableViewCellSelectionStyleDefault;
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 2) {
        [self performSegueWithIdentifier:@"changeContacts" sender:nil];
    }
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.descriptionTextView resignFirstResponder];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"neweventdone"]) {

        self.event.event=self.descriptionTextView.text;

        [self.descriptionTextView resignFirstResponder];

    }else if ([segue.identifier isEqualToString:@"changeDate"]){

        UINavigationController *nav=(UINavigationController *)segue.destinationViewController;
        ChangeEventTimeViewController *dvc=nav.viewControllers[0];
        dvc.event=self.event;

    }else if ([segue.identifier isEqualToString:@"changeContacts"]){

        UINavigationController *nav=(UINavigationController *)segue.destinationViewController;
        ChangeEventContactsViewController *dvc=nav.viewControllers[0];
        dvc.event=self.event;
        
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
