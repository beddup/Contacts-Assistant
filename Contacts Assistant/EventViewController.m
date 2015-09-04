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
#import "EventDisplayView.h"
#import <AddressBookUI/AddressBookUI.h>
@interface EventViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(weak,nonatomic)EventDisplayView *eventDisplayView;
@property (weak, nonatomic) UITextView *descriptionTextView;
@property(weak,nonatomic) UILabel *descriptionTextViewPlaceHolderLabel;
@property (weak, nonatomic) UIImageView *indicatorImageView;

@property(nonatomic)BOOL isNewEvent;


@end

@implementation EventViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    [self configureNavigationBar];
    self.isNewEvent=!self.forDisplay;
    [self configureTableHeaderView];
    [self configureTabelFooterView];
    self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;

}

-(void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    [self.tableView reloadData];

}

-(void)viewDidLayoutSubviews{

    [self updateTableHeaderViewFrame];

}

-(void)configureNavigationBar{
    if (self.forDisplay) {

        UIBarButtonItem *editBarButton=[[UIBarButtonItem alloc]initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(edit:)];
        self.navigationItem.rightBarButtonItem=editBarButton;

    }else{
        self.title=@"新事项";
        UIBarButtonItem *cancel=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];
        self.navigationItem.leftBarButtonItem=cancel;

        UIBarButtonItem *done=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        self.navigationItem.rightBarButtonItem=done;
        done.enabled=NO;
    }

}

-(void)configureTableHeaderView{

    if (self.forDisplay) {
        [self configureTableHeaderViewForDisplay];
    }else{
        [self configureTableHeaderViewForEditing];
    }
}

-(void)configureTableHeaderViewForDisplay{

    [self.tableView.tableHeaderView removeFromSuperview];
    EventDisplayView *eventDisplayView=[[EventDisplayView alloc]init];
    self.eventDisplayView=eventDisplayView;

    eventDisplayView.event=self.event;
    self.tableView.tableHeaderView=eventDisplayView;
}

-(void)configureTableHeaderViewForEditing{

    [self.tableView.tableHeaderView removeFromSuperview];

    UIView *view=[[UIView alloc]init];
    self.tableView.tableHeaderView=view;

    UIImageView *indicatorImageView=[[UIImageView alloc]init];
    indicatorImageView.image=[UIImage imageNamed:@"TagViewSelectedBKG"];
    self.indicatorImageView=indicatorImageView;
    [view addSubview:indicatorImageView];

    UITextView *textview=[[UITextView alloc]init];
    textview.font=[UIFont systemFontOfSize:17 weight:UIFontWeightLight];
    self.descriptionTextView=textview;
    textview.delegate=self;
    textview.text=self.event.event;
    textview.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;

    UILabel *placeHolderLabel=[[UILabel alloc]initWithFrame:CGRectMake(6, 0, 200, 35)];
    placeHolderLabel.text=@"添加事项描述";
    placeHolderLabel.textColor=[UIColor lightGrayColor];
    placeHolderLabel.font=textview.font;
    [textview addSubview:placeHolderLabel];
    self.descriptionTextViewPlaceHolderLabel=placeHolderLabel;
    self.descriptionTextViewPlaceHolderLabel.hidden=textview.text.length;

    [view addSubview: textview];

}

-(void)updateTableHeaderViewFrame{

    if (self.forDisplay) {

        NSAttributedString *mstring=[[NSAttributedString alloc]initWithString:self.event.event attributes:[self.eventDisplayView eventDescriptionAttributes]];

        CGRect rect=[mstring boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.tableView.bounds)-16, CGRectGetHeight(self.tableView.bounds)) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        self.tableView.tableHeaderView.bounds=CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(rect)+500);

    }else{
        self.tableView.tableHeaderView.bounds=CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds),CGRectGetHeight(self.tableView.bounds)-250); // 250 : keyboard HEIGHT
        self.descriptionTextView.frame=CGRectInset(self.tableView.tableHeaderView.bounds, 8, 8);

    }
    // i dont't know why, but it works to change the tableheaderview dynamicly
    self.tableView.tableHeaderView=self.tableView.tableHeaderView;

}

