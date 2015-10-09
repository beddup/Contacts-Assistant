//
//  ViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/13/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//
#import "defines.h"
#import "AppDelegate.h"
#import "ContactsViewController.h"
#import "SearchAssistantView.h"
#import "ContactsManager.h"
#import "TagNavigationView.h"
#import "MoreFunctionsView.h"
#import "Tag+Utility.h"
#import "Contact+Utility.h"
#import "ContactCell.h"
#import "SMSReceiversView.h"
#import "EmailReceiversView.h"
#import "ContactDetailsViewController.h"
#import "NavigationTitleView.h"

#import "QRCodeReaderViewController.h"
#import "QRCodeReader.h"
#import "QRCodeReaderDelegate.h"
#import "QRScanResultViewController.h"
#import "CreatePersonViewController.h"

#import "NSMutableArray+ArrangedContacts.h"
#import "MBProgressHUD+ContactsAssistant.h"
#import "NSString+ContactsAssistant.h"
#import "ManageTagsTableViewController.h"
#import <MessageUI/MessageUI.h>

CGFloat const SearchAssistantViewHeight=150.0;

typedef enum : NSUInteger {
    TVSelectionModeNormal=0,
    TVSelectionModeBatchSMS,
    TVSelectionModeBatchEmail,
} TVSelectionMode;

@interface ContactsViewController ()
<UISearchResultsUpdating,UISearchControllerDelegate,UISearchBarDelegate,MoreFunctionViewDelegate,LoadContactsDelegate,UITableViewDataSource,UITableViewDelegate,QRCodeReaderDelegate>

//table view
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(strong,nonatomic) ContactsManager * contactManager;
//data
@property(strong,nonatomic)NSMutableArray *arrangedContactsUnderCurrentTag;
@property(strong,nonatomic) NSMutableArray *contacts;
@property(strong,nonatomic)NSMutableArray *indexTitles;
@property(strong,nonatomic) Tag *currentTag;

@property(nonatomic) TVSelectionMode selectionMode;

//search
@property(strong,nonatomic)UISearchController *searchController;
@property(weak,nonatomic)SearchAssistantView *searchAssistant;

@property(weak,nonatomic)UIView *customDimmingView;

@property(strong,nonatomic)NavigationTitleView *navigationTitleView;
@property(weak,nonatomic)TagNavigationView *tagNavigationView;

@property (weak, nonatomic) UIButton *moreFunctionsButton;
@property(weak,nonatomic)UIView *moreFunctionsView;

@property(weak,nonatomic)ReceiversView *receiverView;

//row action
@property(strong,nonatomic)UITableViewRowAction *deleteAction;
@property(strong,nonatomic)UITableViewRowAction *topAction;
@property(strong,nonatomic)UITableViewRowAction *shareAction;
@end

@implementation ContactsViewController

#pragma mark - vc life cycle
- (void)viewDidLoad {

    [super viewDidLoad];
    self.tableView.sectionIndexBackgroundColor=[UIColor clearColor];
    [self configureTableFooterView];
    [self configureMoreFunctionButton];
    [self configureNavigationBar];
    [self disableControls];
    [self.contactManager loadContacts]; //asy
}

-(void)enableControls{

    self.navigationItem.rightBarButtonItem.enabled=YES;
    self.navigationTitleView.enabled=YES;
    self.moreFunctionsButton.enabled=YES;
}
- (void)didReceiveMemoryWarning {

    [super didReceiveMemoryWarning];
    self.searchController=nil;
    self.deleteAction=nil;
    self.topAction=nil;
    self.shareAction=nil;
}

-(void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    if (self.selectionMode == TVSelectionModeNormal) {
        //ContactDetailsViewController.h may change contact detail
        NSIndexPath *indexPath=[self.tableView indexPathForSelectedRow];
        if (indexPath) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            // the height may changed , so reload 
            [self.tableView reloadData];
        }
    }
}

