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

CGFloat const SearchAssistantViewHeight=150.0;

CGFloat const OperationViewWidth = 200;
CGFloat const OperationViewHeight = 238;



@interface VisualizedContactsViewController ()<UISearchResultsUpdating,UISearchControllerDelegate,UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (weak, nonatomic) IBOutlet UIButton *moreFunctionsButton;

@property(strong,nonatomic)UISearchController *searchController;

@property(weak,nonatomic)UIView *customDimmingView;
@property(weak,nonatomic)ActionsView *batchEditingView;
@property(weak,nonatomic)ActionsView *moreFunctionsView;
@property(weak,nonatomic)SearchAssistantView *searchAssistant;
@property(weak,nonatomic)TagNavigationView *tagNavigationView;

@property(strong,nonatomic) ContactsManager * contactManager;

@end

@implementation VisualizedContactsViewController


- (void)viewDidLoad {

    [super viewDidLoad];
    [self configureMoreFunctionButton];
    [self configureTitleView];
//    dispatch_queue_t updateCoreDataQueue = dispatch_queue_create("UpdateCoreDataQueue", NULL);
//    dispatch_async(updateCoreDataQueue, ^{
//        [self.contactManager updateCoreDataBasedOnContacts];
//    });
//
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contactsTableView reloadData];
        });

    });
}
-(ContactsManager *)contactManager{

    if (!_contactManager) {
        _contactManager=[[ContactsManager alloc]init];
        self.contactsTableView.delegate=_contactManager;
        self.contactsTableView.dataSource=_contactManager;

    }
    return _contactManager;
}
-(void)configureMoreFunctionButton{

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
    CGRect rect = [self.navigationController.navigationBar convertRect:self.navigationController.navigationBar.bounds toView:self.view];
    CGRect frame=CGRectMake(0, CGRectGetMaxY(rect), CGRectGetWidth(self.view.bounds), 0);
    tagNavigationView.frame=frame;
    [tagNavigationView layoutIfNeeded];

    // display with animation
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
        self.customDimmingView.alpha=0.7;
        tagNavigationView.frame=CGRectMake(0, CGRectGetMaxY(rect), CGRectGetWidth(self.view.bounds), 150);
    } completion:nil];

}
- (IBAction)prepareToSearch:(UIBarButtonItem *)sender {

    [self prepareSearchController];
    [self.searchController.searchBar becomeFirstResponder];

}
-(void )prepareSearchController{

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
    self.contactsTableView.tableHeaderView=searchBar;
    
}
-(void)dim{
    UIView *dimmingView=[[UIView alloc]initWithFrame:self.contactsTableView.frame];
    dimmingView.backgroundColor=[UIColor darkGrayColor];
    self.customDimmingView=dimmingView;
    self.customDimmingView.alpha=0.0;
    [self.view addSubview:dimmingView];

    UITapGestureRecognizer *tapToDismissAdd=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissDimmingView:)];
    [self.customDimmingView addGestureRecognizer:tapToDismissAdd];
}
-(void)dismissDimmingView:(UITapGestureRecognizer *)gesture{

    [self.customDimmingView removeFromSuperview];
    [self.moreFunctionsView removeFromSuperview];
    [self.batchEditingView removeFromSuperview];
    [self.tagNavigationView removeFromSuperview];

    self.navigationItem.rightBarButtonItem.enabled=YES;
    self.navigationItem.leftBarButtonItem.enabled=YES;


    CGRect rect=self.view.bounds;
    self.moreFunctionsButton.frame=CGRectMake(CGRectGetWidth(rect)/2-70/2, CGRectGetHeight(rect)-44-12, 70, 44);

}
- (IBAction)prepareToBatchEditContacts:(UIBarButtonItem *)sender {
    if (self.batchEditingView) {
        [self dismissDimmingView:nil];
        return;
    }
    // dim bkg
    [self dim];
    self.navigationItem.rightBarButtonItem.enabled=NO;

    // prepare action view
    ActionsView *batchEditingView=[[[NSBundle mainBundle]loadNibNamed:@"BatchEditOptionsView" owner:nil options:nil] lastObject];
    [self.view addSubview:batchEditingView];
    self.batchEditingView=batchEditingView;

    //calculate geometry
    CGRect rect = [self.navigationController.navigationBar convertRect:self.navigationController.navigationBar.bounds toView:self.view];
    CGRect frame=CGRectMake(0, CGRectGetMaxY(rect), 200, 0);
    batchEditingView.frame=frame;
    [batchEditingView layoutIfNeeded];

    // display with animation
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
        self.customDimmingView.alpha=0.7;
        batchEditingView.frame=CGRectMake(0, CGRectGetMaxY(rect), 200, 100);
    } completion:nil];

}
- (IBAction)displayMoreActions:(UIButton *)sender {
    // dim bkg
    [self dim];

    self.navigationItem.rightBarButtonItem.enabled=NO;
    self.navigationItem.leftBarButtonItem.enabled=NO;

    // prepare action view
    ActionsView *moreActionsView=[[[NSBundle mainBundle]loadNibNamed:@"MoreFuctionsView" owner:nil options:nil] lastObject];
    [self.view addSubview:moreActionsView];
    self.moreFunctionsView=moreActionsView;

    //calculate geometry
    moreActionsView.frame=self.moreFunctionsButton.frame;
    [moreActionsView layoutIfNeeded];
    CGRect frame=CGRectMake(4, CGRectGetHeight(self.view.bounds)-100-20, CGRectGetWidth(self.view.bounds)-8,100);

    // display with animation
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
        self.customDimmingView.alpha=0.7;
        self.moreFunctionsButton.frame=frame;
        moreActionsView.frame=CGRectInset(frame, 4, 4);
    } completion:nil];

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
            CGRect rect=[self.searchController.searchBar convertRect:self.searchController.searchBar.bounds toView:self.view];
            CGRect frame=CGRectMake(0, CGRectGetMaxY(rect), CGRectGetWidth(self.searchController.searchBar.bounds), 120);
            searchAssistantView.frame=CGRectMake(0, CGRectGetMinY(frame),CGRectGetWidth(frame), 0);
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

@end
