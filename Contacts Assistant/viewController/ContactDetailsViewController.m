//
//  ContactDetailsViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ContactDetailsViewController.h"
#import "ContactInfoViewController.h"
#import "AddTagViewController.h"
#import "EventViewController.h"
#import "ContactsManager.h"
#import "TagCell.h"
#import "Event.h"
#import "Event+Utility.h"
#import "Tag.h"
#import "UIImage+MDQRCode.h"
#import "Contact+Utility.h"


@interface ContactDetailsViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property(weak,nonatomic)UIImageView *qrImageView;

@property(strong,nonatomic)NSArray *contactInfos;

@property(strong,nonatomic)NSArray *tags;
@property(strong,nonatomic)NSArray *events;
@property(strong,nonatomic)NSArray *relations;

@property(strong,nonatomic)NSArray *sectionTitles;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

// view of add new contact
@property(weak,nonatomic)UITextField *addContactValueField;
@property(weak,nonatomic)UITextField *addContactLabelField;

@property(nonatomic)NSString * addingContactType;


@end

@implementation ContactDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sectionTitles=@[@"联系信息",@"事项",@"标签",@"关系"];
    [self configureTableHV];
    [self.tableView reloadData];

    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden=YES;

}
-(void)viewDidLayoutSubviews{

    self.qrImageView.bounds=CGRectMake(0, 0, 200, 200);
    self.qrImageView.center=CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.tableHeaderView.bounds));

}
-(void)configureTableHV{

    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 250)];
    self.tableView.tableHeaderView=view;

    UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectZero];

    imageView.image=[UIImage mdQRCodeForString:[Contact QRStringOfContact:self.contact] size:200 fillColor:[UIColor darkGrayColor]];
    [view addSubview:imageView];
    self.qrImageView=imageView;

}

-(NSArray *)tags{
    return [self.contact.underWhichTags allObjects];
}

-(NSArray *)events{
    return  [self.contact.attendWhichEvents allObjects];
}

-(NSArray *)relations{
    return  [self.contact.belongWhichRelations allObjects];
}

-(void)setContact:(Contact *)contact{
    _contact=contact;
    self.title=contact.contactName;

    NSArray *phones=[[ContactsManager sharedContactManager]phoneNumbersOfContact:contact];
    NSArray *emails=[[ContactsManager sharedContactManager]emailsOfContact:contact];
    self.contactInfos=[[@[] arrayByAddingObjectsFromArray:phones] arrayByAddingObjectsFromArray:emails];

    [self.tableView reloadData];

}
#pragma mark - table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:{
         // contact info
            return self.contactInfos.count;
            break;
        }
        case 1:{
            //  events
            return self.events.count;
            break;
        }
        case 2:{
            //  tags
            return self.tags.count;
            break;
        }
        case 3:{
            //  relations
            return 1;
            break;
        }
        default:{
            return 0;
            break;
        }
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=nil;
    if (indexPath.section == 0) {
        //contact info
        cell=[tableView dequeueReusableCellWithIdentifier:@"phone and email cell"];
        cell.textLabel.text = self.contactInfos[indexPath.row][PhoneLabel] ? self.contactInfos[indexPath.row][PhoneLabel] :self.contactInfos[indexPath.row][EmailLabel];
        cell.detailTextLabel.text =self.contactInfos[indexPath.row][PhoneNumber] ? self.contactInfos[indexPath.row][PhoneNumber] :self.contactInfos[indexPath.row][EmailValue];
    }else if (indexPath.section ==1 ){
        //event;
        cell=[tableView dequeueReusableCellWithIdentifier:@"event"];
        cell.imageView.image=[UIImage imageNamed:@"eventindicator"];
        Event *event=(Event *)self.events[indexPath.row];
        cell.textLabel.text=event.event;
        if (event.date) {
            cell.detailTextLabel.text=[NSDateFormatter localizedStringFromDate:[event nextdate] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
        }

    }else if(indexPath.section ==2){
        //tags
        cell=[tableView dequeueReusableCellWithIdentifier:@"tag cell"];
        if (!cell) {
            cell=[[TagCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tag cell"];
            [(TagCell *)cell setHasCloseButton:YES];
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
            ((TagCell *)cell).closeButtonTapped=^(Tag *tag){

                [self.contact removeUnderWhichTagsObject:tag];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];

            };
        }
        ((TagCell *)cell).myTag = self.tags[indexPath.row];

    }else if (indexPath.section == 3 ){
        cell=[tableView dequeueReusableCellWithIdentifier:@"relations"];
        cell.textLabel.text=[NSString stringWithFormat:@"与通讯录中%@人有关联",@(self.relations.count)];
    }
    return cell;

}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return self.sectionTitles[section];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section != 3) {
        return 44.0;
    }
    return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *view=[[UIView alloc]init];
    UIButton *button=nil;
    NSString *title;
    SEL selector;
    // configure buttons
    if (section !=3) {
        button=[[UIButton alloc]init];
        [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [button setBackgroundColor:[UIColor whiteColor]];
        button.frame=CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 44);

        switch ( section) {
            case 0:{
                if (self.addingContactType) {

                    UIView *addNewContactView=[self addNewContactView:self.addingContactType];
                    addNewContactView.frame=CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 44);
                    [view addSubview:addNewContactView];
                    button=nil;
                    break;

                }
                title=@"新建联系方式";
                selector=@selector(createContactInfo:);
                break;
            }
            case 1:{
                title=@"新建事项";
                selector=@selector(createEvent:);
                break;
            }
            case 2:{
                title=@"添加标签";
                selector=@selector(addTag:);

                break;
            }
            default:
                break;
        }
    }
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [view addSubview: button];

    return view;

}

