//
//  AddEventViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "EventViewController.h"
#import "ChangeEventTimeViewController.h"
#import "AddContactsToEventViewController.h"
#import "AppDelegate.h"
#import "EventDisplayView.h"
#import "Event+Utility.h"
#import "ContactDetailsViewController.h"
#import "NSString+ContactsAssistant.h"
#import "defines.h"
#import "ContactsManager.h"
#import "MBProgressHUD+ContactsAssistant.h"
#import <AddressBookUI/AddressBookUI.h>

@interface EventViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(weak,nonatomic)EventDisplayView *eventDisplayView;
@property (weak, nonatomic) UITextView *descriptionTextView;
@property(weak,nonatomic) UILabel *descriptionTextViewPlaceHolderLabel;

@property(nonatomic)BOOL isNewEvent;

@property(strong,nonatomic)NSDate *eventDate;
@property(copy,nonatomic)NSArray *eventRepeatedDays;
@property(copy,nonatomic)NSArray *relatedPeople;


@end

@implementation EventViewController
#pragma mark- life cycle
- (void)viewDidLoad {

    [super viewDidLoad];
    [self configureNavigationBar];
    self.isNewEvent=!self.forDisplay;
    [self configureTableHeaderView];
    [self configureTabelFooterView];
    self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;

}
-(void)viewDidLayoutSubviews{

    [self updateTableHeaderViewFrame];

}
#pragma mark - delete event
-(void)deleteEvent{

    [self.event cancelLocalNotification];

    [self.event.contactWhoOwnThisEvent removeOwnedEventsObject:self.event];
    [self.event.managedObjectContext deleteObject:self.event];

    [self.delegate eventsChanged];
    
}


#pragma mark - navigation bar itmes and actions
-(void)configureNavigationBar{
    if (self.forDisplay ) {
        if (!self.event.finished.boolValue) {
            UIBarButtonItem *editBarButton=[[UIBarButtonItem alloc]initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(edit:)];
            self.navigationItem.rightBarButtonItem=editBarButton;
        }
    }else{
        self.title=self.event.contactWhoOwnThisEvent.contactName ;
        UIBarButtonItem *cancel=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];
        self.navigationItem.leftBarButtonItem=cancel;

        UIBarButtonItem *done=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        self.navigationItem.rightBarButtonItem=done;
        done.enabled=NO;
    }

}
-(void)edit:(UIBarButtonItem *)sender{
    sender.title = @"完成";
    sender.action =@selector(editingFinished:);
    self.forDisplay=NO;

}
- (void)dismiss:(id)sender {

    [self.descriptionTextView resignFirstResponder];
    [self deleteEvent];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

}

