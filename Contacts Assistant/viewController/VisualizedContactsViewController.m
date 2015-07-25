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

CGFloat const SearchAssistantViewHeight=150.0;
CGFloat const OperationViewWidth = 200;
CGFloat const OperationViewHeight = 238;
typedef enum : NSUInteger {
    TVSelectionModeNone=0,
    TVSelectionModeDelete,
    TVSelectionModeMove,
    TVSelectionModeBatchSMS,
    TVSelectionModeBatchEmail,
    TVSelectionModeBatchShare,
} TVSelectionMode;

@interface VisualizedContactsViewController ()<UISearchResultsUpdating,UISearchControllerDelegate,UISearchBarDelegate,ActionsViewDelegate,ContactsManagerDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(strong,nonatomic)UITableViewRowAction *deleteAction;
@property(strong,nonatomic)UITableViewRowAction *renameAction;
@property(strong,nonatomic)UITableViewRowAction *moreAction;
@property(strong,nonatomic)UITableViewRowAction *shareAction;


@property (weak, nonatomic) UIButton *moreFunctionsButton;

@property(strong,nonatomic)UISearchController *searchController;

@property(weak,nonatomic)UIView *customDimmingView;
@property(weak,nonatomic)UIView *moreFunctionsContainerView;
@property(weak,nonatomic)SearchAssistantView *searchAssistant;
@property(weak,nonatomic)TagNavigationView *tagNavigationView;

@property(weak,nonatomic)SMSReceiversView *smsReceiversView;
@property(weak,nonatomic)EmailReceiversView *eMailReceiversView;

@property(strong,nonatomic) ContactsManager * contactManager;
@property(nonatomic) TVSelectionMode selectionMode;

@property(strong,nonatomic) NSMutableArray *contacts;
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
            [self.tableView reloadData];
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
-(void)configureTitleView{

    UIButton *button=[[UIButton alloc]init];
    [button setTitle:@"Group" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(prepareSwitchTag:) forControlEvents:UIControlEventTouchUpInside];

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

    };
    tagNavigationView.manageTags=^{

    };
    [self.view addSubview:tagNavigationView];
    self.tagNavigationView=tagNavigationView;

    //calculate geometry
    CGRect frame=CGRectMake(0, -150, CGRectGetWidth(self.view.bounds), 150);
    tagNavigationView.frame=frame;
    [tagNavigationView layoutIfNeeded];

    // display with animation
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
        self.customDimmingView.alpha=0.7;
        tagNavigationView.frame=CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 150);
    } completion:nil];

}

-(void )prepareSearchController{

    if (self.searchController) {
        return;
    }
    //configure Search Controller
    UISearchController *searchController=[[UISearchController alloc]initWithSearchResultsController:nil];
    self.searchController=searchController;
    searchController.searchResultsUpdater=self;
    searchController.delegate=self;
    [searchController setHidesNavigationBarDuringPresentation:YES];
    [searchController setDimsBackgroundDuringPresentation:YES];

    //configure searchBar
    UISearchBar *searchBar=searchController.searchBar;
    searchBar.placeholder=@"Keyword: Contact Info or Tag Name";
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
//        self.batchEditingContainerView.frame=CGRectMake(0, -100-70, CGRectGetWidth(self.view.bounds), 100);
        self.tagNavigationView.frame=CGRectMake(0, -150-70, CGRectGetWidth(self.view.bounds), 150);
        self.searchAssistant.frame=CGRectMake(0, -120-70, CGRectGetWidth(self.view.bounds), 120);

    } completion:^(BOOL finished) {
        [self.customDimmingView removeFromSuperview];
        [self.moreFunctionsContainerView removeFromSuperview];
//        [self.batchEditingContainerView removeFromSuperview];
        [self.tagNavigationView removeFromSuperview];
    }];

    self.navigationItem.rightBarButtonItem.enabled=YES;
    self.navigationItem.leftBarButtonItem.enabled=YES;

}
- (IBAction)prepareToBatchEditContacts:(UIBarButtonItem *)sender {
//    if (self.batchEditingContainerView) {
//        [self dismissDimmingView:nil];
//        return;
//    }
//    // dim bkg
//    [self dim];
//    self.navigationItem.rightBarButtonItem.enabled=NO;
//
//    // prepare scrollView
//    UIScrollView *scrollView=[[UIScrollView alloc]init];
//    scrollView.backgroundColor=[UIColor lightGrayColor];
//    [self.view addSubview:scrollView];
//    self.batchEditingContainerView=scrollView;
//    // prepare action view
//    ActionsView *batchEditing=[[[NSBundle mainBundle]loadNibNamed:@"BatchEditOptionsView" owner:nil options:nil] lastObject];
//    [scrollView addSubview:batchEditing];
//    batchEditing.delegate=self;
//    batchEditing.type=ActionViewBatchEditingView;
//
//    //calculate geometry
//    scrollView.contentSize=CGSizeMake(CGRectGetWidth(self.view.bounds)+5, 100);
//    CGRect frame=CGRectMake(0, -100, CGRectGetWidth(self.view.bounds), 100);
//    scrollView.frame=frame;
//
//    // display with animation
//    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
//        self.customDimmingView.alpha=0.7;
//        scrollView.frame=CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 100);
//        batchEditing.frame=CGRectOffset(scrollView.bounds, 4, 4);
//
//    } completion:nil];
//
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
    NSLog(@"%@",self.moreFunctionsButton);
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
//    switch (actionView.type) {
//        case ActionViewBatchEditingView:{
//            [self batchEditingButtonTapped:buttonTag];
//            break;
//        }
//        case ActionViewMoreFunctionsView:{
            [self moreFunctionButtonTapped:buttonTag];
//            break;
//        }
//    }
}


