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
#import "NavigationTitleView.h"

#import "QRCodeReaderViewController.h"
#import "QRCodeReader.h"
#import "QRCodeReaderDelegate.h"
#import "QRScanResultViewController.h"
#import "CreatePersonViewController.h"

#import "NSMutableArray+ArrangedContacts.h"
#import "MBProgressHUD.h"
#import <MessageUI/MessageUI.h>

CGFloat const SearchAssistantViewHeight=150.0;
CGFloat const OperationViewWidth = 200;
CGFloat const OperationViewHeight = 238;
typedef enum : NSUInteger {
    TVSelectionModeNormal=0,
    TVSelectionModeBatchSMS,
    TVSelectionModeBatchEmail,
} TVSelectionMode;

@interface VisualizedContactsViewController ()<UISearchResultsUpdating,UISearchControllerDelegate,UISearchBarDelegate,ActionsViewDelegate,ContactsManagerDelegate,UITableViewDataSource,UITableViewDelegate,QRCodeReaderDelegate,ContactCellDelegate,MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>

//table view
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(strong,nonatomic)UITableViewRowAction *deleteAction;
@property(strong,nonatomic)UITableViewRowAction *topAction;
@property(strong,nonatomic)UITableViewRowAction *shareAction;

//search
@property(strong,nonatomic)UISearchController *searchController;
@property(weak,nonatomic)SearchAssistantView *searchAssistant;
@property(strong,nonatomic)NSMutableArray *baseContactsForSearch;

@property(strong,nonatomic)NavigationTitleView *navigationTitleView;

// button button
@property (weak, nonatomic) UIButton *moreFunctionsButton;
@property(weak,nonatomic)ReceiversView *receiverView;

@property(weak,nonatomic)UIView *customDimmingView;
@property(weak,nonatomic)UIView *moreFunctionsView;
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
    [self configureNavigationBar];
    [self configureTableFooterView];
    self.tableView.sectionIndexBackgroundColor=[UIColor clearColor];

    [self.contactManager loadContacts]; //asy

}
-(void)enableControls{

    self.navigationItem.rightBarButtonItem.enabled=YES;
    UIView *titleView=self.navigationItem.titleView;
    if ([titleView isKindOfClass:[NavigationTitleView class]]) {
        ((NavigationTitleView *)titleView).enabled=YES;
    }
    self.moreFunctionsButton.enabled=YES;

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coreDataUpdatingFinished:) name:ContactManagerDidFinishUpdatingCoreData object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ContactManagerDidFinishUpdatingCoreData object:nil];
}
-(void)viewDidAppear:(BOOL)animated{
    self.tableView.frame=CGRectMake(0, 0, 320,500);
    [self.tableView setNeedsLayout];
}

-(void)viewDidLayoutSubviews{
    self.moreFunctionsButton.frame=CGRectMake(CGRectGetWidth(self.view.bounds)/2-70/2, CGRectGetHeight(self.view.bounds)-44-12, 70, 44);
}

-(void)coreDataUpdatingFinished:(NSNotification *)notification{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self enableControls];
        self.currentTag=[Tag rootTag];
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
    [self.view addSubview:moreFunctionButton];
    [self.view bringSubviewToFront:moreFunctionButton];
    [moreFunctionButton addTarget:self action:@selector(displayMoreActions:) forControlEvents:UIControlEventTouchUpInside];
    moreFunctionButton.enabled=NO;
    UIImage *image=[[UIImage imageNamed:@"MoreFunctionButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4) resizingMode:UIImageResizingModeStretch];
    [moreFunctionButton setBackgroundImage:image forState:UIControlStateNormal];
    self.moreFunctionsButton=moreFunctionButton;

}

-(void)configureNavigationBar{

    self.navigationItem.rightBarButtonItem=[self searchBarButton];
    self.navigationItem.rightBarButtonItem.enabled=NO;
    self.navigationItem.leftBarButtonItem=[self placeHolderBarButtonItem];

    NavigationTitleView *titleView=[[[NSBundle mainBundle]loadNibNamed:@"NavigationTitleView" owner:nil options:nil]lastObject];
    titleView.enabled=NO;
    titleView.title=@"所有联系人";
    titleView.navigationTitlePressed=^{
        [self prepareSwitchTag];
    };
    self.navigationItem.titleView=titleView;
    self.navigationTitleView=titleView;


}
-(UIBarButtonItem *)placeHolderBarButtonItem{
    UIBarButtonItem *barbutton=[[UIBarButtonItem alloc]initWithCustomView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 44)]];
    return barbutton;
}