-(void)viewDidLayoutSubviews{

    self.moreFunctionsButton.frame=CGRectMake(CGRectGetWidth(self.view.bounds)/2-70/2, CGRectGetHeight(self.view.bounds)-44-12, 70, 44);
}


#pragma mark - properties
-(ContactsManager *)contactManager{

    if (!_contactManager) {
        _contactManager=[ContactsManager sharedContactManager];
        _contactManager.delegate=self;
    }
    return _contactManager;
}
-(UISearchController *)searchController{
    if (!_searchController) {
        //configure Search Controller
        UISearchController *searchController=[[UISearchController alloc]initWithSearchResultsController:nil];
        searchController.searchResultsUpdater=self;
        searchController.delegate=self;
        searchController.dimsBackgroundDuringPresentation=NO;
        searchController.hidesNavigationBarDuringPresentation=NO;

        //configure searchBar
        UISearchBar *searchBar=searchController.searchBar;
        searchBar.placeholder=@"联系人信息或者标签";
        searchBar.delegate=self;
        searchBar.showsCancelButton=YES;
        _searchController=searchController;

    }
    return _searchController;
}

//table view related
-(void)setSelectionMode:(TVSelectionMode)selectionMode{

    _selectionMode=selectionMode;
    switch (selectionMode) {
        case TVSelectionModeBatchSMS:{
            self.contacts=[self.contacts contactsWhichHasPhones];
            break;
        }
        case TVSelectionModeBatchEmail:{
            self.contacts=[self.contacts contactsWhichHasEmail];
            break;
        }
        default:{
            self.contacts=self.arrangedContactsUnderCurrentTag;
            self.navigationTitleView.title=self.currentTag.tagName;
            break;
        }
    }
    [self.tableView reloadData];
}

-(void)setCurrentTag:(Tag *)currentTag{

    _currentTag=currentTag;
    self.arrangedContactsUnderCurrentTag =[[self.contactManager arrangedContactsunderTag:currentTag]mutableCopy];
    if (self.selectionMode==TVSelectionModeBatchSMS) {
        self.arrangedContactsUnderCurrentTag=[self.arrangedContactsUnderCurrentTag contactsWhichHasPhones];
    }else if (self.selectionMode==TVSelectionModeBatchEmail){
        self.arrangedContactsUnderCurrentTag=[self.arrangedContactsUnderCurrentTag contactsWhichHasEmail];
    }
}

-(void)setArrangedContactsUnderCurrentTag:(NSMutableArray *)arrangedContactsUnderCurrentTag{
    _arrangedContactsUnderCurrentTag=arrangedContactsUnderCurrentTag;
    self.contacts=self.arrangedContactsUnderCurrentTag;
}
-(void)setContacts:(NSMutableArray *)contacts{

    _contacts=contacts;
    self.indexTitles=[[self.contactManager indexTitleOfContacts:contacts] mutableCopy];
    [self configureTableHeaderView];
    [self.tableView reloadData];
}

#pragma mark - Contacts Manager Delegate
-(void)loadingContact:(NSInteger)index total:(NSInteger)total{

    MBProgressHUD *hud=[MBProgressHUD HUDForView:self.navigationController.view];
    if (!hud) {
        hud=[MBProgressHUD loadingContactHudMode:MBProgressHUDModeDeterminateHorizontalBar view:self.navigationController.view];
        [hud show:YES];
    }
    if (index%2) {
        // reduce some drawing time
        hud.progress=index *1.0/total;
    }
}

-(void)didFinishLoadContacts{
    if (!self.contactManager.addressBookAuthorized) {
        [self configureTableHeaderView];
    }
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [self enableControls];
    self.currentTag=[Tag rootTag];
}
-(void)disableControls{
    self.navigationItem.rightBarButtonItem.enabled=NO;
    self.navigationTitleView.enabled=NO;
    self.moreFunctionsButton.enabled=NO;

}