//-(void)batchEditingButtonTapped:(NSInteger)buttonTag{
//
//    [self.tableView setEditing:YES animated:YES];
//    self.navigationItem.leftBarButtonItem.title=@"取消";
//    self.navigationItem.leftBarButtonItem.action=@selector(cancelEdit:);
//
//    switch (buttonTag) {
//        case ActionViewButtonEditDelete:{
//            self.selectionMode=TVSelectionModeDelete;
//            break;
//        }
//        case ActionViewButtonEditMove:{
//            self.selectionMode=TVSelectionModeMove;
//            break;
//        }
//    }
//}

//-(void)cancelEdit:(UIBarButtonItem *)barbutton{
//    barbutton.title=@"编辑";
//    barbutton.action=@selector(prepareToBatchEditContacts:);
//    [self.tableView setEditing:NO animated:YES];
//}

//-(void)moveSelectedContacts:(UIBarButtonItem *)barbutton{
//    NSLog(@"移动");
//}

-(void)moreFunctionButtonTapped:(NSInteger)buttonTag{
    self.navigationItem.leftBarButtonItem.enabled=NO;
    switch (buttonTag) {
        case ActionViewButtonMoreFunctionSMS:{
            NSLog(@"SMS");
            // 筛掉没有电话的联系人
            self.contacts=(NSMutableArray *)[self.contactManager filterContactsWithoutPhoneNumbers:self.contacts];
            // 更改cell 内容，仅显示姓名，公司，及电话，同时隐藏导航栏(更改cell高度)
            self.selectionMode=TVSelectionModeBatchSMS;
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            // 提醒用户，选择电话号码???

            [self.tableView setEditing:YES animated:NO];
            [self configureSMSReceiversView];


            break;
        }
        case ActionViewButtonMoreFunctionEmail:{
            NSLog(@"email");

            // 筛掉没有邮件的联系人
            self.contacts=(NSMutableArray *)[self.contactManager filterContactsWithoutemail:self.contacts];
            // 更改cell 内容，仅显示姓名，公司，及邮件，同时隐藏导航栏(更改cell高度)
            self.selectionMode=TVSelectionModeBatchEmail;
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            // 提醒用户，选择邮件 ???

            [self.tableView setEditing:YES animated:NO];
            [self configureEmailReceiversView];

            break;
        }
        case ActionViewButtonMoreFunctionManuallyAdd:{
            break;
        }

        case ActionViewButtonMoreFunctionScanQR:{

            break;
        }
        case ActionViewButtonMoreFunctionExchangeCard:{

            break;
        }
        case ActionViewButtonMoreFunctionShareContacts:{
            self.selectionMode=TVSelectionModeBatchShare;
            [self.tableView setEditing:YES animated:NO];
            break;
        }

    }

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
        self.selectionMode=TVSelectionModeNone;
        self.currentTag=self.currentTag;
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
        self.selectionMode=TVSelectionModeNone;
        self.currentTag=self.currentTag;
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
#pragma mark - ContactsManagerDelegate
-(void)selectionChanged{

//    if (self.tableView.indexPathsForSelectedRows.count){
//        switch (self.selectionMode) {
//            case TVSelectionModeDelete:{
//                self.navigationItem.leftBarButtonItem.title=@"删除";
//                self.navigationItem.leftBarButtonItem.action=@selector(deleteSelectedContacts:);
//                break;
//            }
//            case TVSelectionModeMove:{
//                self.navigationItem.leftBarButtonItem.title=@"移动到";
//                self.navigationItem.leftBarButtonItem.action=@selector(moveSelectedContacts:);
//                break;
//            }
////            case TVSelectionModeBatchSMS:{
////                self.navigationItem.leftBarButtonItem.title=@"取消";
////                self.navigationItem.leftBarButtonItem.action=@selector(cancelEdit:);
////                break;
////            }
////            case TVSelectionModeBatchEmail:{
////                break;
////            }
////            case TVSelectionModeBatchShare:{
////                break;
////            }
//            default:{
//
//                break;
//            }
//        }
//    }else{
//        self.navigationItem.leftBarButtonItem.title=@"取消";
//        self.navigationItem.leftBarButtonItem.action=@selector(cancelEdit:);
//    }
//
}

#pragma  mark - UISearchResultsUpdatingDelegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    NSLog(@"updating");
}
#pragma mark - UISearchBarDelegate
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self showSearchAssistantView];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{

    // dismiss searchAssistantView
    [self dismissDimmingView:nil];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{

    [self.searchAssistant removeFromSuperview];
    [UIView animateWithDuration:0.5 animations:^{
        self.tableView.tableHeaderView.alpha=0.1;
    }completion:^(BOOL finished) {
        [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    }];

}

-(void)showSearchAssistantView{
    if (self.searchAssistant) {
        return;
    }
    dispatch_queue_t searchAssistantCreationQueue = dispatch_queue_create("SearchAssistantView", NULL);

    dispatch_async(searchAssistantCreationQueue, ^{
        // create search Assistant view
        SearchAssistantView *searchAssistantView=[[[NSBundle mainBundle]loadNibNamed:@"SearchAssistantView"
                                                                               owner:nil
                                                                             options:nil]lastObject];
        searchAssistantView.keyWordSelectedHandler=^(NSDictionary *keyWord){
            
        };

        dispatch_async(dispatch_get_main_queue(), ^{
            // update UI in main queue

            [self.view addSubview:searchAssistantView];
            self.searchAssistant=searchAssistantView;

            // calcute geometry info
            CGRect frame=CGRectMake(0, 0, CGRectGetWidth(self.searchController.searchBar.bounds), 120);
            searchAssistantView.frame=CGRectMake(0, -120,CGRectGetWidth(frame), 120);
            [searchAssistantView layoutIfNeeded];

            // display with animation
            [UIView animateWithDuration:3
                                  delay:0
                 usingSpringWithDamping:0.7
                  initialSpringVelocity:0.5
                                options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 searchAssistantView.frame=frame;
                                 self.customDimmingView.alpha=0.7;
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
-(void)setContacts:(NSMutableArray *)contacts{
    _contacts=contacts;
    [self.tableView reloadData];
}
-(void)setCurrentTag:(Tag *)currentTag{
    _currentTag=currentTag;
    NSArray *array;
    if ([currentTag isRootTag]) {
        array = [Contact allContacts];
    }else{
        array = [currentTag allOwnedContacts];
    }
    NSPredicate *predicate=[NSPredicate predicateWithFormat:@"contactIsDeleted == %@",@(NO)];
    NSLog(@"count:%@",@(array.count));
    self.contacts=[[array filteredArrayUsingPredicate:predicate] mutableCopy];
    NSLog(@"count:%@",@(self.contacts.count));

}

#pragma  mark - tableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.contacts.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    ContactCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Contact Cell"];
    if (!cell) {
        cell=[[ContactCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Contact Cell"];
    }

    cell.contact=self.contacts[indexPath.row];

    switch (self.selectionMode) {
        case TVSelectionModeBatchSMS:{
            cell.mode=ContactCellModeSMS;
            break;
        }
        case TVSelectionModeBatchEmail:{
            cell.mode=ContactCellModeEmail;
            break;
        }
        default:
            cell.mode=ContactCellModeNormal;
    }
    return cell;

}
// height
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPat
{
    return self.selectionMode == TVSelectionModeBatchSMS || self.selectionMode == TVSelectionModeBatchEmail ? 60 : 120;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
#pragma mark - tableviewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    if (tableView.isEditing) {
        Contact *contact=self.contacts[indexPath.row];
        switch (self.selectionMode) {
            case TVSelectionModeBatchSMS:{
                [self.smsReceiversView addContactAtIndex:indexPath.row
                                                withName:contact.contactName
                                         andPhoneNumbers:[self.contactManager phoneNumbersOfContact:contact]];
                break;
            }
            case TVSelectionModeBatchEmail:{

                [self.eMailReceiversView addContactAtIndex:indexPath.row
                                                withName:contact.contactName
                                               andEmails:[self.contactManager emailsOfContact:contact]];

                break;
            }
            default:{
                break;
            }
        }
    }
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
    return @[self.deleteAction,self.shareAction,self.moreAction];
}



-(void)deleteSelectedContacts{
    NSArray *indexpaths=[self.tableView indexPathsForSelectedRows];
    NSLog(@"tv:%@,indexpaths:%@",self.tableView, indexpaths);
    for (NSIndexPath *indexPath in indexpaths) {
        Contact *contact=self.contacts[indexPath.row];
        contact.contactIsDeleted=@(YES);
        [self.contacts removeObjectAtIndex:indexPath.row];
    }

    [self.tableView reloadData];

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
        _moreAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"更多" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
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

@end
