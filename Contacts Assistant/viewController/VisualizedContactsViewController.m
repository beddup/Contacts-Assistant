//
//  ViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/13/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "VisualizedContactsViewController.h"
#import "SearchAssistantView.h"
#import "OperationsView.h"
#import "ContactsManager.h"
#import "ContactNetView.h"

CGFloat const SearchAssistantViewHeight=150.0;

CGFloat const OperationViewWidth = 200;
CGFloat const OperationViewHeight = 238;



@interface VisualizedContactsViewController ()<UISearchResultsUpdating,UISearchControllerDelegate,UISearchBarDelegate,OperationDelegate>

@property(strong,nonatomic)UISearchController *searchController;
@property(weak,nonatomic)SearchAssistantView *searchAssistant;

@property(weak,nonatomic)UIView *contentDimmingView;
@property(weak,nonatomic)UIView *navigationDimmingView;
@property(weak,nonatomic)OperationsView *operationView;

@property(strong,nonatomic) ContactsManager * contactManager;
@property(weak,nonatomic)ContactNetView *contactNetView;

@end

@implementation VisualizedContactsViewController


- (void)viewDidLoad {

    [super viewDidLoad];
    [self configureNavigationBar];

    dispatch_queue_t updateCoreDataQueue = dispatch_queue_create("UpdateCoreDataQueue", NULL);
    dispatch_async(updateCoreDataQueue, ^{
        [self.contactManager updateCoreDataBasedOnContacts];
    });
    ContactNetView *contactNetView=[[ContactNetView alloc]initWithFrame:CGRectZero];
    self.contactNetView=contactNetView;
    [self.view addSubview:contactNetView];

}
-(void)viewWillAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coreDataUpdatingFinished:) name:ContactManagerDidFinishUpdatingCoreData object:nil];
    [super viewWillAppear:animated];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ContactManagerDidFinishUpdatingCoreData object:nil];
}
-(void)coreDataUpdatingFinished:(NSNotification *)notification{

    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"y:%f",CGRectGetMaxY(self.navigationController.navigationBar.frame));

        self.contactNetView.dataSource=self.contactManager;
        self.contactNetView.delegate=self.contactManager;

        self.contactNetView.frame=CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-CGRectGetMaxY(self.navigationController.navigationBar.frame));
        [self.contactNetView setNeedsLayout];


    });


}
-(ContactsManager *)contactManager{

    if (!_contactManager) {
        _contactManager=[[ContactsManager alloc]init];
    }
    return _contactManager;
}
-(void)configureNavigationBar{

    //configure rightBarButtonItem
    self.navigationItem.rightBarButtonItem= [self createRightButtonItem];

    //configure searchBar
    [self configureSearchController];
    UISearchBar *searchBar=self.searchController.searchBar;
    searchBar.placeholder=@"Keyword: Contact Info or Tag Name";
    searchBar.delegate=self;
    searchBar.showsCancelButton=NO;
    self.navigationItem.titleView=searchBar;


}
-(UIBarButtonItem *)createRightButtonItem{

    return [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                        target:self
                                                        action:@selector(add:)];

}