-(void)didCreateNewPerson{

    self.arrangedContactsUnderCurrentTag=[[self.contactManager arrangedContactsunderTag:self.currentTag] mutableCopy];

    NSArray *searchKeyWords=[self keyWordsInSearchBar:self.searchController.searchBar];

    if (searchKeyWords.count) {
        NSDictionary *results=[self.contactManager searchContacts:self.arrangedContactsUnderCurrentTag keywords:searchKeyWords];
        self.contacts=results[SearchResultContactsKey];
    }
}

#pragma mark - Configure Table Header Footer

-(void)configureTableFooterView{
    UIView *footerView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 200)];
    [self.tableView setTableFooterView:footerView];
}
-(void)configureTableHeaderView{
    if (!self.indexTitles.count) {
        UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 300)];
        label.textAlignment=NSTextAlignmentCenter;
        label.textColor=[UIColor lightGrayColor];
        label.font=[UIFont systemFontOfSize:20 weight:UIFontWeightLight];
        self.tableView.tableHeaderView=label;
        [self.tableView setContentOffset:CGPointZero];
        if (!self.contactManager.addressBookAuthorized) {
            label.text=@"请允许APP访问通讯录";
            return;
        }
        switch (self.selectionMode) {
            case TVSelectionModeBatchEmail:{
                label.text=@"无邮箱地址";
                break;
            }
            case TVSelectionModeBatchSMS:{
                label.text=@"无电话号码";
                break;
            }
            case TVSelectionModeNormal:{
                label.text=@"无联系人";
                break;
            }
        }
    }else{
        self.tableView.tableHeaderView=nil;
    }

}
#pragma  mark - navigation bar items and control,actions
-(void)configureNavigationBar{
    self.navigationItem.rightBarButtonItem=[self searchBarButton];
    self.navigationItem.leftBarButtonItem=[self placeHolderBarButtonItem];

    NavigationTitleView *titleView=[[[NSBundle mainBundle]loadNibNamed:@"NavigationTitleView" owner:nil options:nil]lastObject];
    titleView.title=@"所有联系人";
    titleView.navigationTitlePressed=^{
        [self prepareSwitchTag];
    };
    self.navigationItem.titleView=titleView;
    self.navigationTitleView=titleView;
}
-(void)enableSearchAndTagSwitch{
    self.navigationItem.rightBarButtonItem.enabled=YES;
    self.navigationTitleView.enabled=YES;
}
-(void)disableSearchAndTagSwitch{
    self.navigationItem.rightBarButtonItem.enabled=NO;
    ((NavigationTitleView*)self.navigationItem.titleView).enabled=NO;
}
// UIBarButtonItems
-(UIBarButtonItem *)placeHolderBarButtonItem{
    UIBarButtonItem *barbutton=[[UIBarButtonItem alloc]initWithCustomView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 44)]];
    return barbutton;
}

-(UIBarButtonItem *)searchBarButton{
    UIBarButtonItem *searchBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(prepareSearch:)];
    return searchBarButtonItem;
}
-(UIBarButtonItem *)selectAllBarButtonItem{
    UIBarButtonItem *selectAll=[[UIBarButtonItem alloc]initWithTitle:@"全选" style:UIBarButtonItemStylePlain target:self action:@selector(selectAllContact:)];
    return selectAll;
}
-(UIBarButtonItem *)deselectAllBarButtonItem{
    UIBarButtonItem *deselectAll=[[UIBarButtonItem alloc]initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(deSelectionAllContact:)];
    return deselectAll;
}
//actions
-(void)selectAllContact:(UIBarButtonItem*)barbutton{

    [self disableSearchAndTagSwitch];
    self.navigationItem.leftBarButtonItem=[self deselectAllBarButtonItem];
    //select all
    MBProgressHUD *hud=[[MBProgressHUD alloc]initWithView:self.navigationController.view];
    hud.removeFromSuperViewOnHide=YES;
    [self.navigationController.view addSubview:hud];
    [hud showAnimated:YES whileExecutingBlock:^{
        for (int section = 0; section< self.contacts.count; section++) {
            for (int row = 0; row <[self.contacts[section] count]; row++) {
                Contact *contact= self.contacts[section][row];
                NSArray *contactInfos=nil;
                if ([self.receiverView isKindOfClass:[SMSReceiversView class]]) {
                    contactInfos=[self.contactManager phoneNumbersOfContact:contact];
                }else{
                    contactInfos=[self.contactManager emailsOfContact:contact];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:row inSection:section];
                    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                    [self.receiverView addContactInfosToReceivers:contactInfos contact:contact];
                });
            }
        }
    }];

}
-(void)deSelectionAllContact:(UIBarButtonItem *)barbutton{
    [self enableSearchAndTagSwitch];
    self.navigationItem.leftBarButtonItem=[self selectAllBarButtonItem];

    [self.tableView reloadData];
    [self.receiverView removeAllContactInfos];
}

