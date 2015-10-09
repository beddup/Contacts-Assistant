//
//  ContactDetailsViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

//2. 验证local notification
//3. design icon
#import "ContactDetailsViewController.h"
#import "ContactInfoViewController.h"
#import "AddTagsToContactViewController.h"
#import "EventViewController.h"
#import "ContactsManager.h"
#import "TagCell.h"
#import "Event.h"
#import "Event+Utility.h"
#import "Tag.h"
#import "Tag+Utility.h"
#import "UIImage+MDQRCode.h"
#import "Contact+Utility.h"
#import "PhotoCircleImageView.h"
#import "RelationsViewController.h"
#import "ContactsViewController.h"
#import "NSString+ContactsAssistant.h"
#import "defines.h"
#import "AppDelegate.h"

@interface ContactDetailsViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property(weak,nonatomic)UIImageView *qrImageView;
@property(weak,nonatomic)UIView *QRBKGImageView;

@property(strong,nonatomic)NSMutableArray *contactInfos;
@property(strong,nonatomic)NSMutableArray *tags;
@property(strong,nonatomic)NSMutableArray *unfinishedEvents;
@property(strong,nonatomic)NSMutableArray *finishedEvents;
@property(nonatomic)NSInteger relationsCount;

@property(copy,nonatomic)NSArray *sectionHeaderTitles;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

// view of add new contact
@property(weak,nonatomic)UITextField *addContactValueField;
@property(weak,nonatomic)UITextField *addContactLabelField;

@property(nonatomic)ContactInfoType addWhatTypeOfContactInfo;

@end

@implementation ContactDetailsViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.sectionHeaderTitles=@[@"联系信息",@"联系事项",@"标签",@"关系"];
    [self configureNavigationBar];
    // Do any additional setup after loading the view.
}
-(void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    NSIndexPath *indexPath=[self.tableView indexPathForSelectedRow];
    if (indexPath) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - mavigation bar items and action
-(void)configureNavigationBar{

    if (self.addWhatTypeOfContactInfo == ContactInfoTypeUnkown) {
        UIBarButtonItem *qrBarButton=[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"QR"] style:UIBarButtonItemStylePlain target:self action:@selector(showQRImage:)];
        self.navigationItem.rightBarButtonItem=qrBarButton;
    }else{
        self.navigationItem.rightBarButtonItem=[self cancelContactInfoCreateBarButton];
    }
}

-(void)showQRImage:(UIBarButtonItem *)barbutton{

    UIView *dimmingView=[[UIView alloc]initWithFrame:self.navigationController.view.frame];
    dimmingView.backgroundColor=[UIColor whiteColor];
    dimmingView.alpha=0.0;
    self.QRBKGImageView=dimmingView;
    [self.navigationController.view addSubview:dimmingView];
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissQRImageView:)];
    [dimmingView addGestureRecognizer:tap];

    UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds)-44,20, 44, 44)];
    [self.navigationController.view addSubview:imageView];
    self.qrImageView=imageView;
    imageView.alpha=0.0;
    UIImage *QRImage=[UIImage mdQRCodeForString:[Contact QRStringOfContact:self.contact] size:200 fillColor:IconColor];
    imageView.image=QRImage;
    imageView.contentMode=UIViewContentModeScaleAspectFill;
    [UIView animateWithDuration:0.5 delay:0
                        options:UIViewAnimationOptionCurveEaseInOut animations:^{
        dimmingView.alpha=1;
        imageView.alpha=1.0;
        CGFloat width=CGRectGetWidth(self.navigationController.view.bounds)*2/3;
        imageView.frame=CGRectMake(CGRectGetWidth(self.navigationController.view.bounds)/2-width/2, CGRectGetHeight(self.navigationController.view.bounds)/2-width/2, width, width);
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }];
}

-(void)dismissQRImageView:(UITapGestureRecognizer *)tagGesture{
    if (tagGesture.state == UIGestureRecognizerStateRecognized) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [UIView animateWithDuration:0.5 delay:0
                            options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.qrImageView.frame=CGRectMake(CGRectGetWidth(self.view.bounds)-44,20, 44, 44);
            self.qrImageView.alpha=0.0;
            self.QRBKGImageView.alpha=0.0;
        } completion:^(BOOL finished) {
            [self.QRBKGImageView removeFromSuperview];
            [self.qrImageView removeFromSuperview];
        }];

    }
}

#pragma mark - Properties
-(void)setContact:(Contact *)contact{
    _contact=contact;
    self.title=contact.contactName;

    // tags
    [self resetTags];
    //events
    [self resetEvents];
     // relations
    [self resetRelationCount];
    //contactinfos
    [self resetContactInfos];

    [self.tableView reloadData];
}