-(UIBarButtonItem *)searchBarButton{
    UIBarButtonItem *searchBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(prepareSearch:)];
    return searchBarButtonItem;
}

#pragma mark - Actions
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
-(void)prepareSearch:(UIBarButtonItem *)barButton{

    self.baseContactsForSearch=self.contacts;

    self.navigationItem.titleView=self.searchController.searchBar;
    self.navigationItem.rightBarButtonItem=nil;
    self.navigationItem.leftBarButtonItem=nil;
    [self presentViewController:self.searchController animated:YES completion:^{
        [self.searchController.searchBar becomeFirstResponder];
    }];
}

-(void )prepareSearchController{

    //configure Search Controller
    UISearchController *searchController=[[UISearchController alloc]initWithSearchResultsController:nil];
    self.searchController=searchController;
    searchController.searchResultsUpdater=self;
    searchController.delegate=self;
    searchController.dimsBackgroundDuringPresentation=NO;
    searchController.hidesNavigationBarDuringPresentation=NO;

    //configure searchBar
    UISearchBar *searchBar=searchController.searchBar;
    searchBar.placeholder=@"联系人信息或者标签";
    searchBar.delegate=self;
    searchBar.showsCancelButton=YES;

}
-(void)dismissSearchController{

    [self dismissSearchAssistantView];

    NSString *searchText=self.searchController.searchBar.text;
    self.navigationTitleView.title=searchText.length ? [NSString stringWithFormat:@"搜索：%@",searchText] :self.currentTag.tagName ;
    self.navigationItem.titleView=self.navigationTitleView;
    self.navigationItem.rightBarButtonItem=[self searchBarButton];
    if (self.selectionMode == TVSelectionModeBatchEmail || self.selectionMode == TVSelectionModeBatchSMS) {
        self.navigationItem.leftBarButtonItem=[self selectAllBarButtonItem];
    }else{
        self.navigationItem.leftBarButtonItem=[self placeHolderBarButtonItem];
    }

    [self.searchController.presentingViewController dismissViewControllerAnimated:YES completion:nil];

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

- (void)displayMoreActions:(UIButton *)sender {
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
    ActionsView *moreActionsView=[[[NSBundle mainBundle]loadNibNamed:@"MoreFuctionsView" owner:nil options:nil] lastObject];
    self.moreFunctionsView=moreActionsView;
    self.moreFunctionsView.alpha=0.2;
    [self.view addSubview:moreActionsView];
    moreActionsView.delegate=self;

    //calculate geometry
    moreActionsView.frame=self.moreFunctionsButton.frame;
    [moreActionsView layoutIfNeeded];
    CGRect frame=CGRectMake(4, CGRectGetHeight(self.view.bounds)-120-8, CGRectGetWidth(self.view.bounds)-8,120);

    // display with animation
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
        self.customDimmingView.alpha=0.7;
        moreActionsView.alpha=1.0;
        moreActionsView.frame=CGRectInset(frame, 4, 4);
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
            self.selectionMode=TVSelectionModeBatchSMS;
            [self.tableView setEditing:YES animated:NO];
            SMSReceiversView *receiversView=[[[NSBundle mainBundle]loadNibNamed:@"SMSReceiversView" owner:nil options:nil] lastObject];
            self.receiverView=receiversView;
            [self showReceiversView:receiversView];
            break;
        }
        case ActionViewButtonMoreFunctionEmail:{
            self.selectionMode=TVSelectionModeBatchEmail;
            [self.tableView setEditing:YES animated:NO];
            EmailReceiversView *receiversView=[[[NSBundle mainBundle]loadNibNamed:@"EmailReceversView" owner:nil options:nil] lastObject];
            self.receiverView=receiversView;
            [self showReceiversView:receiversView];
            break;
        }
        case ActionViewButtonMoreFunctionScanQR:{
            [self prepareScanQR];
            break;
        }
        case ActionViewButtonMoreFunctionManuallyAdd:{
            UINavigationController *createPersonNavVC=[self.storyboard instantiateViewControllerWithIdentifier:@"create person nav vc"];
            [self dismissSearchController];
            [self presentViewController:createPersonNavVC animated:YES completion:nil];

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
        [self dismissSearchController];
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

        UINavigationController *nav=[self.storyboard instantiateViewControllerWithIdentifier:@"scanresultvc"];
        QRScanResultViewController *scanresultvc=(QRScanResultViewController *)nav.viewControllers[0];
        scanresultvc.resultString=result;

        [self presentViewController:nav animated:YES completion:nil];

}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)showReceiversView:(ReceiversView *)receiversView{

    [self.view addSubview:receiversView];
    CGRect frame=CGRectInset(CGRectMake(0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds), 150),2,0);
    receiversView.frame=frame;
    [receiversView layoutIfNeeded];


    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         receiversView.frame=CGRectOffset(frame, 0, -150);
                         // adjust tableview frame
                         self.tableView.frame=CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-CGRectGetHeight(frame));
                     }
                     completion:nil];

    __weak ReceiversView * weakReceiverView=receiversView;
    receiversView.cancelHandler=^{
        [self.tableView setEditing:NO animated:YES];
        self.selectionMode=TVSelectionModeNormal;
        ((NavigationTitleView *)self.navigationItem.titleView).enabled=YES;
        [self dismissSearchController];
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             weakReceiverView.frame =  CGRectInset(frame, CGRectGetWidth(self.view.bounds)/4, 10);
                             self.tableView.frame=self.view.bounds;
                         }
                         completion:^(BOOL finished) {
                             // restore table view frame
                             [weakReceiverView removeFromSuperview];
                         }];
    };
    receiversView.sendHandler=^(NSArray *phonesOrEmails){

        //the search controller may be working

        [self dismissSearchController];
            //send sms or email
            if ([self.receiverView isKindOfClass:[SMSReceiversView class]]) {
                MFMessageComposeViewController *composeSMSVC=[[MFMessageComposeViewController alloc]init];
                composeSMSVC.recipients=phonesOrEmails;
                composeSMSVC.messageComposeDelegate=self;
                    [self presentViewController:composeSMSVC animated:YES completion:nil];

            }else{
                MFMailComposeViewController *composeEmail=[[MFMailComposeViewController alloc]init];
                composeEmail.mailComposeDelegate=self;
                [composeEmail setToRecipients:phonesOrEmails[0]];
                [composeEmail setCcRecipients:phonesOrEmails[1]];
                [composeEmail setBccRecipients:phonesOrEmails[2]];
                [self presentViewController:composeEmail animated:YES completion:nil];
            }

    };

    self.navigationItem.leftBarButtonItem=[self selectAllBarButtonItem];
}
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(UIBarButtonItem *)selectAllBarButtonItem{
    UIBarButtonItem *selectAll=[[UIBarButtonItem alloc]initWithTitle:@"全选" style:UIBarButtonItemStylePlain target:self action:@selector(selectAllContact:)];
    return selectAll;
}
-(UIBarButtonItem *)deselectAllBarButtonItem{
    UIBarButtonItem *deselectAll=[[UIBarButtonItem alloc]initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(deSelectionAllContact:)];
    return deselectAll;
}
-(void)selectAllContact:(UIBarButtonItem*)barbutton{

    ((NavigationTitleView *)self.navigationItem.titleView).enabled=NO;
    self.navigationItem.rightBarButtonItem.enabled=NO;

    self.navigationItem.leftBarButtonItem=[self deselectAllBarButtonItem];
    //select all
    MBProgressHUD *hud=[[MBProgressHUD alloc]initWithView:self.navigationController.view];
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
    ((NavigationTitleView *)self.navigationItem.titleView).enabled=YES;
    self.navigationItem.rightBarButtonItem.enabled=YES;

    self.navigationItem.leftBarButtonItem=[self selectAllBarButtonItem];

    [self.tableView reloadData];
    [self.receiverView removeAllContactInfos];
}
#pragma  mark - UISearchResultsUpdatingDelegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController{

    NSArray *keywords=[self keyWordsInSearchBar:self.searchController.searchBar];

    if (!keywords.count) {
        self.contacts=self.arrangedContactsUnderCurrentTag;
        [self.searchAssistant removeFromSuperview];
        return;
    }

    NSDictionary *results=[self.contactManager searchContacts:self.baseContactsForSearch keywords:keywords];
    
    if (![results[AdvicedTagsKey] count]) {
        self.contacts=[results[SearchResultContactsKey] mutableCopy];
    }else{
        [self showSearchAssistantView:@{AdvicedTagsKey:results[AdvicedTagsKey],
                                        AdvicedContactsKey:results[AdvicedContactsKey]}];
    }

}
-(NSArray *)keyWordsInSearchBar:(UISearchBar *)searchBar{

    NSMutableArray *keywords=[@[] mutableCopy];
    for (NSString *subString in [searchBar.text componentsSeparatedByString:@" "]) {
        NSString *string=[subString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (string.length) {
            [keywords addObject:string];
        }
    }
    return keywords;

}

#pragma mark - UISearchBarDelegate

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self dismissSearchAssistantView];

    NSArray *keywords=[self keyWordsInSearchBar:self.searchController.searchBar];
    NSDictionary *results=[self.contactManager searchContacts:self.self.baseContactsForSearch keywords:keywords];
    self.contacts=results[SearchResultContactsKey];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    [self dismissSearchAssistantView];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self dismissSearchController];
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
                         [self.searchController.searchBar resignFirstResponder];

                     }];

}

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
        self.currentTag=tag;
        self.navigationTitleView.title=tag.tagName;
        [self dismissSearchController];
    };
    #warning  keyboard height
    CGFloat height=CGRectGetHeight(self.tableView.bounds)-250;
    CGRect frame=CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), height);
    searchAssistantView.frame=CGRectMake(0, -height,CGRectGetWidth(frame), height);
    [searchAssistantView layoutIfNeeded];

    // display with animation
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut
                     animations:^{searchAssistantView.frame=frame;}
                     completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - contact