#pragma mark - Tag Navigation
-(void)prepareSwitchTag{
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
        NavigationTitleView *titleView=(NavigationTitleView *)self.navigationItem.titleView;
        titleView.title=tag.tagName;
        [self dismissDimmingView:nil];
    };
    tagNavigationView.manageTags=^{
        [self performSegueWithIdentifier:@"Manage Tags" sender:nil];
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
        tagNavigationView.frame=CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame), CGRectGetWidth(self.view.bounds), 200);
    } completion:nil];

}
#pragma mark - dim and disdim
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

    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut animations:^{

        self.customDimmingView.alpha=0.0;

        self.moreFunctionsView.frame=self.moreFunctionsButton.frame;
        self.moreFunctionsView.alpha=0.0;

        self.tagNavigationView.frame=CGRectMake(0, -150-70, CGRectGetWidth(self.view.bounds), 150);
        self.searchAssistant.frame=CGRectMake(0, -120-70, CGRectGetWidth(self.view.bounds), 120);

    } completion:^(BOOL finished) {
        [self.customDimmingView removeFromSuperview];
        [self.moreFunctionsView removeFromSuperview];
        [self.tagNavigationView removeFromSuperview];
    }];

    self.navigationItem.rightBarButtonItem.enabled=YES;
    self.navigationItem.leftBarButtonItem.enabled=YES;
    ((NavigationTitleView *)self.navigationItem.titleView).enabled=YES;
}

#pragma mark - MoreFunctionsView
-(void)configureMoreFunctionButton{

    UIButton *moreFunctionButton=[[UIButton alloc]init];
    [self.view addSubview:moreFunctionButton];
    [self.view bringSubviewToFront:moreFunctionButton];
    [moreFunctionButton addTarget:self action:@selector(displayMoreFunctionsView:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *image=[[UIImage imageNamed:@"MoreFunctionButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4) resizingMode:UIImageResizingModeStretch];
    [moreFunctionButton setBackgroundImage:image forState:UIControlStateNormal];
    self.moreFunctionsButton=moreFunctionButton;
}

- (void)displayMoreFunctionsView:(UIButton *)sender {
    // dim bkg
    [self dim];

    self.navigationItem.rightBarButtonItem.enabled=NO;
    self.navigationItem.leftBarButtonItem.enabled=NO;
    UIView *titleView=self.navigationItem.titleView;
    if ([titleView isKindOfClass:[NavigationTitleView class]]) {
        ((NavigationTitleView *)titleView).enabled=NO;
    }

    [self.view bringSubviewToFront:self.moreFunctionsButton];
    // prepare action view
    MoreFunctionsView *moreFunctionsView=[[[NSBundle mainBundle]loadNibNamed:@"MoreFuctionsView" owner:nil options:nil] lastObject];
    self.moreFunctionsView=moreFunctionsView;
    self.moreFunctionsView.alpha=0.2;
    [self.view addSubview:moreFunctionsView];
    moreFunctionsView.delegate=self;

    //calculate geometry
    moreFunctionsView.frame=self.moreFunctionsButton.frame;
    [moreFunctionsView layoutIfNeeded];
    CGRect frame=CGRectMake(4, CGRectGetHeight(self.view.bounds)-120-8, CGRectGetWidth(self.view.bounds)-8,120);

    // display with animation
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
        self.customDimmingView.alpha=0.7;
        moreFunctionsView.alpha=1.0;
        moreFunctionsView.frame=CGRectInset(frame, 4, 4);
    } completion:nil];

}
//MoreFunctionsView delegate
-(void)groupSMS{
    if (![MFMessageComposeViewController canSendText]) {
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil message:@"无法发送短信" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil]];
        [self  presentViewController:alertController animated:YES completion:nil];
        return;
    }

    self.selectionMode=TVSelectionModeBatchSMS;
    [self.tableView setEditing:YES animated:NO];
    SMSReceiversView *receiversView=[[[NSBundle mainBundle]loadNibNamed:@"SMSReceiversView" owner:nil options:nil] lastObject];
    self.receiverView=receiversView;
    [self showReceiversView:receiversView];
}
-(void)groupEmail{
    if (![MFMailComposeViewController canSendMail]) {
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil message:@"无法发送邮件，请检查邮箱设置" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil]];
        [self  presentViewController:alertController animated:YES completion:nil];
        return;
    }
    self.selectionMode=TVSelectionModeBatchEmail;
    [self.tableView setEditing:YES animated:NO];
    EmailReceiversView *receiversView=[[[NSBundle mainBundle]loadNibNamed:@"EmailReceversView" owner:nil options:nil] lastObject];
    self.receiverView=receiversView;
    [self showReceiversView:receiversView];
}

