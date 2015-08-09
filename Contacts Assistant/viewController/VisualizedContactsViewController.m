//
//  ViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/13/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "VisualizedContactsViewController.h"
#import "SearchAssistantView.h"
#import "ContactsManager.h"
#import "TagNavigationView.h"
#import "ActionsView.h"
#import "Tag+Utility.h"
#import "Contact+Utility.h"
#import "ContactCell.h"
#import "SMSReceiversView.h"
#import "EmailReceiversView.h"
#import "ContactDetailsViewController.h"

#import "QRCodeReaderViewController.h"
#import "QRCodeReader.h"
#import "QRCodeReaderDelegate.h"
#import "QRScanResultViewController.h"


CGFloat const SearchAssistantViewHeight=150.0;
CGFloat const OperationViewWidth = 200;
CGFloat const OperationViewHeight = 238;
typedef enum : NSUInteger {
    TVSelectionModeNormal=0,
    TVSelectionModeBatchSMS,
    TVSelectionModeBatchEmail,
} TVSelectionMode;

@interface VisualizedContactsViewController ()<UISearchResultsUpdating,UISearchControllerDelegate,UISearchBarDelegate,ActionsViewDelegate,ContactsManagerDelegate,UITableViewDataSource,UITableViewDelegate,QRCodeReaderDelegate,ContactCellDelegate>

//table view
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(strong,nonatomic)UITableViewRowAction *deleteAction;
@property(strong,nonatomic)UITableViewRowAction *renameAction;
@property(strong,nonatomic)UITableViewRowAction *moreAction;
@property(strong,nonatomic)UITableViewRowAction *shareAction;

//search
@property(strong,nonatomic)UISearchController *searchController;
@property(weak,nonatomic)SearchAssistantView *searchAssistant;


// button button
@property (weak, nonatomic) UIButton *moreFunctionsButton;
@property(weak,nonatomic)SMSReceiversView *smsReceiversView;
@property(weak,nonatomic)EmailReceiversView *eMailReceiversView;
@property(weak,nonatomic)UIButton *titleButton;


@property(weak,nonatomic)UIView *customDimmingView;
@property(weak,nonatomic)UIView *moreFunctionsContainerView;
@property(weak,nonatomic)TagNavigationView *tagNavigationView;


@property(strong,nonatomic) ContactsManager * contactManager;
@property(nonatomic) TVSelectionMode selectionMode;

@property(strong,nonatomic)NSMutableArray *arrangedContactsUnderCurrentTag;
@property(strong,nonatomic) NSMutableArray *contacts;
@property(strong,nonatomic)NSMutableArray *indexTitles;

@property(strong,nonatomic)NSMutableArray *cellHeight;
@property(strong,nonatomic) Tag *currentTag;

@end

@implementation VisualizedContactsViewController


- (void)viewDidLoad {

    [super viewDidLoad];
    [self prepareSearchController];
    [self configureMoreFunctionButton];
    [self configureTitleView];

    dispatch_queue_t updateCoreDataQueue = dispatch_queue_create("UpdateCoreDataQueue", NULL);
    dispatch_async(updateCoreDataQueue, ^{

        [self.contactManager updateCoreDataBasedOnContacts];
        
    });



}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coreDataUpdatingFinished:) name:ContactManagerDidFinishUpdatingCoreData object:nil];

    self.moreFunctionsButton.frame=CGRectMake(CGRectGetWidth(self.view.bounds)/2-70/2, CGRectGetHeight(self.view.bounds)-44-12, 70, 44);

}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ContactManagerDidFinishUpdatingCoreData object:nil];
}

-(void)coreDataUpdatingFinished:(NSNotification *)notification{

    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{

            self.currentTag=[Tag rootTag];

        });

    });
}
-(ContactsManager *)contactManager{

    if (!_contactManager) {
        _contactManager=[ContactsManager sharedContactManager];
    }
    return _contactManager;
}
-(void)configureMoreFunctionButton{

    UIButton *moreFunctionButton=[[UIButton alloc]init];

    UIImage *image=[[UIImage imageNamed:@"ActionIconNoFill"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4) resizingMode:UIImageResizingModeStretch];
    [moreFunctionButton setBackgroundImage:image forState:UIControlStateNormal];
    self.moreFunctionsButton=moreFunctionButton;

    [self.view addSubview:moreFunctionButton];

    [moreFunctionButton addTarget:self action:@selector(displayMoreActions:) forControlEvents:UIControlEventTouchUpInside];

}