-(void)setSelectionMode:(TVSelectionMode)selectionMode{

    _selectionMode=selectionMode;
    switch (selectionMode) {
        case TVSelectionModeBatchSMS:{
            self.contacts=(NSMutableArray *)[self.contactManager filterContactsWithoutPhoneNumbers:self.contacts];
            break;
        }
        case TVSelectionModeBatchEmail:{
            self.contacts=(NSMutableArray *)[self.contactManager filterContactsWithoutemail:self.contacts];
            break;
        }
        default:{
            self.contacts=self.arrangedContactsUnderCurrentTag;
            break;
        }
    }
    [self.tableView reloadData];

}

-(void)setContacts:(NSMutableArray *)contacts{

    _contacts=contacts;
    // reset indexTitles
    self.indexTitles=[self.contactManager indexTitleOfContact:contacts];
    if (!self.indexTitles.count) {
        UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 300)];
        label.textAlignment=NSTextAlignmentCenter;
        label.textColor=[UIColor lightGrayColor];
        label.text=@"无联系人";
        label.font=[UIFont systemFontOfSize:20 weight:UIFontWeightLight];
        self.tableView.tableHeaderView=label;
        [self.tableView setContentOffset:CGPointZero];

    }else{
        self.tableView.tableHeaderView=nil;
    }
    for (int section =0;section<self.contacts.count; section++) {
        for (int row =0 ; row<[self.contacts[section] count]; row++) {
            Contact *contact=self.contacts[section][row];
            NSLog(@"contact name:%@",contact.contactName);
        }
    }

    [self.tableView reloadData];
}