-(void)scanContactQR{
    [self dismissSearchController];
    [self prepareScanQR];
}
-(void)addContactManually{
    UINavigationController *createPersonNavVC=[self.storyboard instantiateViewControllerWithIdentifier:@"create person nav vc"];
    [self dismissSearchController];
    [self presentViewController:createPersonNavVC animated:YES completion:nil];

}
#pragma mark - group sms and email
-(void)showReceiversView:(ReceiversView *)receiversView{

    [self dismissDimmingView:nil];
    [self.view addSubview:receiversView];
    CGRect frame=CGRectInset(CGRectMake(0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds), 150),2,0);
    receiversView.frame=frame;
    [receiversView layoutIfNeeded];
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5
                        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         receiversView.frame=CGRectOffset(frame, 0, -150);
                         self.navigationItem.leftBarButtonItem=[self selectAllBarButtonItem];
                     }
                     completion:nil];

    __weak ReceiversView * weakReceiverView=receiversView;
    receiversView.cancelHandler=^{
        [self.tableView setEditing:NO animated:YES];
        self.selectionMode=TVSelectionModeNormal;
        [self enableSearchAndTagSwitch];
        [self dismissSearchController];

        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5
                            options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             weakReceiverView.frame =  CGRectInset(frame, CGRectGetWidth(self.view.bounds)/4, 10);
                             self.tableView.frame=self.view.bounds;
                         }
                         completion:^(BOOL finished) {
                             [weakReceiverView removeFromSuperview];
                         }];
    };
}

#pragma mark - QRCodeReader
-(void)prepareScanQR{

    if ([QRCodeReader supportsMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]) {

        static QRCodeReaderViewController *reader = nil;
        static dispatch_once_t onceToken;

        dispatch_once(&onceToken, ^{
            reader                        = [QRCodeReaderViewController new];
            reader.modalPresentationStyle = UIModalPresentationFormSheet;
        });
        reader.delegate = self;

        [self presentViewController:reader animated:YES completion:NULL];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Reader not supported by the current device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];

        [alert show];
    }
}