-(NSAttributedString *)createTitle:(NSString *)string{

    UIImage *image=[UIImage imageNamed:@"TagViewSelectedBKG"];

    NSTextAttachment *textAttachment=[[NSTextAttachment alloc]init];
    textAttachment.image=image;

    NSAttributedString *titleIndocator=[NSAttributedString attributedStringWithAttachment:textAttachment];
    NSMutableAttributedString *attributedTitle=[[NSMutableAttributedString alloc]initWithString:string] ;
    [attributedTitle appendAttributedString:titleIndocator];

    return attributedTitle;

}
-(void)configureTitleView{

    UIButton *button=[[UIButton alloc]init];
    [button setAttributedTitle:[self createTitle:@"所有联系人"] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(prepareSwitchTag:) forControlEvents:UIControlEventTouchUpInside];
    self.titleButton=button;
    self.navigationItem.titleView=button;

}
#pragma mark - Actions
-(void)prepareSwitchTag:(UIButton *)button{
    if (self.tagNavigationView) {
        [self dismissDimmingView:nil];
        return;
    }
    // dim bkg
    [self dim];
    self.navigationItem.rightBarButtonItem.enabled=NO;
    self.navigationItem.leftBarButtonItem.enabled=NO;

    // prepare action view
    TagNavigationView *tagNavigationView=[[[NSBundle mainBundle]loadNibNamed:@"TagNavigationView" owner:nil options:nil] lastObject];
    tagNavigationView.didSelectTag=^(Tag *tag){
        self.currentTag = tag;
        [self.titleButton setAttributedTitle:[self createTitle:tag.tagName] forState:UIControlStateNormal];
        [self dismissDimmingView:nil];
    };
    tagNavigationView.manageTags=^{
        NSLog(@"manage tags");
    };


    [self.view addSubview:tagNavigationView];
    self.tagNavigationView=tagNavigationView;

    //calculate geometry
    CGRect frame=CGRectMake(0, -200, CGRectGetWidth(self.view.bounds), 200);
    tagNavigationView.frame=frame;
    [tagNavigationView layoutIfNeeded];

    // display with animation
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
        self.customDimmingView.alpha=0.7;
        tagNavigationView.frame=CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 200);
    } completion:nil];

}

-(void )prepareSearchController{


    //configure Search Controller
    UISearchController *searchController=[[UISearchController alloc]initWithSearchResultsController:nil];
    self.searchController=searchController;
    searchController.searchResultsUpdater=self;
    searchController.delegate=self;
    searchController.dimsBackgroundDuringPresentation=NO;
    searchController.hidesNavigationBarDuringPresentation=YES;


    //configure searchBar
    UISearchBar *searchBar=searchController.searchBar;
    searchBar.placeholder=@"姓名、公司、部门、电话、邮箱或者标签";
    searchBar.delegate=self;
    searchBar.showsCancelButton=NO;

    searchBar.bounds=CGRectMake(0, 0, 0, 44);
    self.tableView.tableHeaderView =searchBar;
    [self.tableView setContentOffset:CGPointMake(0, 44)];

}
-(void)dim{
    UIView *dimmingView=[[UIView alloc]initWithFrame:self.tableView.frame];
    dimmingView.backgroundColor=[UIColor darkGrayColor];
    self.customDimmingView=dimmingView;
    self.customDimmingView.alpha=0.0;
    [self.view addSubview:dimmingView];

    UITapGestureRecognizer *tapToDismissAdd=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissDimmingView:)];
    [self.customDimmingView addGestureRecognizer:tapToDismissAdd];
}
-(void)dismissDimmingView:(UITapGestureRecognizer *)gesture{

    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:-0.5 options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut animations:^{

        self.customDimmingView.alpha=0.0;
        self.moreFunctionsButton.frame=CGRectMake(CGRectGetWidth(self.view.bounds)/2-70/2, CGRectGetHeight(self.view.bounds)-44-12, 70, 44);
        self.moreFunctionsContainerView.frame=CGRectInset(self.moreFunctionsButton.frame, 35, 22);
        self.tagNavigationView.frame=CGRectMake(0, -150-70, CGRectGetWidth(self.view.bounds), 150);
        self.searchAssistant.frame=CGRectMake(0, -120-70, CGRectGetWidth(self.view.bounds), 120);

    } completion:^(BOOL finished) {
        [self.customDimmingView removeFromSuperview];
        [self.moreFunctionsContainerView removeFromSuperview];
        [self.tagNavigationView removeFromSuperview];
    }];

    self.navigationItem.rightBarButtonItem.enabled=YES;
    self.navigationItem.leftBarButtonItem.enabled=YES;

}