-(void)setAddWhatTypeOfContactInfo:(ContactInfoType)addWhatTypeOfContactInfo{
    _addWhatTypeOfContactInfo=addWhatTypeOfContactInfo;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self configureNavigationBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - reset data
-(void)resetTags{
    self.tags=[[self.contact.underWhichTags allObjects] mutableCopy];
    [self.tags removeObject:[Tag rootTag]];

}

-(void)resetEvents{
    
    self.unfinishedEvents=[self.contact sortedUnfinishedOwnedEvents];
    self.finishedEvents=[[self.contact finishedOwnedEvents] mutableCopy];;
}
-(Event *)eventAtIndexPath:(NSIndexPath *)indexPath{
    Event *event=nil;
    if (indexPath.row < self.unfinishedEvents.count) {
        event=(Event *)self.unfinishedEvents[indexPath.row];
    }else{
        event=(Event *)self.finishedEvents[indexPath.row-self.unfinishedEvents.count];
    }
    return event;
}

-(void)resetRelationCount{
    self.relationsCount=self.contact.relationsWithOtherPeople.count + self.contact.belongWhichRelations.count;
}
-(void)resetContactInfos{
    self.contactInfos = [[[ContactsManager sharedContactManager] phoneNumbersOfContact:self.contact] mutableCopy];
    NSArray *emails=[[ContactsManager sharedContactManager]emailsOfContact:self.contact];
    [self.contactInfos addObjectsFromArray:emails];
}

#pragma mark - table data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    if (section==0) {
        return self.contactInfos.count;
    }else if (section ==1){
        return self.contact.ownedEvents.count;
    }else if (section ==2){
        return self.tags.count;
    }else if (section ==3){
        return 1;
    }
    return 0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell=nil;
    if (indexPath.section == 0) {
        //contact info
        cell=[tableView dequeueReusableCellWithIdentifier:@"Contact Info Cell"];
        cell.textLabel.text = self.contactInfos[indexPath.row][ContactInfoLabelKey];
        cell.detailTextLabel.text =self.contactInfos[indexPath.row][ContactInfoValueKey];
    }else if (indexPath.section ==1 ){
        //event;
        Event *event=[self eventAtIndexPath:indexPath];
        NSDate *eventNextDate=[event nextEventDate];
        if ((eventNextDate && [eventNextDate timeIntervalSinceNow] < 0) || event.finished.boolValue ) {
            // passed or finished
            cell=[tableView dequeueReusableCellWithIdentifier:@"Event Cell Passed"];
            cell.imageView.image=[UIImage imageNamed:event.finished.boolValue ?@"eventFinishedIndicator":@"eventindicator"];
        }else{
            cell=[tableView dequeueReusableCellWithIdentifier:@"Event Cell"];
            cell.imageView.image=[UIImage imageNamed:@"eventIndicatorOrange"];
        }
        NSString *displayedEventString=[event displayedEventString];
        cell.textLabel.text=displayedEventString;
        if (eventNextDate) {
            cell.detailTextLabel.text=[NSDateFormatter localizedStringFromDate:eventNextDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
        }else{
            cell.detailTextLabel.text=nil;
        }

    }else if(indexPath.section ==2){
        //tags
        static NSString *tagCellIdentifier=@"Tag Cell";
        cell=[tableView dequeueReusableCellWithIdentifier:tagCellIdentifier];
        if (!cell) {
            cell=[[TagCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tagCellIdentifier];
            [(TagCell *)cell setHasCloseButton:YES];
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
            ((TagCell *)cell).closeButtonTapped=^(Tag *tag){
                [self.contact removeUnderWhichTagsObject:tag];
                [self.tags removeObject:tag];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
                [APP saveContext];
            };
        }
        ((TagCell *)cell).myTag = self.tags[indexPath.row];

    }else if (indexPath.section == 3 ){
        cell=[tableView dequeueReusableCellWithIdentifier:@"Relation Cell"];
        cell.textLabel.text=[NSString stringWithFormat:@"与通讯录中%@人有关联",@(self.relationsCount)];
    }
    return cell;

}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return self.sectionHeaderTitles[section];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 44.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1) {
        // event
        return 50.0;
    }
    return 44.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{

    switch (section) {
        case 0:{
            if (self.addWhatTypeOfContactInfo) {
                UIView *addNewContactView=[self viewForCreatingNewContactInfo:self.addWhatTypeOfContactInfo];
                addNewContactView.frame=CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 44);
                return addNewContactView;
            }
            return [self sectionFooterButton:@"新增联系方式" action:@selector(createContactInfo:)];
        }
        case 1:{

            return [self sectionFooterButton:@"新增联系事项" action:@selector(createEvent:)];

        }
        case 2:{
            return [self sectionFooterButton:@"添加标签" action:@selector(addTag:)];
        }
        default:
            return nil;
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1 && indexPath.row < self.unfinishedEvents.count) {
        UITableViewRowAction *markAsFinishedAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal     title:@"标记为已完成" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            Event *event=self.unfinishedEvents[indexPath.row];
            event.finished=@(YES);
            [self.unfinishedEvents removeObjectAtIndex:indexPath.row];
            [self.finishedEvents insertObject:event atIndex:0];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
            [event cancelLocalNotification];
        }];
        markAsFinishedAction.backgroundColor=[UIColor orangeColor];
        return @[markAsFinishedAction];
    }
    return @[];
}
// event cell action
- (IBAction)removeEvent:(UIButton *)button {

    UITableViewCell *cell=(UITableViewCell *)button.superview.superview;
    NSIndexPath *indexPath=[self.tableView indexPathForCell:cell];
    Event *event=[self eventAtIndexPath:indexPath];

    [event.contactWhoOwnThisEvent removeOwnedEventsObject:event];
    [event cancelLocalNotification];

    [APP.managedObjectContext deleteObject:event];
    [self resetEvents];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    [APP saveContext];
    
    
}
// generate sectionFooterButton
-(UIButton *)sectionFooterButton:(NSString *)title action:(SEL)seletor{

    UIButton *button=[[UIButton alloc]init];
    [button setTitleColor:IconColor forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:17]];
    [button setBackgroundColor:[UIColor whiteColor]];
    button.frame=CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 44);
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:seletor forControlEvents:UIControlEventTouchUpInside];
    return button;

}
#pragma mark - Create New Contact Info
-(UIView *)viewForCreatingNewContactInfo:(ContactInfoType)contactInfoType{

    BOOL isPhone= (contactInfoType == ContactInfoTypePhone);
    UIView *addNewContactView=[[UIView alloc]init];
    addNewContactView.backgroundColor=[UIColor colorWithRed:81.0/255.0 green:167.0/255.0 blue:249.0/255.0 alpha:0.2];
    UITextField *labelField=[[UITextField alloc]initWithFrame:CGRectMake(15, 0, 60, 44)];
    labelField.placeholder= isPhone ?  @"电话" : @"邮箱";
    labelField.textColor=[UIColor lightGrayColor];
    labelField.returnKeyType=UIReturnKeyNext;
    labelField.delegate=self;
    self.addContactLabelField=labelField;
    [addNewContactView addSubview:labelField];

    UITextField *valueField=[[UITextField alloc]initWithFrame:CGRectMake(CGRectGetMaxX(labelField.frame), 0, CGRectGetWidth(self.tableView.bounds)-CGRectGetMaxX(labelField.frame)-44, 44)];
    valueField.textAlignment=NSTextAlignmentRight;
    valueField.textColor=[UIColor lightGrayColor];

    valueField.placeholder=isPhone ? @"请输入电话号码" :@"请输入邮箱地址";

    valueField.keyboardType=isPhone ? UIKeyboardTypeNumbersAndPunctuation : UIKeyboardTypeEmailAddress;
    valueField.returnKeyType=UIReturnKeyDone;
    valueField.delegate=self;
    self.addContactValueField=valueField;
    [addNewContactView addSubview:valueField];

    return addNewContactView;

}