-(void)add:(UIBarButtonItem *)barButtonItem{

    // navigation dimmingview
    UIView *navigationDimmingView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetMaxY(self.navigationController.navigationBar.bounds)+20)];
    [navigationDimmingView setBackgroundColor:[UIColor darkGrayColor]];
    navigationDimmingView.alpha=0.0;
    [self.navigationController.view addSubview:navigationDimmingView];
    self.navigationDimmingView=navigationDimmingView;

    //content dimming View
    UIView *contentDimmingView=[[UIView alloc]initWithFrame:self.view.bounds];
    [contentDimmingView setBackgroundColor:[UIColor darkGrayColor]];
    contentDimmingView.alpha=0;
    [self.view addSubview:contentDimmingView];
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissOperationsView:)];
    [contentDimmingView addGestureRecognizer:tap];
    self.contentDimmingView=contentDimmingView;

    // create operations View
    OperationsView *operationView=[[[NSBundle mainBundle]loadNibNamed:@"OperationView" owner:nil options:nil]lastObject];
    operationView.frame=CGRectMake(CGRectGetWidth(self.view.bounds)-OperationViewWidth-8, -OperationViewHeight+CGRectGetMaxY(self.navigationController.navigationBar.frame), OperationViewWidth, OperationViewHeight);
    [self.view addSubview:operationView];
    operationView.delegate=self;
    self.operationView=operationView;


    //animation dimming view and operation view
    [UIView animateWithDuration:0.3 animations:^{
        contentDimmingView.alpha=0.5;
        navigationDimmingView.alpha=0.3;
        operationView.frame=CGRectMake(CGRectGetWidth(self.view.bounds)-OperationViewWidth-8, CGRectGetMaxY(self.navigationController.navigationBar.frame), OperationViewWidth, OperationViewHeight);
    }];
}
-(void)dismissOperationViewAnimation:(BOOL)animated{

    [UIView animateWithDuration:animated ? 0.3 : 0 animations:^{
        if (animated) {
            self.navigationDimmingView.alpha=0.0;
            self.contentDimmingView.alpha=0.0;
            self.operationView.frame=CGRectMake(CGRectGetWidth(self.view.bounds)-OperationViewWidth-8, -OperationViewHeight+CGRectGetMaxY(self.navigationController.navigationBar.frame), OperationViewWidth, OperationViewHeight);
        }
        } completion:^(BOOL finished) {
            [self.navigationDimmingView removeFromSuperview];
            [self.contentDimmingView removeFromSuperview];
            [self.operationView removeFromSuperview];
        }];
}
-(void)dismissOperationsView:(UITapGestureRecognizer *)gesture{
    NSLog(@"tapped");
    if (gesture.state==UIGestureRecognizerStateEnded) {
        [self dismissOperationViewAnimation:YES];
    }
}
#pragma  mark - OperationViewDelegate
-(void)operationViewCreatNewContact:(OperationsView *)view{
    [self dismissOperationViewAnimation:NO];

}
-(void)operationViewScanQRCode:(OperationsView *)view{
    [self dismissOperationViewAnimation:NO];

}
-(void)operationViewExchangeCard:(OperationsView *)view{
    [self dismissOperationViewAnimation:NO];


}
-(void)operationViewSendSMS:(OperationsView *)view{
    [self dismissOperationViewAnimation:NO];

}
-(void)operationViewSendEmail:(OperationsView *)view{
    [self dismissOperationViewAnimation:NO];

}

#pragma  mark - UISearchResultsUpdatingDelegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    NSLog(@"updating");
}
#pragma mark - UISearchBarDelegate
-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    
    self.navigationItem.rightBarButtonItem=nil;
    [self showSearchAssistantView];

}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{

    // dismiss searchAssistantView
    [searchBar setShowsCancelButton:NO animated:YES];
    [self dismissSearchAssistantView];

}
-(void)dismissSearchAssistantView{
    [UIView animateWithDuration:0.3 animations:^{

        self.searchAssistant.frame=CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame)-SearchAssistantViewHeight, CGRectGetWidth(self.view.bounds), SearchAssistantViewHeight);

    } completion:^(BOOL finished) {
        if (finished) {
            [self.searchAssistant removeFromSuperview];
        }
    }];

}

-(void)showSearchAssistantView{

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
            CGFloat y=CGRectGetMaxY(self.navigationController.navigationBar.frame);
            CGRect frame=CGRectMake(0, y-SearchAssistantViewHeight, CGRectGetWidth(self.view.bounds), SearchAssistantViewHeight);
            frame=CGRectInset(frame, 4, 4);
            searchAssistantView.frame=frame;
            [self.view addSubview:searchAssistantView];
            self.searchAssistant=searchAssistantView;
            [UIView animateWithDuration:2 animations:^{
                searchAssistantView.frame=CGRectOffset(frame, 0, SearchAssistantViewHeight);
                NSLog(@"searchAssistantView y %f",searchAssistantView.frame.origin.y);
            }];
        });
    });
}
-(void )configureSearchController{

    UISearchController *searchController=[[UISearchController alloc]initWithSearchResultsController:nil];
    self.searchController=searchController;

    searchController.searchResultsUpdater=self;
    searchController.delegate=self;

    [searchController setHidesNavigationBarDuringPresentation:NO];
    [searchController setDimsBackgroundDuringPresentation:NO];

}

#pragma mark - UISearchControllerDelegate
-(void)willDismissSearchController:(UISearchController *)searchController{

    if (!self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem=[self createRightButtonItem];
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