- (void)displayMoreActions:(UIButton *)sender {
    // dim bkg
    [self dim];

    self.navigationItem.rightBarButtonItem.enabled=NO;
    self.navigationItem.leftBarButtonItem.enabled=NO;
    // prepare scroll view
    UIScrollView *scrollView=[[UIScrollView alloc]init];
    self.moreFunctionsContainerView=scrollView;
    scrollView.backgroundColor=[UIColor lightGrayColor];
    [self.view addSubview:scrollView];

    // prepare action view
    ActionsView *moreActionsView=[[[NSBundle mainBundle]loadNibNamed:@"MoreFuctionsView" owner:nil options:nil] lastObject];
    [scrollView addSubview:moreActionsView];
    moreActionsView.delegate=self;
    moreActionsView.type=ActionViewMoreFunctionsView;

    //calculate geometry
    scrollView.contentSize=CGSizeMake(CGRectGetWidth(self.view.bounds), 100);
    scrollView.frame=CGRectInset(self.moreFunctionsButton.frame, 35, 22);
    moreActionsView.frame=scrollView.bounds;
    [moreActionsView layoutIfNeeded];
    CGRect frame=CGRectMake(4, CGRectGetHeight(self.view.bounds)-200-20, CGRectGetWidth(self.view.bounds)-8,200);

    // display with animation
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
        self.customDimmingView.alpha=0.7;
        self.moreFunctionsButton.frame=frame;
        scrollView.frame=CGRectInset(frame, 4, 4);
        moreActionsView.frame=CGRectInset(scrollView.bounds, 4, 4);
    } completion:nil];

}
#pragma mark -ActionViewDelegate
-(void)actionView:(ActionsView *)actionView actionButtonTapped:(NSInteger)buttonTag{

    [self dismissDimmingView:nil];

    [self moreFunctionButtonTapped:buttonTag];

}


-(void)moreFunctionButtonTapped:(NSInteger)buttonTag{
    self.navigationItem.leftBarButtonItem.enabled=NO;
    switch (buttonTag) {
        case ActionViewButtonMoreFunctionSMS:{
            NSLog(@"SMS");

            self.contacts=(NSMutableArray *)[self.contactManager filterContactsWithoutPhoneNumbers:self.contacts];
            NSLog(@"contacts:%@",@(self.contacts.count));

            self.selectionMode=TVSelectionModeBatchSMS;

            [self.tableView setEditing:YES animated:NO];
            [self configureSMSReceiversView];


            break;
        }
        case ActionViewButtonMoreFunctionEmail:{
            NSLog(@"email");

            self.contacts=(NSMutableArray *)[self.contactManager filterContactsWithoutemail:self.contacts];
            NSLog(@"contacts:%@",@(self.contacts.count));
            self.selectionMode=TVSelectionModeBatchEmail;
            // 提醒用户，选择邮件 ???

            [self.tableView setEditing:YES animated:NO];
            [self configureEmailReceiversView];

            break;
        }
        case ActionViewButtonMoreFunctionScanQR:{
            [self prepareScanQR];
            break;
        }
        case ActionViewButtonMoreFunctionManuallyAdd:{
            break;
        }
        case ActionViewButtonMoreFunctionShareContacts:{
            [self.tableView setEditing:YES animated:NO];
            break;
        }

    }

}
-(void)prepareScanQR{

    if ([QRCodeReader supportsMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]) {

        static QRCodeReaderViewController *reader = nil;
        static dispatch_once_t onceToken;

        dispatch_once(&onceToken, ^{
            reader                        = [QRCodeReaderViewController new];
            reader.modalPresentationStyle = UIModalPresentationFormSheet;
        });
        reader.delegate = self;

        [reader setCompletionWithBlock:^(NSString *resultAsString) {
            NSLog(@"Completion with result: %@", resultAsString);
        }];

        [self presentViewController:reader animated:YES completion:NULL];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Reader not supported by the current device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
    }
}
#pragma mark - QRCodeReader Delegate Methods

- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
        [self dismissViewControllerAnimated:NO completion:nil];

        NSDictionary *resultinfo=[Contact infoFromQRString:result];

        UINavigationController *nav=[self.storyboard instantiateViewControllerWithIdentifier:@"scanresultvc"];
        QRScanResultViewController *scanresultvc=(QRScanResultViewController *)nav.viewControllers[0];
        scanresultvc.resultInfo=resultinfo;

        [self presentViewController:nav animated:YES completion:nil];

}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)configureSMSReceiversView{

    SMSReceiversView *receiversView=[[[NSBundle mainBundle]loadNibNamed:@"SMSReceiversView" owner:nil options:nil] lastObject];
    self.smsReceiversView=receiversView;
    [self.view addSubview:receiversView];
    CGRect frame=CGRectMake(4, CGRectGetMaxY(self.view.bounds), CGRectGetWidth(self.view.bounds)-8, 150);
    receiversView.frame=CGRectInset(frame, CGRectGetWidth(self.view.bounds)/4, 10);
    [receiversView layoutIfNeeded];

    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         receiversView.frame=CGRectOffset(frame, 0, -150);
                     }
                     completion:nil];

    __weak SMSReceiversView * weakReceiverView=receiversView;
    receiversView.cancelSMSHandler=^{
        [self.tableView setEditing:NO animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.selectionMode=TVSelectionModeNormal;
        self.contacts=self.arrangedContactsUnderCurrentTag;
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             weakReceiverView.frame =  CGRectInset(frame, CGRectGetWidth(self.view.bounds)/4, 10);                                 }
                         completion:^(BOOL finished) {
                             [weakReceiverView removeFromSuperview];
                         }];
    };

}
-(void)configureEmailReceiversView{

    EmailReceiversView *emailReceiverView=[[[NSBundle mainBundle]loadNibNamed:@"EmailReceversView" owner:nil options:nil] lastObject];
    self.eMailReceiversView=emailReceiverView;
    [self.view addSubview:emailReceiverView];
    CGRect frame=CGRectMake(4, CGRectGetMaxY(self.view.bounds), CGRectGetWidth(self.view.bounds)-8, 150);
    emailReceiverView.frame=CGRectInset(frame, CGRectGetWidth(self.view.bounds)/4, 10);
    [emailReceiverView layoutIfNeeded];

    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         emailReceiverView.frame=CGRectOffset(frame, 0, -150);
                     }
                     completion:nil];

    __weak EmailReceiversView * weakEmailReceiverView=emailReceiverView;
    emailReceiverView.cancelEmailHandler=^{
        [self.tableView setEditing:NO animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.selectionMode=TVSelectionModeNormal;
        self.contacts=self.arrangedContactsUnderCurrentTag;
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             weakEmailReceiverView.frame =  CGRectInset(frame, CGRectGetWidth(self.view.bounds)/4, 10);                                 }
                         completion:^(BOOL finished) {
                             [weakEmailReceiverView removeFromSuperview];
                         }];
    };

}