-(void)createContactInfo:(UIButton *)button{

    UIAlertController *contactInfoTypeAlertController=[UIAlertController alertControllerWithTitle:nil message:@"新增联系方式" preferredStyle:UIAlertControllerStyleActionSheet];

    CGRect rect=[self.tableView rectForFooterInSection:0];
    [contactInfoTypeAlertController addAction:[UIAlertAction actionWithTitle:@"新增电话" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.tableView setContentOffset:CGPointMake(0, CGRectGetMinY(rect)-44) animated:YES];
        self.addWhatTypeOfContactInfo=ContactInfoTypePhone;
        [self.addContactValueField becomeFirstResponder];
    }]];

    [contactInfoTypeAlertController addAction:[UIAlertAction actionWithTitle:@"新增邮箱" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.tableView setContentOffset:CGPointMake(0, CGRectGetMinY(rect)-44) animated:YES];
        self.addWhatTypeOfContactInfo=ContactInfoTypeEmail;
        [self.addContactValueField becomeFirstResponder];
    }]];

    [contactInfoTypeAlertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel  handler:nil]];

    [self presentViewController:contactInfoTypeAlertController animated:YES completion:nil];

}

-(UIBarButtonItem *)cancelContactInfoCreateBarButton{
    UIBarButtonItem *cancelButton=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAddingContact:)];
    return cancelButton;
}