-(void)setCurrentTag:(Tag *)currentTag{

    _currentTag=currentTag;
    self.arrangedContactsUnderCurrentTag =[self.contactManager arrangedContactsunderTag:currentTag];
    if (self.selectionMode==TVSelectionModeBatchSMS) {
        self.arrangedContactsUnderCurrentTag=[[self.contactManager filterContactsWithoutPhoneNumbers:self.arrangedContactsUnderCurrentTag] mutableCopy];
    }else if (self.selectionMode==TVSelectionModeBatchEmail){
        self.arrangedContactsUnderCurrentTag=[[self.contactManager filterContactsWithoutemail:self.arrangedContactsUnderCurrentTag] mutableCopy];
    }
}

-(void)setArrangedContactsUnderCurrentTag:(NSMutableArray *)arrangedContactsUnderCurrentTag{
    _arrangedContactsUnderCurrentTag=arrangedContactsUnderCurrentTag;
    self.contacts=self.arrangedContactsUnderCurrentTag;
}

#pragma  mark - unwind
-(IBAction)didCreatePerson:(UIStoryboardSegue *)segue{

    if ([segue.identifier isEqualToString:@"didCreatePerson"]) {

        self.arrangedContactsUnderCurrentTag=[self.contactManager arrangedContactsunderTag:self.currentTag];

        NSArray *searchKeyWords=[self keyWordsInSearchBar:self.searchController.searchBar];

        if (searchKeyWords.count) {
            NSDictionary *results=[self.contactManager searchContacts:self.arrangedContactsUnderCurrentTag keywords:searchKeyWords];
            self.contacts=results[SearchResultContactsKey];
        }
    }

}
#pragma  mark - navigaiton
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"contactDetail"]) {
        ContactDetailsViewController *dstvc=(ContactDetailsViewController *)segue.destinationViewController;
        dstvc.contact=(Contact *)sender;
    }

}
#pragma  mark - tableViewDataSource