//QRCodeReader delegate
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
        
    if (![[[Contact infoFromQRString:result] allKeys] count]) {
        MBProgressHUD *hud=[MBProgressHUD textHud:@"无法识别联系人" view:reader.view];
        [hud show:YES];
        [hud hide:YES afterDelay:1.0];
        return;
    }

    [self dismissViewControllerAnimated:NO completion:nil];
    UINavigationController *nav=[self.storyboard instantiateViewControllerWithIdentifier:@"scanresultvc"];
    QRScanResultViewController *scanresultvc=(QRScanResultViewController *)nav.viewControllers[0];
    scanresultvc.personInfo=[Contact infoFromQRString:result];
    [self presentViewController:nav animated:YES completion:nil];

}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma  mark - Search
-(void)prepareSearch:(UIBarButtonItem *)barButton{

    self.navigationItem.rightBarButtonItem=nil;
    self.navigationItem.leftBarButtonItem=nil;
    self.navigationItem.titleView=self.searchController.searchBar;
    [self presentViewController:self.searchController animated:YES completion:^{
        [self.searchController.searchBar becomeFirstResponder];
    }];

}
-(void)dismissSearchController{

    [self dismissSearchAssistantView];

    NSString *searchText=self.searchController.searchBar.text;
    self.navigationTitleView.title=[searchText whiteSpaceTrimmedLength] ? [NSString stringWithFormat:@"搜索：%@",searchText] :self.currentTag.tagName ;
    self.navigationItem.titleView=self.navigationTitleView;
    self.navigationItem.rightBarButtonItem=[self searchBarButton];
    if (self.selectionMode == TVSelectionModeBatchEmail || self.selectionMode == TVSelectionModeBatchSMS) {
        self.navigationItem.leftBarButtonItem=[self selectAllBarButtonItem];
    }else{
        self.navigationItem.leftBarButtonItem=[self placeHolderBarButtonItem];
    }

    [self.searchController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
}
-(NSArray *)keyWordsInSearchBar:(UISearchBar *)searchBar{

    NSMutableArray *keywords=[@[] mutableCopy];
    for (NSString *subString in [searchBar.text componentsSeparatedByString:@" "]) {

        NSString *string=[subString whiteSpaceAtEndsTrimmedString];
        if (string.length) {
            [keywords addObject:string];
        }
    }
    return keywords;
    
}
//UISearchController delegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController{

    NSArray *keywords=[self keyWordsInSearchBar:self.searchController.searchBar];
    if (!keywords.count) {
        self.contacts=self.arrangedContactsUnderCurrentTag;
        [self.searchAssistant removeFromSuperview];
        return;
    }

    NSDictionary *results=[self.contactManager searchContacts:self.contacts keywords:keywords];
    if (![results[AdvicedTagsKey] count]) {
        self.contacts=[results[SearchResultContactsKey] mutableCopy];
    }else{
        [self showSearchAssistantView:@{AdvicedTagsKey:results[AdvicedTagsKey],
                                        AdvicedContactsKey:results[AdvicedContactsKey]}];
    }

}
// search bar delegate
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self dismissSearchAssistantView];
    NSArray *keywords=[self keyWordsInSearchBar:self.searchController.searchBar];
    NSDictionary *results=[self.contactManager searchContacts:self.contacts keywords:keywords];
    self.contacts=results[SearchResultContactsKey];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self dismissSearchController];
}

// show and dismiss Search Assistant View
-(void)showSearchAssistantView:(NSDictionary *)searchAdvice{
    if (self.searchAssistant) {
        self.searchAssistant.searchAdvice=searchAdvice;
        return;
    }
    // create search Assistant view
    SearchAssistantView *searchAssistantView=[[[NSBundle mainBundle]loadNibNamed:@"SearchAssistantView" owner:nil options:nil]lastObject];
    [self.view addSubview:searchAssistantView];
    self.searchAssistant=searchAssistantView;
    searchAssistantView.searchAdvice=searchAdvice;

    searchAssistantView.advicedContactSelectedHandler=^(Contact *contact){
        self.contacts=[@[@[contact]] mutableCopy];
        [self dismissSearchController];
    };

    searchAssistantView.advicedTagSelectedHandler=^(Tag *tag){
        [self dismissSearchController];
        self.currentTag=tag;
        self.navigationTitleView.title=tag.tagName;
    };
    CGFloat height=CGRectGetHeight(self.tableView.bounds)-250;
    CGRect frame=CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame), CGRectGetWidth(self.tableView.bounds), height);
    searchAssistantView.frame=CGRectMake(0, -height,CGRectGetWidth(frame), height);
    [searchAssistantView layoutIfNeeded];

    // show with animation
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                     animations:^{searchAssistantView.frame=frame;}
                     completion:nil];
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