- (void)done:(id)sender{
    [self.descriptionTextView resignFirstResponder];

    self.event.eventDescription=self.descriptionTextView.text;
    self.event.eventDate=self.eventDate;
    self.event.eventRepeatedDays=[self.eventRepeatedDays componentsJoinedByString:@","];
    self.event.otherContacts=[NSSet setWithArray:self.relatedPeople];

    [self.event scheduleLocalNotification];

    [self.delegate eventsChanged];

    [self performSegueWithIdentifier:@"eventCreateFinished" sender:nil];
}
-(void)editingFinished:(UIBarButtonItem *)barbutton{

    barbutton.title=@"编辑";
    barbutton.action=@selector(edit:);

    self.event.eventDescription=self.descriptionTextView.text;
    self.event.eventDate=self.eventDate;
    self.event.eventRepeatedDays=[self.eventRepeatedDays componentsJoinedByString:@","];
    self.event.otherContacts=[NSSet setWithArray:self.relatedPeople];

    self.forDisplay=YES;

    [self.event scheduleLocalNotification];

    [self.delegate eventsChanged];
}
-(UIButton *)deleteButton{
    UIButton *deleteButton=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 0, 100)];

    [deleteButton setTitle:@"删除联系事项" forState:UIControlStateNormal];
    [deleteButton.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
    return deleteButton;
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


#pragma mark- table view Header footerView
-(void)configureTabelFooterView{

    if (!self.isNewEvent && !self.forDisplay) {
        self.tableView.tableFooterView=[self deleteButton];
        return;
    }
    self.tableView.tableFooterView=nil;
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
    eventDisplayView.SMSToRelatedPeople=^(NSArray *contacts){
        if ([MFMessageComposeViewController canSendText]) {
            NSMutableArray *phoneNumbers=[@[] mutableCopy];
            NSMutableArray *noPhonesContacts=[@[] mutableCopy];
            for (Contact *contact in contacts) {
                NSArray *phonesInfo=[[ContactsManager sharedContactManager] phoneNumbersOfContact:contact];
                if (!phonesInfo.count) {
                    [noPhonesContacts addObject:contact];
                }
                [phoneNumbers addObjectsFromArray:[phonesInfo valueForKey:ContactInfoValueKey]];
            }
            MBProgressHUD *hud=[MBProgressHUD textHud:@"跳转中..." view:self.navigationController.view];
            if (noPhonesContacts.count) {
                hud.detailsLabelText=[[[noPhonesContacts valueForKey:@"contactName"] componentsJoinedByString:@","] stringByAppendingString:@"%@没有联系电话"];
            }

            [hud show:YES];
            APP.globalMessageComposer.recipients=phoneNumbers;
            APP.globalMessageComposer.messageComposeDelegate=self;
            [self presentViewController:APP.globalMessageComposer animated:YES completion:^{
                [hud hide:YES];
            }];
        }

    };
    eventDisplayView.EmailToRelatedPeople=^(NSArray *contacts){
        if ([MFMailComposeViewController canSendMail]) {

            NSMutableArray *emails=[@[] mutableCopy];
            NSMutableArray *noEmailsContacts=[@[] mutableCopy];
            for (Contact *contact in contacts) {
                NSArray *emailsInfo=[[ContactsManager sharedContactManager] emailsOfContact:contact];
                if (!emailsInfo.count) {
                    [noEmailsContacts addObject:contact];
                }
                [emails addObjectsFromArray:[emailsInfo valueForKey:ContactInfoValueKey]];
            }

            MBProgressHUD *hud=[MBProgressHUD textHud:@"跳转中" view:self.navigationController.view];
            if (noEmailsContacts.count) {
                hud.detailsLabelText=[[[noEmailsContacts valueForKey:@"contactName"] componentsJoinedByString:@","] stringByAppendingString:@"%@没有邮箱"];
            }
            [hud show:YES];
            APP.globalMailComposer.mailComposeDelegate=self;
            [APP.globalMailComposer setToRecipients:emails];
            [self presentViewController:APP.globalMailComposer animated:YES completion:^{
                [hud hide:YES];
            }];
        }
    };

    self.tableView.tableHeaderView=eventDisplayView;
}


-(void)configureTableHeaderViewForEditing{

    [self.tableView.tableHeaderView removeFromSuperview];

    UIView *view=[[UIView alloc]init];
    self.tableView.tableHeaderView=view;

    UITextView *textview=[[UITextView alloc]init];
    textview.font=[UIFont systemFontOfSize:17 weight:UIFontWeightLight];
    self.descriptionTextView=textview;
    textview.delegate=self;
    textview.text=self.event.eventDescription;
    textview.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;

    UILabel *placeHolderLabel=[[UILabel alloc]initWithFrame:CGRectMake(6, 0, 200, 35)];
    placeHolderLabel.text=@"添加联系事项描述";
    placeHolderLabel.textColor=[UIColor lightGrayColor];
    placeHolderLabel.font=textview.font;
    [textview addSubview:placeHolderLabel];
    self.descriptionTextViewPlaceHolderLabel=placeHolderLabel;
    self.descriptionTextViewPlaceHolderLabel.hidden=[textview.text whiteSpaceTrimmedLength];

    [view addSubview: textview];

}

-(void)updateTableHeaderViewFrame{

    if (self.forDisplay) {
        CGFloat width=CGRectGetWidth(self.tableView.bounds);
        self.tableView.tableHeaderView.bounds=CGRectMake(0, 0, width, [self.eventDisplayView minHeightWithMaxWidth:width]);

    }else{
        self.tableView.tableHeaderView.bounds=CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds),CGRectGetHeight(self.tableView.bounds)-250); // 250 : keyboard HEIGHT
        self.descriptionTextView.frame=CGRectInset(self.tableView.tableHeaderView.bounds, 8, 8);

    }
    // i dont't know why, but it works to change the tableheaderview dynamicly
    self.tableView.tableHeaderView=self.tableView.tableHeaderView;
    
}