-(void)configureTableFooterView{
    UIView *footerView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 200)];
    self.tableView.tableFooterView=footerView;
}

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
    for (int section =0;section<self.contacts.count; section++) {
        for (int row =0 ; row<[self.contacts[section] count]; row++) {
            Contact *contact=self.contacts[section][row];
            NSLog(@"contact name:%@",contact.contactName);
        }
    }
    NSLog(@"indexpath:%@",indexPath);
//    Contact *contact=self.contacts[indexPath.section][indexPath.row];
//    NSLog(@"%@",contact);
//    Contact *contact1=self.contacts[0][0];
//    Contact *contact=[[self.contacts objectAtIndex:0] objectAtIndex:0];
//    cell.contact=contact;
//    cell.delegate=self;
//    switch (self.selectionMode) {
//        case TVSelectionModeBatchSMS:{
//            cell.mode=ContactCellModeSMS;
//            break;
//        }
//        case TVSelectionModeBatchEmail:{
//            cell.mode=ContactCellModeEmail;
//            break;
//        }
//        default:{
//            cell.mode=ContactCellModeNormal;
//        }
//    }

    return cell;

}
// height
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath

{
    return 100;
//    Contact *contact=self.contacts[indexPath.section][indexPath.row];
//    NSLog(@"%@,heser",contact.contactName);
//    if (self.selectionMode == TVSelectionModeBatchSMS)
//    {
//        return  48 + [self.contactManager phoneNumbersOfContact:contact].count * 16;
//
//    }else if (self.selectionMode == TVSelectionModeBatchEmail) {
//
//        return  48 + [self.contactManager emailsOfContact:contact].count * 16;
//
//    }else{
//        return [contact mostRecentEvent] ? 108 :92;
//    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 24;
}

//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//
//    NSString *title=self.indexTitles[section];
//    if ([title isEqualToString:@"☆"]) {
//        NSMutableString *string=[@"" mutableCopy];
//        for (int i =0 ; i< [(NSArray *)self.contacts[0] count]; i++) {
//            [string appendString:title];
//        }
//        return string;
//    }
//    return title;
//}
//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
//    return self.indexTitles;
//}
//- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
//    return index;
//}