#pragma mark - add contact tf delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.addContactLabelField resignFirstResponder];
    [self.addContactValueField resignFirstResponder];
}
-(void)textFieldDidEndEditing:(UITextField *)textField{

}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == self.addContactLabelField) {
        [self.addContactValueField becomeFirstResponder];
    }else if (textField == self.addContactValueField){
        if (!textField.text.length) {
            return NO;
        }else{
            NSString *label = self.addContactLabelField.text.length ? self.addContactLabelField.text : self.addContactLabelField.placeholder;
            NSString *value= textField.text;

            BOOL isPhone=![textField.text containsString:@"@"];
            [[ContactsManager sharedContactManager] addContactLabel:label value:value isPhoneNumber:isPhone];
            self.navigationItem.rightBarButtonItem=nil;
            self.addingContactType=nil;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

            [textField resignFirstResponder];
        }
    }
    return YES;
}

-(UIView *)addNewContactView:(NSString *)addingContactType{

    BOOL isPhone=[addingContactType isEqualToString:PhoneLabel] ;
    UIView *addNewContactView=[[UIView alloc]init];
    addNewContactView.backgroundColor=[UIColor orangeColor];

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

    UIButton *rightCancelButton=[[UIButton alloc]init];
    [rightCancelButton setTitle:@"取消" forState:UIControlStateNormal];
    valueField.rightView=rightCancelButton;

    return addNewContactView;

}
-(void)createContactInfo:(UIButton *)button{

    UIAlertController *chooseWhichKindofContact=[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [chooseWhichKindofContact addAction:[UIAlertAction actionWithTitle:@"新增电话" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        button.enabled=NO;
        self.addingContactType=PhoneLabel;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

        UIBarButtonItem *cancelButton=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAddingContact:)];
        self.navigationItem.rightBarButtonItem=cancelButton;

    }]];

    [chooseWhichKindofContact addAction:[UIAlertAction actionWithTitle:@"新增邮箱" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        button.enabled=NO;
        self.addingContactType=EmailLabel;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

        UIBarButtonItem *cancelButton=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAddingContact:)];
        self.navigationItem.rightBarButtonItem=cancelButton;

    }]];

    [chooseWhichKindofContact addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel  handler:^(UIAlertAction *action) {

    }]];


    [self presentViewController:chooseWhichKindofContact animated:YES completion:nil];

}

-(void)cancelAddingContact:(UIBarButtonItem *)barbutton{

    self.addingContactType=nil;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    self.navigationItem.rightBarButtonItem=nil;

}

-(void)createEvent:(UIButton *)button{
    [self performSegueWithIdentifier:@"add event" sender:nil];
}

-(IBAction)eventCreateFinished:(UIStoryboardSegue *)segue{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

-(void)addTag:(UIButton *)button{
    [self performSegueWithIdentifier:@"add tag" sender:nil];
}
//unwind from add tag view
-(IBAction)tagsAdded:(UIStoryboardSegue *)segue{

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"slection");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"contactInfo"]) {
        ContactInfoViewController *dstVC=(ContactInfoViewController *)segue.destinationViewController;
        dstVC.contact=self.contact;
        NSIndexPath *indexPath=[self.tableView indexPathForSelectedRow];
        dstVC.contactInfo=self.contactInfos[indexPath.row];
    }
    else if ([segue.identifier isEqualToString:@"add tag"]){

        AddTagViewController *dstVC=(AddTagViewController*)segue.destinationViewController;
        dstVC.contact=self.contact;

    }else if ([segue.identifier isEqualToString:@"showevent"]){
        UINavigationController *nav=(UINavigationController *)segue.destinationViewController;
        EventViewController *dstVC=nav.viewControllers[0];
        NSIndexPath *indexPath=[self.tableView indexPathForSelectedRow];
        Event *event=self.events[indexPath.row];
        dstVC.event=event;
        dstVC.forDisplay=YES;
    }else if ([segue.identifier isEqualToString:@"add event"]){
        UINavigationController *nav=(UINavigationController *)segue.destinationViewController;
        EventViewController *dstVC=nav.viewControllers[0];
        dstVC.event=[NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.contact.managedObjectContext];
        [dstVC.event addContactsWhichAttendObject:self.contact];
        dstVC.forDisplay=NO;
    }
}


@end