-(void)setForDisplay:(BOOL)forDisplay{

    _forDisplay=forDisplay;
    [self configureTableHeaderView];
    [self configureTabelFooterView];
    [self updateTableHeaderViewFrame];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:forDisplay ? UITableViewRowAnimationNone : UITableViewRowAnimationTop];

}

-(void)textViewDidChange:(UITextView *)textView{

    self.descriptionTextViewPlaceHolderLabel.hidden=textView.text.length;
    self.navigationItem.rightBarButtonItem.enabled=textView.text.length;
    ((UIButton *)self.tableView.tableFooterView).enabled=textView.text.length;
    if (textView.text.length) {
        [textView scrollRangeToVisible: textView.selectedRange];
    }

}
#pragma mark - bar button
-(void)edit:(UIBarButtonItem *)sender{
    sender.title = @"完成";
    sender.action =@selector(editingFinished:);
    self.forDisplay=NO;

}
-(void)editingFinished:(UIBarButtonItem *)barbutton{

    barbutton.title=@"编辑";
    barbutton.action=@selector(edit:);
    self.event.event=self.descriptionTextView.text;
    self.forDisplay=YES;

}
-(UIButton *)deleteButton{
    UIButton *deleteButton=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 0, 100)];

    [deleteButton setTitle:@"删除沟通备忘" forState:UIControlStateNormal];
    [deleteButton.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
    return deleteButton;
}
-(void)configureTabelFooterView{

    if (!self.isNewEvent && !self.forDisplay) {
        self.tableView.tableFooterView=[self deleteButton];
        return;
    }
    self.tableView.tableFooterView=nil;
}

-(void)delete:(UIButton *)button{

    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *deleteAction=[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteEvent];
        if (self.presentingViewController) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }else{
            [self.navigationController.navigationController popViewControllerAnimated:YES];
        }
    }];
    UIAlertAction *cancelAcion=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:deleteAction];
    [alertController addAction:cancelAcion];

    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)deleteEvent{
    [self.event removeContactsWhichAttend:self.event.contactsWhichAttend];
    [self.event.managedObjectContext deleteObject:self.event];
}

- (void)dismiss:(id)sender {

    [self.descriptionTextView resignFirstResponder];
    [self deleteEvent];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

}

- (void)done:(id)sender{

    [self.descriptionTextView resignFirstResponder];
    self.event.event=self.descriptionTextView.text;
    [self performSegueWithIdentifier:@"eventCreateFinished" sender:nil];

}

#pragma mark - table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{

    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.forDisplay) {
        return 0;
    }
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (self.forDisplay) {
        return nil;
    }
    return @"时间、相关人";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        if (self.event.repeatedDays) {
            cell=[tableView dequeueReusableCellWithIdentifier:@"timecellRepeatedDays"];
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
            cell=[tableView dequeueReusableCellWithIdentifier:@"timecell"];
            cell.textLabel.text=self.event.date ? [NSDateFormatter localizedStringFromDate:self.event.date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle] : @"设置时间";
        }

    }else{
        cell=[tableView dequeueReusableCellWithIdentifier:@"placecell"];
        if (self.event.contactsWhichAttend.count) {
            NSString *contactNames=[[[self.event.contactsWhichAttend allObjects] valueForKey:@"contactName"] componentsJoinedByString:@","];
            cell.textLabel.text=[@"相关人:" stringByAppendingString:contactNames];
        }else{
            cell.textLabel.text=@"添加相关人员";
        }
    }

    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        [self performSegueWithIdentifier:@"changeDate" sender:nil];
    }
    else if (indexPath.row == 1) {
        [self performSegueWithIdentifier:@"changeContacts" sender:nil];
    }
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"neweventdone"]) {

        self.event.event=self.descriptionTextView.text;
        [self.descriptionTextView resignFirstResponder];

    }else if ([segue.identifier isEqualToString:@"changeDate"]){

        ChangeEventTimeViewController *dvc=(ChangeEventTimeViewController *)segue.destinationViewController;
        dvc.event=self.event;

    }else if ([segue.identifier isEqualToString:@"changeContacts"]){

        ChangeEventContactsViewController *dvc=(ChangeEventContactsViewController *)segue.destinationViewController;
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