#pragma  mark - UISearchResultsUpdatingDelegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController{


    NSMutableArray *keywords=[@[] mutableCopy];
    for (NSString *subString in [searchController.searchBar.text componentsSeparatedByString:@" "]) {
        NSString *string=[subString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (string.length) {
            [keywords addObject:string];
        }
    }
    if (!keywords.count) {
        self.contacts=self.arrangedContactsUnderCurrentTag;
        [self.searchAssistant removeFromSuperview];
    }

    NSDictionary *results=[self.contactManager searchContacts:self.arrangedContactsUnderCurrentTag keywords:keywords];
    if (!results) {
        return;
    }

    NSArray *advicedTags=[results[AdvicedTagsKey] valueForKey:@"tagName"];
    NSLog(@"updating with keywords:%@",keywords);
    NSLog(@"advicedTags:%@",advicedTags);
    NSArray *advicedContacts=[results[AdvicedContactsKey] valueForKey:@"contactName"];
    NSLog(@"advicedContacts:%@",advicedContacts);

    NSArray *searchResultContact=results[SearchResultContactsKey];

    for (NSArray *subResults in searchResultContact) {
        NSLog(@"subResults:%@",[subResults valueForKey:@"contactName"]);
    }

    // update table view
    self.searchAssistant.searchAdvice=@{AdvicedTagsKey:results[AdvicedTagsKey],
                                        AdvicedContactsKey:results[AdvicedContactsKey]};
    self.contacts=results[SearchResultContactsKey];


}
#pragma mark - UISearchBarDelegate

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self dismissSearchAssistantView];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    [self dismissSearchAssistantView];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    [self showSearchAssistantView];
}

-(void)dismissSearchAssistantView{
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.searchAssistant.frame=CGRectMake(0, -120,CGRectGetWidth(self.searchController.searchBar.bounds), 120);;
                     }
                     completion:^(BOOL finished){
                         [self.searchAssistant removeFromSuperview];
                     }];

}

-(void)showSearchAssistantView{
    if (self.searchAssistant) {
        return;
    }
    dispatch_queue_t searchAssistantCreationQueue = dispatch_queue_create("SearchAssistantView", NULL);

    dispatch_async(searchAssistantCreationQueue, ^{
        // create search Assistant view
        SearchAssistantView *searchAssistantView=[[[NSBundle mainBundle]loadNibNamed:@"SearchAssistantView" owner:nil options:nil]lastObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            // update UI in main queue
            searchAssistantView.advicedContactSelectedHandler=^(Contact *contact){
                self.contacts=[@[@[contact]] mutableCopy];
            };
            searchAssistantView.advicedTagSelectedHandler=^(Tag *tag){

                self.currentTag=tag;
                [self.titleButton setAttributedTitle:[self createTitle:tag.tagName] forState:UIControlStateNormal];

            };
            [self.view addSubview:searchAssistantView];
            self.searchAssistant=searchAssistantView;

            // calcute geometry info
            CGRect frame=CGRectMake(0, CGRectGetMaxY(self.searchController.searchBar.frame), CGRectGetWidth(self.searchController.searchBar.bounds), 120);
            searchAssistantView.frame=CGRectMake(0, -120,CGRectGetWidth(frame), 120);
            [searchAssistantView layoutIfNeeded];

            // display with animation
            [UIView animateWithDuration:0.5
                                  delay:0
                 usingSpringWithDamping:0.7
                  initialSpringVelocity:0.5
                                options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 searchAssistantView.frame=frame;
                             }
                             completion:nil];
        });
    });
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - contact


-(void)setSelectionMode:(TVSelectionMode)selectionMode{
    _selectionMode=selectionMode;

    [self.tableView reloadData];

}
-(NSMutableArray *)indexTitles{
    if (!_indexTitles) {
        _indexTitles=[@[] mutableCopy];
    }
    return _indexTitles;
}

-(void)setContacts:(NSMutableArray *)contacts{
    _contacts=contacts;

    // reset indexTitles
    self.indexTitles=nil;
    for (int section=0; section<contacts.count; section++) {
        NSArray *contactsInSection=contacts[section];
        Contact *contact=[contactsInSection firstObject];
        if (contact.contactOrderWeight.doubleValue != 0.0) {
            [self.indexTitles addObject:@"☆"];
        }else{
            NSString *firstLetter=[self.contactManager firstLetter:contact];
            [self.indexTitles addObject:firstLetter];
        }
    }

    [self.tableView reloadData];
}