#pragma mark - tableviewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    NSArray *contactInfos=nil;
    if (tableView.isEditing) {
        switch (self.selectionMode) {
            case TVSelectionModeBatchSMS:{
                contactInfos=[self.contactManager phoneNumbersOfContact:contact];
                break;
            }
            case TVSelectionModeBatchEmail:{
                contactInfos=[self.contactManager emailsOfContact:contact];
                break;
            }
            default:{
                return;
            }
        }
        if (contactInfos.count <= 1) {
            [self.receiverView addContactInfosToReceivers:contactInfos contact:contact];
            self.navigationItem.rightBarButtonItem.enabled=NO;
            ((NavigationTitleView*)self.navigationItem.titleView).enabled=NO;
        }else{
            BOOL isPhone=[[contactInfos firstObject][ContactInfoTypeKey] integerValue] == ContactInfoTypePhone;
            NSString *title=isPhone ? @"选择电话号码":@"选择邮箱地址";
            UIAlertController *alertController=[self alertControllerForAddingContactInfosToRecevierView:contactInfos
                                                                                  ofContact:contact
                                                                                      title:title
                                                                              cancelHandler:^{
                                    [tableView deselectRowAtIndexPath:indexPath animated:YES];}];
            [self dismissSearchController];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        return;
    }
    [self performSegueWithIdentifier:@"contactDetail" sender:contact];
}
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.isEditing) {
        Contact *contact=self.contacts[indexPath.section][indexPath.row];
        switch (self.selectionMode) {
            case TVSelectionModeBatchSMS:{
                [self.receiverView removeContactInfosOfContact:contact];
                break;
            }
            case TVSelectionModeBatchEmail:{
                [self.receiverView removeContactInfosOfContact:contact];
                break;
            }
            default:{
                return;
            }
        }
        if (!self.receiverView.hasContactInfo) {
            self.navigationItem.rightBarButtonItem.enabled=YES;
            ((NavigationTitleView*)self.navigationItem.titleView).enabled=YES;
        }
    }
}
-(UIAlertController *)alertControllerForAddingContactInfosToRecevierView:(NSArray *)contactInfos
                                                               ofContact:(Contact *)contact
                                                                   title:(NSString *)title
                                                           cancelHandler:(void(^)()) handler{
    // configure alertController
    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSDictionary *contactInfo in contactInfos) {
        NSString *actionTitle=contactInfo[ContactInfoValueKey];
        UIAlertAction *action=[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.navigationItem.rightBarButtonItem.enabled=NO;
            ((NavigationTitleView*)self.navigationItem.titleView).enabled=NO;
            [self.receiverView addContactInfosToReceivers:@[contactInfo] contact:contact];

        }];
        [alertController addAction:action];
    }

    BOOL isPhone= [[contactInfos firstObject][ContactInfoTypeKey] integerValue]==ContactInfoTypePhone;
    UIAlertAction *selectAllAction=[UIAlertAction actionWithTitle:isPhone ? @"全部号码" : @"全部邮箱"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              self.navigationItem.rightBarButtonItem.enabled=NO;
                                                              ((NavigationTitleView*)self.navigationItem.titleView).enabled=NO;
                                                              [self.receiverView addContactInfosToReceivers:contactInfos contact:contact];
                                                          }];
    [alertController addAction:selectAllAction];

    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        handler();
    }];
    [alertController addAction:cancelAction];
    
    return alertController;
    
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //To enable the swipe-to-delete feature of table views (wherein a user swipes horizontally across a row to display a Delete button), you must implement this method
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @[self.deleteAction,self.shareAction,self.topAction];
}


-(UITableViewRowAction *)deleteAction{
    if (!_deleteAction) {
        _deleteAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            Contact *contact= self.contacts[indexPath.section][indexPath.row];
            UIAlertController *deleteAlert=[UIAlertController alertControllerWithTitle:nil message: [@"删除联系人:" stringByAppendingString:contact.contactName] preferredStyle:UIAlertControllerStyleActionSheet];

            UIAlertAction *deleteCompletelyAction=[UIAlertAction actionWithTitle:@"同时删除通讯录中的联系人" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self.contactManager removePerson:contact];
                [self.contacts removeContactAtIndexPath:indexPath];
                self.indexTitles=[self.contactManager indexTitleOfContact:self.contacts];
                [self.tableView reloadData];}];

            UIAlertAction *deleteTemlyAction=[UIAlertAction actionWithTitle:@"保留通讯录中的联系人" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
               [self.contacts removeContactAtIndexPath:indexPath];
               self.indexTitles=[self.contactManager indexTitleOfContact:self.contacts];
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
-(UITableViewRowAction *)topAction{
    if (!_topAction) {
        _topAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"置顶" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [self putToTop:indexPath];
        }];
        _topAction.backgroundColor=[UIColor lightGrayColor];
    }
    return _topAction;
}
-(UITableViewRowAction *)shareAction{
    if (!_shareAction) {
        _shareAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"共享" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            Contact *contact= self.contacts[indexPath.section][indexPath.row];
            NSString *sharedInfo=[NSString stringWithFormat:@"姓名:%@; ",contact.contactName];
            sharedInfo=[sharedInfo stringByAppendingString:[self phoneInfoOfContact:contact]];
            sharedInfo=[sharedInfo stringByAppendingString:[self emailInfoOfContact:contact]];
            UIActivityViewController *activityVC=[[UIActivityViewController alloc]initWithActivityItems:@[sharedInfo] applicationActivities:nil];
            NSLog(@"info:%@",sharedInfo);

            [self dismissSearchController];
            [self presentViewController:activityVC animated:YES completion:nil];

        }];
        _shareAction.backgroundColor=[UIColor orangeColor];

    }
    return _shareAction;
}