#pragma  mark - tableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.contacts.count;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.contacts[section] count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier=@"Contact Cell";
    ContactCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell=[[ContactCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.contact=self.contacts[indexPath.section][indexPath.row];
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath

{
    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    if (self.selectionMode == TVSelectionModeBatchSMS)
    {
        return  48 + [self.contactManager phoneCountOfContact:contact] * 16;

    }else if (self.selectionMode == TVSelectionModeBatchEmail) {

        return  48 + [self.contactManager emailCountOfContact:contact] * 16;

    }else{
        return [contact hasUnfinishedOwnedEvents] ? 112 :92;
    }
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

#pragma mark - tableviewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    if (self.selectionMode == TVSelectionModeNormal) {
        [self performSegueWithIdentifier:@"contactDetail" sender:contact];
        return;
    }
    NSArray *contactInfos=self.selectionMode == TVSelectionModeBatchSMS ? [self.contactManager phoneNumbersOfContact:contact] : [self.contactManager emailsOfContact:contact];

    if (contactInfos.count <= 1) {
        // directly add to receiversView
        [self.receiverView addContactInfosToReceivers:contactInfos contact:contact];
        [self disableSearchAndTagSwitch];
    }else{
        NSString *title=self.selectionMode == TVSelectionModeBatchSMS ? @"选择电话号码":@"选择邮箱地址";
        UIAlertController *alertController=[self alertControllerForAddingContactInfosToRecevierView:contactInfos
                                                                              ofContact:contact
                                                                                  title:title
                                                                          cancelHandler:^{
                                [tableView deselectRowAtIndexPath:indexPath animated:YES];}];
        [self dismissSearchController];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.selectionMode == TVSelectionModeNormal) {
        return;
    }
    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    self.selectionMode == TVSelectionModeBatchSMS ? [self.receiverView removeContactInfosOfContact:contact]:[self.receiverView removeContactInfosOfContact:contact];
    if (!self.receiverView.hasContactInfo) {
        [self enableSearchAndTagSwitch];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //To enable the swipe-to-delete feature of table views (wherein a user swipes horizontally across a row to display a Delete button), you must implement this method
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @[self.deleteAction,self.shareAction,self.topAction];
}

#pragma mark - alertController

-(UIAlertController *)alertControllerForAddingContactInfosToRecevierView:(NSArray *)contactInfos
                                                               ofContact:(Contact *)contact
                                                                   title:(NSString *)title
                                                           cancelHandler:(void(^)()) handler{
    // configure alertController
    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSDictionary *contactInfo in contactInfos) {
        NSString *actionTitle=contactInfo[ContactInfoValueKey];
        UIAlertAction *action=[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self disableSearchAndTagSwitch];
            [self.receiverView addContactInfosToReceivers:@[contactInfo] contact:contact];
        }];
        [alertController addAction:action];
    }

    BOOL isPhone= [[contactInfos firstObject][ContactInfoTypeKey] integerValue]==ContactInfoTypePhone;
    UIAlertAction *selectAllAction=[UIAlertAction actionWithTitle:isPhone ? @"所有号码" : @"所有邮箱"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self disableSearchAndTagSwitch];
                                                              [self.receiverView addContactInfosToReceivers:contactInfos contact:contact];
                                                          }];
    [alertController addAction:selectAllAction];

    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        handler();
    }];
    [alertController addAction:cancelAction];

    return alertController;
    
}