-(void)setCurrentTag:(Tag *)currentTag{

    _currentTag=currentTag;
    self.arrangedContactsUnderCurrentTag =[self arrangedContactsunderTag:currentTag];
    self.contacts=self.arrangedContactsUnderCurrentTag;
}
-(NSMutableArray *)arrangedContactsunderTag:(Tag *)tag{
    NSArray *contacts;
    // get all contact under currentTag;
    if ([tag isRootTag]) {
        contacts = [Contact allContacts];
    }else{
        contacts = [tag allOwnedContacts];
    }
    return [self rearrangeContacts:contacts];

}

-(NSMutableArray *)rearrangeContacts:(NSArray *)contacts{

    NSMutableArray *sortedContacts=[[contacts sortedArrayUsingComparator:^NSComparisonResult(Contact * obj1, Contact * obj2) {
        return [self.contactManager compareResult:obj1 contact2:obj2];
    }] mutableCopy];

    NSMutableArray *rearrangedContacts=[@[] mutableCopy];

    // get the top contacts
    NSPredicate *topContactsPredicate=[NSPredicate predicateWithFormat:@"contactOrderWeight.doubleValue != %f",@(0.0)];
    NSArray *topContacts=[sortedContacts filteredArrayUsingPredicate:topContactsPredicate];
    if (topContacts.count) {
        [rearrangedContacts addObject:topContacts];
        [sortedContacts removeObjectsInArray:topContacts];
    }

    // arrange the left contacts
    NSMutableArray *contactsInSameSection=[@[] mutableCopy];
    for (int i =0 ; i<sortedContacts.count; i++) {
        Contact *contactToBeArranged=sortedContacts[i];
        NSString *firstLetter=[self.contactManager firstLetter:contactToBeArranged];
        NSString *sectionLetter=[self.contactManager firstLetter:[contactsInSameSection lastObject]];
        if (![firstLetter isEqualToString:sectionLetter]) {
            contactsInSameSection =[@[] mutableCopy];
            [rearrangedContacts addObject:contactsInSameSection];
        }
        [contactsInSameSection addObject:contactToBeArranged];
    }

    return rearrangedContacts;
}