-(NSString *)stringOfContactInfos:(NSArray *)contactInfos{
    NSString *contactInfosString=@"";
    for (NSDictionary *contactInfo in contactInfos) {
        contactInfosString=[contactInfosString stringByAppendingString:[NSString stringWithFormat:@"%@:%@,",contactInfo[ContactInfoLabelKey],contactInfo[ContactInfoValueKey]]];
    }
    if (contactInfosString.length) {
        contactInfosString=[contactInfosString substringToIndex:contactInfosString.length-1];
        contactInfosString=[contactInfosString stringByAppendingString:@";"];
    }
    return contactInfosString;
}
-(NSString *)phoneInfoOfContact:(Contact *)contact{
    NSArray *phones=[self.contactManager phoneNumbersOfContact:contact];
    return  [self stringOfContactInfos:phones];
}
-(NSString *)emailInfoOfContact:(Contact *)contact{
    NSArray *emails=[self.contactManager emailsOfContact:contact];
    return  [self stringOfContactInfos:emails];
}

#pragma mark - cell delegate;

-(UIAlertController *)alertControllerPhonesOrEmails:(NSArray *)infos
                                      actionHandler:(void(^)(UIAlertAction *action,NSString *phoneNumberOrEmailAddress))handler
                                      cancelHandler:(void(^)(UIAlertAction *action))cancleHandler{

    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSDictionary *info in infos) {
        NSString *title=[NSString stringWithFormat:@"%@: %@", info[ContactInfoLabelKey],info[ContactInfoValueKey]];
        UIAlertAction *action=[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            handler(action,info[ContactInfoValueKey]);
        }];
        [alertController addAction:action];
    }

    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:cancleHandler];
    [alertController addAction:cancelAction];
    return alertController;

}


-(void)phone:(Contact *)contact phonesInfo:(NSArray *)numbers{
    UIAlertController *phoneAlertController=[self alertControllerPhonesOrEmails:numbers actionHandler:^(UIAlertAction *action,NSString *phoneNumberOrEmailAddress) {
        NSString *urlString=[NSString stringWithFormat:@"tel://%@",phoneNumberOrEmailAddress];
        NSURL *url=[NSURL URLWithString:urlString];
        if ([[UIApplication sharedApplication]canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    } cancelHandler:nil];
    phoneAlertController.message=[NSString stringWithFormat:@"给 %@ 打电话",contact.contactName];
    [self dismissSearchController];
    [self presentViewController:phoneAlertController animated:YES completion:nil];

}
-(void)sms:(Contact *)contact phonesInfo:(NSArray *)numbers {

    UIAlertController *phoneAlertController=[self alertControllerPhonesOrEmails:numbers actionHandler:^(UIAlertAction *action,NSString *phoneNumberOrEmailAddress) {
        MFMessageComposeViewController *composeSMSVC=[[MFMessageComposeViewController alloc]init];
        composeSMSVC.recipients=@[phoneNumberOrEmailAddress];
        composeSMSVC.messageComposeDelegate=self;
        [self presentViewController:composeSMSVC animated:YES completion:nil];
    }cancelHandler:nil];
    phoneAlertController.message=[NSString stringWithFormat:@"给 %@ 发短信",contact.contactName];

    [self dismissSearchController];
    [self presentViewController:phoneAlertController animated:YES completion:nil];

}
-(void)email:(Contact *)contact emailsInfo:(NSArray *)emails {
    UIAlertController *phoneAlertController=[self alertControllerPhonesOrEmails:emails actionHandler:^(UIAlertAction *action,NSString *phoneNumberOrEmailAddress) {

        MFMailComposeViewController *composeEmail=[[MFMailComposeViewController alloc]init];
        composeEmail.mailComposeDelegate=self;
        [composeEmail setToRecipients:@[phoneNumberOrEmailAddress]];
        [self presentViewController:composeEmail animated:YES completion:nil];
        
    }cancelHandler:nil];
    phoneAlertController.message=[NSString stringWithFormat:@"给 %@ 发邮件",contact.contactName];

    [self dismissSearchController];
    [self presentViewController:phoneAlertController animated:YES completion:nil];

}
-(void)putToTop:(NSIndexPath *)indexPath{
    Contact *contact=self.contacts[indexPath.section][indexPath.row];
    contact.contactOrderWeight=@([NSDate timeIntervalSinceReferenceDate]);
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