#pragma  mark - UITableViewRowAction
-(UITableViewRowAction *)deleteAction{
    if (!_deleteAction) {
        _deleteAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            Contact *contact= self.contacts[indexPath.section][indexPath.row];
            UIAlertController *deleteAlert=[UIAlertController alertControllerWithTitle:nil message: [@"删除联系人:" stringByAppendingString:contact.contactName] preferredStyle:UIAlertControllerStyleActionSheet];

            UIAlertAction *deleteCompletelyAction=[UIAlertAction actionWithTitle:@"同时删除通讯录中的联系人" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self.contactManager removePerson:contact];
                [self.contacts removeContactAtIndexPath:indexPath];
                self.indexTitles=[[self.contactManager indexTitleOfContacts:self.contacts] mutableCopy];
                [self.tableView reloadData];}];

            UIAlertAction *deleteTemlyAction=[UIAlertAction actionWithTitle:@"保留通讯录中的联系人" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
               [self.contacts removeContactAtIndexPath:indexPath];
               self.indexTitles=[[self.contactManager indexTitleOfContacts:self.contacts] mutableCopy];
               [self.tableView reloadData];}];

            UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [deleteAlert addAction:deleteCompletelyAction];
            [deleteAlert addAction:deleteTemlyAction];
            [deleteAlert addAction:cancelAction];

            [self dismissSearchController];
            [self presentViewController:deleteAlert animated:YES completion:nil];

        }];
    }

    return _deleteAction;
}
-(UITableViewRowAction *)shareAction{
    if (!_shareAction) {
        _shareAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"共享" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            Contact *contact= self.contacts[indexPath.section][indexPath.row];
            NSString *sharedInfo=[NSString stringWithFormat:@"姓名:%@; %@; %@",contact.contactName,[contact phoneInfoString],[contact emailInfoString]];
            UIActivityViewController *activityVC=[[UIActivityViewController alloc]initWithActivityItems:@[sharedInfo] applicationActivities:nil];
            activityVC.excludedActivityTypes=@[UIActivityTypePostToFacebook,UIActivityTypePostToTwitter,UIActivityTypePostToWeibo,UIActivityTypePostToTencentWeibo,UIActivityTypePrint];

            [self dismissSearchController];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self presentViewController:activityVC animated:YES completion:nil];
        });


        }];
        _shareAction.backgroundColor=[UIColor orangeColor];

    }
    return _shareAction;
}

-(UITableViewRowAction *)topAction{
    if (!_topAction) {
        _topAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"置顶" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [self putToTop:indexPath];
        }];
        _topAction.backgroundColor=[UIColor lightGrayColor];
    }
    return _topAction;
}

-(void)putToTop:(NSIndexPath *)indexPath{


    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    contact.contactOrderWeight=@([NSDate timeIntervalSinceReferenceDate]);
    [self.contactManager arrangeContactToTop:contact indexTitle:self.indexTitles[indexPath.section]];

    //remove contact at indexPath
    [self.contacts[indexPath.section] removeObject:contact];
    if (![self.contacts[indexPath.section] count]) {
        [self.indexTitles removeObjectAtIndex:indexPath.section];
        [self.contacts removeObjectAtIndex:indexPath.section];
    }

    // insert contact to (0,0)
    if (![self.indexTitles[0] isEqualToString:@"☆"]) {
        [self.indexTitles insertObject:@"☆" atIndex:0];
        [self.contacts insertObject:[@[] mutableCopy] atIndex:0];
    }
    [self.contacts[0] insertObject:contact atIndex:0];


    [self.tableView reloadData];

}

#pragma  mark - segue navigation

-(IBAction)finishManagingTags:(UIStoryboardSegue *)segue{
    // finish managing tags , so need to update tags list in tag navigaiton view
    [self.tagNavigationView updateTags];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"contactDetail"]) {
        [self dismissSearchController];
        ContactDetailsViewController *dstvc=(ContactDetailsViewController *)segue.destinationViewController;
        NSIndexPath *indexPath=[self.tableView indexPathForSelectedRow];
        Contact *contact=self.contacts[indexPath.section][indexPath.row];
        dstvc.contact=contact;
        dstvc.indexPath=indexPath;
    }
}

@end