#pragma  mark - navigaiton
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"contactDetail"]) {
        ContactDetailsViewController *dstvc=(ContactDetailsViewController *)segue.destinationViewController;
        dstvc.contact=(Contact *)sender;
    }

}
#pragma  mark - tableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.contacts.count;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [(NSArray *)self.contacts[section] count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    ContactCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Contact Cell"];
    if (!cell) {
        cell=[[ContactCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Contact Cell"];
    }
    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    cell.contact=contact;
    cell.delegate=self;
    switch (self.selectionMode) {
        case TVSelectionModeBatchSMS:{
            cell.mode=ContactCellModeSMS;
            break;
        }
        case TVSelectionModeBatchEmail:{
            cell.mode=ContactCellModeEmail;
            break;
        }
        default:{
            cell.mode=ContactCellModeNormal;

        }
    }
    return cell;

}
// height
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath

{
    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    if (self.selectionMode == TVSelectionModeBatchSMS)
    {
        return  60 + ([self.contactManager phoneNumbersOfContact:contact].count-1) * 15;

    }else if (self.selectionMode == TVSelectionModeBatchEmail) {

        return  60 + ([self.contactManager emailsOfContact:contact].count-1) * 15;

    }else{
        return [contact recentEvent] ? 120 :90;
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 24;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{

    NSString *title=self.indexTitles[section];
    if ([title isEqualToString:@"☆"]) {
        NSMutableString *string=[@"" mutableCopy];
        for (int i =0 ; i< [(NSArray *)self.contacts[0] count]; i++) {
            [string appendString:title];
        }
        return string;
    }
    return title;
}
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    return self.indexTitles;
}
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    return index;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return YES;
}
#pragma mark - tableviewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    if (tableView.isEditing) {
        switch (self.selectionMode) {
            case TVSelectionModeBatchSMS:{

                NSArray *numbers=[self.contactManager phoneNumbersOfContact:contact];
                if (numbers.count <= 1) {
                    [self.smsReceiversView addContactAtIndex:indexPath.row
                                                    withName:contact.contactName
                                             andPhoneNumbers:[numbers valueForKey:PhoneNumber]];
                    break;
                }
                // configure alertController
                UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"向以下号码发送短信" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

                for (NSDictionary *number in numbers) {
                    NSString *title=[NSString stringWithFormat:@"%@: %@", number[PhoneLabel],number[PhoneNumber]];
                    UIAlertAction *action=[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [self.smsReceiversView addContactAtIndex:indexPath.row withName:contact.contactName andPhoneNumbers:@[number[PhoneNumber]]];
                    }];
                    [alertController addAction:action];
                }
                UIAlertAction *selectAllAction=[UIAlertAction actionWithTitle:@"全部号码" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self.smsReceiversView addContactAtIndex:indexPath.row
                                                    withName:contact.contactName
                                             andPhoneNumbers:[numbers valueForKey:PhoneNumber]];
                }];
                [alertController addAction:selectAllAction];
                UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }];
                [alertController addAction:cancelAction];

                [self presentViewController:alertController animated:YES completion:nil];

                break;
            }
            case TVSelectionModeBatchEmail:{
                NSArray *emails=[self.contactManager emailsOfContact:contact];
                if (emails.count <= 1) {
                    [self.eMailReceiversView addContactAtIndex:indexPath.row
                                                    withName:contact.contactName
                                             andEmails:emails];
                    break;
                }
                // configure alertController
                UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"向以下号码发送邮件" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

                for (NSDictionary *email in emails) {
                    NSString *title=[NSString stringWithFormat:@"%@: %@", email[EmailLabel],email[EmailValue]];
                    UIAlertAction *action=[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [self.eMailReceiversView addContactAtIndex:indexPath.row withName:contact.contactName andEmails:@[email]];
                    }];
                    [alertController addAction:action];
                }
                UIAlertAction *selectAllAction=[UIAlertAction actionWithTitle:@"选择全部" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self.eMailReceiversView addContactAtIndex:indexPath.row
                                                    withName:contact.contactName
                                             andEmails:emails];
                }];
                [alertController addAction:selectAllAction];
                UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }];
                [alertController addAction:cancelAction];

                [self presentViewController:alertController animated:YES completion:nil];
                break;
            }
            default:{
                break;
            }
        }
        return;
    }

    //navigate to contact detail vc
    [self performSegueWithIdentifier:@"contactDetail" sender:contact];
}
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.isEditing) {
        switch (self.selectionMode) {
            case TVSelectionModeBatchSMS:{
                [self.smsReceiversView removeContactAtIndex:indexPath.row];
                break;
            }
            case TVSelectionModeBatchEmail:{
                [self.eMailReceiversView removeContactAtIndex:indexPath.row];
                break;
            }
            default:{
                break;
            }
        }
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //To enable the swipe-to-delete feature of table views (wherein a user swipes horizontally across a row to display a Delete button), you must implement this method
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @[self.deleteAction,self.shareAction];
}


-(UITableViewRowAction *)deleteAction{
    if (!_deleteAction) {
        _deleteAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"delete");
        }];
    }
    return _deleteAction;
}
-(UITableViewRowAction *)renameAction{
    if (!_renameAction) {
        _renameAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"重命名" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"Rename");
        }];
        _renameAction.backgroundColor=[UIColor orangeColor];
    }
    return _renameAction;
}
-(UITableViewRowAction *)moreAction{
    if (!_moreAction) {
        _moreAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"置顶" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"more");
        }];
        _moreAction.backgroundColor=[UIColor lightGrayColor];
    }
    return _moreAction;
}
-(UITableViewRowAction *)shareAction{
    if (!_shareAction) {
        _shareAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"分享" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"share");
        }];
        _shareAction.backgroundColor=[UIColor orangeColor];

    }
    return _shareAction;
}
#pragma mark - cell delegate;

-(UIAlertController *)alertControllerPhonesOrEmails:(NSArray *)infos
                                      actionHandler:(void(^)(UIAlertAction *action))handler
                                      cancelHandler:(void(^)(UIAlertAction *action))cancleHandler{

    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSDictionary *info in infos) {
        NSString *title=[NSString stringWithFormat:@"%@: %@", info[PhoneLabel] ? info[PhoneLabel] : info[EmailLabel] ,info[PhoneNumber] ? info[PhoneNumber] : info[EmailValue]];

        UIAlertAction *action=[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:handler];
        [alertController addAction:action];
    }
    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:cancleHandler];
    [alertController addAction:cancelAction];
    return alertController;

}