#pragma mark -MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:^{
        [APP cycleTheGlobalMailComposer];
    }];
}

#pragma mark -MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    [self dismissViewControllerAnimated:YES completion:^{
        [APP cycleTheGlobalMessageComposer];
    }];
}

-(void)setEvent:(Event *)event{
    _event=event;

    self.eventDate=event.eventDate;
    self.eventRepeatedDays=[[event.eventRepeatedDays componentsSeparatedByString:@","] valueForKey:@"integerValue"];
    self.relatedPeople=[event.otherContacts allObjects];

    [self.tableView reloadData];

}
-(void)setForDisplay:(BOOL)forDisplay{

    _forDisplay=forDisplay;
    [self configureTableHeaderView];
    [self configureTabelFooterView];
    [self updateTableHeaderViewFrame];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:forDisplay ? UITableViewRowAnimationNone : UITableViewRowAnimationTop];

}
#pragma mark - textView Delegate
-(void)textViewDidChange:(UITextView *)textView{

    self.descriptionTextViewPlaceHolderLabel.hidden=[textView.text whiteSpaceTrimmedLength];
    self.navigationItem.rightBarButtonItem.enabled=[textView.text whiteSpaceTrimmedLength];
    ((UIButton *)self.tableView.tableFooterView).enabled=[textView.text whiteSpaceTrimmedLength];
    if ([textView.text whiteSpaceTrimmedLength]) {
        [textView scrollRangeToVisible: textView.selectedRange];
    }

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
    return @"设置提醒和相关人";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        if (self.eventRepeatedDays.count) {
            cell=[tableView dequeueReusableCellWithIdentifier:@"timecellRepeatedDays"];
            cell.textLabel.text=self.eventDate ? [NSDateFormatter localizedStringFromDate:self.eventDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle] : @"时间提醒";
            cell.detailTextLabel.text=[NSString repeatedDaySymbols:self.eventRepeatedDays];
        }else{
            cell=[tableView dequeueReusableCellWithIdentifier:@"timecell"];
            cell.textLabel.text=self.eventDate ? [NSDateFormatter localizedStringFromDate:self.eventDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle] : @"时间提醒";
        }

    }else{
        cell=[tableView dequeueReusableCellWithIdentifier:@"relatedPeople"];
        if (self.relatedPeople.count) {
            NSString *contactNames=[[self.relatedPeople valueForKey:@"contactName"] componentsJoinedByString:@","];
            cell.textLabel.text=[@"相关人员:" stringByAppendingString:contactNames];
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
#pragma mark - EventContentUpdatingDelegate
-(void)eventDateChanged:(NSDate *)eventDate repeatedDays:(NSArray *)repeatedDays{
    self.eventDate=eventDate;
    self.eventRepeatedDays=repeatedDays;

    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}
-(void)eventRelatedPeopleChanged:(NSArray *)relatedPeople{
    self.relatedPeople=relatedPeople;
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:1 inSection:0];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"neweventdone"]) {

        self.event.eventDescription=self.descriptionTextView.text;
        [self.descriptionTextView resignFirstResponder];

    }else if ([segue.identifier isEqualToString:@"changeDate"]){

        ChangeEventTimeViewController *dvc=(ChangeEventTimeViewController *)segue.destinationViewController;
        dvc.date=self.eventDate;
        dvc.repeatedDays=[self.eventRepeatedDays mutableCopy];
        dvc.delegate=self;

    }else if ([segue.identifier isEqualToString:@"changeContacts"]){

        AddContactsToEventViewController *dvc=(AddContactsToEventViewController *)segue.destinationViewController;
        dvc.contactsSelected=[self.relatedPeople mutableCopy];
        dvc.whoseEvent=self.event.contactWhoOwnThisEvent;
        dvc.delegate=self;
    }
}

@end