-(void)cancelAddingContact:(UIBarButtonItem *)barbutton{
    self.addWhatTypeOfContactInfo=ContactInfoTypeUnkown;
}

#pragma mark - Text Field Delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == self.addContactLabelField) {
        [self.addContactValueField becomeFirstResponder];
    }else if (textField == self.addContactValueField){
        BOOL isPhone=[self.addContactLabelField.placeholder isEqualToString:@"电话"];

        if (![textField.text whiteSpaceTrimmedLength] || (!isPhone && ![textField.text containsString:@"@"])) {
            return NO;
        }
        NSString *label = [self.addContactLabelField.text whiteSpaceTrimmedLength] ? [self.addContactLabelField.text whiteSpaceAtEndsTrimmedString] : self.addContactLabelField.placeholder;
        NSString *value= [textField.text whiteSpaceAtEndsTrimmedString];
        NSInteger type= isPhone ? ContactInfoTypePhone:ContactInfoTypeEmail;
        NSDictionary *newContact=@{ContactInfoTypeKey:@(type),
                                   ContactInfoLabelKey:label,
                                   ContactInfoValueKey:value};
        [[ContactsManager sharedContactManager] addContactInfo:newContact contact:self.contact];
        self.addWhatTypeOfContactInfo=ContactInfoTypeUnkown;
        [self resetContactInfos];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [textField resignFirstResponder];
    }

    return YES;
}

#pragma mark -vc Navigation (segue)
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"contactInfo"]) {
        ContactInfoViewController *dstVC=(ContactInfoViewController *)segue.destinationViewController;
        dstVC.contact=self.contact;
        dstVC.delegate=self;
        NSIndexPath *indexPath=[self.tableView indexPathForSelectedRow];
        dstVC.contactInfo=self.contactInfos[indexPath.row];
    }else if ([segue.identifier isEqualToString:@"add tag"]){
        UINavigationController *nav=(UINavigationController *)segue.destinationViewController;
        AddTagsToContactViewController *dstVC=(AddTagsToContactViewController*)nav.viewControllers[0];
        dstVC.contact=self.contact;

    }else if ([segue.identifier containsString:@"showEvent"]){
        EventViewController *dstVC=(EventViewController*)segue.destinationViewController;
        NSIndexPath *indexPath=[self.tableView indexPathForSelectedRow];
        Event *event=[self eventAtIndexPath:indexPath];
        dstVC.event=event;
        dstVC.delegate=self;
        dstVC.forDisplay=YES;
    }else if ([segue.identifier isEqualToString:@"add event"]){
        UINavigationController *nav=(UINavigationController *)segue.destinationViewController;
        EventViewController *dstVC=nav.viewControllers[0];
        Event *event=[NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.contact.managedObjectContext];
        event.contactWhoOwnThisEvent=self.contact;
        event.finished=@(NO);
        event.eventID=@([NSDate timeIntervalSinceReferenceDate]);
        dstVC.event=event;
        dstVC.forDisplay=NO;
        dstVC.delegate=self;

    }else if ([segue.identifier isEqualToString:@"relations"]){
        RelationsViewController *dstVC=(RelationsViewController *)segue.destinationViewController;
        dstVC.contact=self.contact;
        dstVC.delegate=self;
    }
}
// create event
-(void)createEvent:(UIButton *)button{
    [self performSegueWithIdentifier:@"add event" sender:nil];
}
// event creating finished unwind
-(IBAction)eventCreateFinished:(UIStoryboardSegue *)segue{
    [self resetEvents];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    [APP saveContext];
}
// add tag
-(void)addTag:(UIButton *)button{
    [self performSegueWithIdentifier:@"add tag" sender:nil];
}
-(IBAction)tagAdded:(UIStoryboardSegue *)segue{
    [self resetTags];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
    [APP saveContext];
}
#pragma mark - ContactDetailsUpdatingDelegate
-(void)contactInfoChanged{
    [self resetContactInfos];
    [self.tableView reloadData];
}
-(void)relationsChanged{
    [self resetRelationCount];
    [self.tableView reloadData];
    [APP saveContext];
}
-(void)eventsChanged{
    [self resetEvents];
    [self.tableView reloadData];
    [APP saveContext];
}











@end