-(void)phone:(Contact *)contact availableNumbers:(NSArray *)numbers{

    UIAlertController *phoneAlertController=[self alertControllerPhonesOrEmails:numbers actionHandler:^(UIAlertAction *action) {
        NSLog(@"call");
    } cancelHandler:nil];
    phoneAlertController.message=[NSString stringWithFormat:@"给 %@ 打电话",contact.contactName];

    [self presentViewController:phoneAlertController animated:YES completion:nil];


}
-(void)sms:(Contact *)contact availableNumbers:(NSArray *)numbers {

    UIAlertController *phoneAlertController=[self alertControllerPhonesOrEmails:numbers actionHandler:^(UIAlertAction *action) {
        NSLog(@"sms");
    }cancelHandler:nil];
    phoneAlertController.message=[NSString stringWithFormat:@"给 %@ 发短信",contact.contactName];

    [self presentViewController:phoneAlertController animated:YES completion:nil];

}
-(void)email:(Contact *)contact availableEmails:(NSArray *)emails {

    UIAlertController *phoneAlertController=[self alertControllerPhonesOrEmails:emails actionHandler:^(UIAlertAction *action) {
        NSLog(@"email");
    }cancelHandler:nil];
    phoneAlertController.message=[NSString stringWithFormat:@"给 %@ 发邮件",contact.contactName];

    [self presentViewController:phoneAlertController animated:YES completion:nil];

}
-(void)putToTop:(UITableViewCell *)cell{

    Contact *contact=[(ContactCell *)cell contact];
    NSIndexPath *indexPath=[self.tableView indexPathForCell:cell];

    // remove the contact from the orig
    [self.contacts[indexPath.section] removeObjectAtIndex:indexPath.row];
    if ([self.contacts[indexPath.section] count] < 1) {
        [self.contacts removeObjectAtIndex:indexPath.section];
        [self.indexTitles removeObjectAtIndex:indexPath.section];
    }

    if ([self.indexTitles containsObject:@"☆"]) {
        [self.contacts[0] insertObject:contact atIndex:0];
        if ([self.contacts[0] count] > 5) {
            // if more than 10 in the top contacts, downgrade the last one
            Contact *lastOne=[self.contacts[0] lastObject];
            lastOne.contactOrderWeight=@(0);
            [self.contacts[0] removeObject:lastOne];

            NSString *lastOneTitle=[self.contactManager firstLetter:lastOne];
            NSInteger index=[self.indexTitles indexOfObject:lastOneTitle];
            if (index != NSNotFound) {
                //if has corresponding index title, move the last one contact to corresponding section and re-order
                [self.contacts[index] addObject:lastOne];
                self.contacts[index]=[[self.contacts sortedArrayUsingComparator:^NSComparisonResult(Contact * obj1, Contact * obj2) {
                        return [self.contactManager compareResult:obj1 contact2:obj2];
                }] mutableCopy];
            }else{
                // if no, add its first letter to indextitles and reorder, then add a new mutablearray to contacts
                [self.indexTitles addObject:lastOneTitle];
                self.indexTitles =[[self.indexTitles sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
                    return [obj1 compare:obj2];
                }] mutableCopy];
                NSInteger topTitleIndex=[self.indexTitles indexOfObject:@"☆"];
                [self.indexTitles removeObjectAtIndex:topTitleIndex];
                [self.indexTitles insertObject:@"☆" atIndex:0];

                NSInteger lastOneTitleIndex=[self.indexTitles indexOfObject:lastOneTitle];
                [self.contacts insertObject:[@[lastOne] mutableCopy]  atIndex:lastOneTitleIndex];
            }
        }
    }else{
        [self.indexTitles insertObject:@"☆" atIndex:0];
        NSMutableArray *topContact=[@[contact] mutableCopy];
        [self.contacts insertObject:topContact atIndex:0];
    }
    [self.tableView reloadData];

}















@end
