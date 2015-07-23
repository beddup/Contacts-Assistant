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
@property (weak, nonatomic) UIButton *moreFunctionsButton;

@property(strong,nonatomic)UISearchController *searchController;

@property(weak,nonatomic)UIView *customDimmingView;
@property(weak,nonatomic)UIView *batchEditingContainerView;
@property(weak,nonatomic)UIView *moreFunctionsContainerView;
@property(weak,nonatomic)SearchAssistantView *searchAssistant;
@property(weak,nonatomic)TagNavigationView *tagNavigationView;

@property(strong,nonatomic) ContactsManager * contactManager;

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
            [self.contactsTableView reloadData];
        });

    });
}
-(ContactsManager *)contactManager{

    if (!_contactManager) {
        _contactManager=[ContactsManager sharedContactManager];
        self.contactsTableView.delegate=_contactManager;
        self.contactsTableView.dataSource=_contactManager;
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
    self.contactsTableView.tableHeaderView =searchBar;
    [self.contactsTableView setContentOffset:CGPointMake(0, 44)];

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

    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:-0.5 options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseInOut animations:^{

        self.customDimmingView.alpha=0.0;
        self.moreFunctionsButton.frame=CGRectMake(CGRectGetWidth(self.view.bounds)/2-70/2, CGRectGetHeight(self.view.bounds)-44-12, 70, 44);
        self.moreFunctionsContainerView.frame=CGRectInset(self.moreFunctionsButton.frame, 35, 22);
        self.batchEditingContainerView.frame=CGRectMake(0, -100-70, CGRectGetWidth(self.view.bounds), 100);
        self.tagNavigationView.frame=CGRectMake(0, -150-70, CGRectGetWidth(self.view.bounds), 150);
        self.searchAssistant.frame=CGRectMake(0, -120-70, CGRectGetWidth(self.view.bounds), 120);

    } completion:^(BOOL finished) {
        [self.customDimmingView removeFromSuperview];
        [self.moreFunctionsContainerView removeFromSuperview];
        [self.batchEditingContainerView removeFromSuperview];
        [self.tagNavigationView removeFromSuperview];
    }];

    self.navigationItem.rightBarButtonItem.enabled=YES;
    self.navigationItem.leftBarButtonItem.enabled=YES;

}
- (IBAction)prepareToBatchEditContacts:(UIBarButtonItem *)sender {
    if (self.batchEditingContainerView) {
        [self dismissDimmingView:nil];
        return;
    }
    // dim bkg
    [self dim];
    self.navigationItem.rightBarButtonItem.enabled=NO;

    // prepare scrollView
    UIScrollView *scrollView=[[UIScrollView alloc]init];
    scrollView.backgroundColor=[UIColor lightGrayColor];
    [self.view addSubview:scrollView];
    self.batchEditingContainerView=scrollView;
    // prepare action view
    ActionsView *batchEditing=[[[NSBundle mainBundle]loadNibNamed:@"BatchEditOptionsView" owner:nil options:nil] lastObject];
    [scrollView addSubview:batchEditing];

    //calculate geometry
    scrollView.contentSize=CGSizeMake(CGRectGetWidth(self.view.bounds)+5, 100);
    CGRect frame=CGRectMake(0, -100, CGRectGetWidth(self.view.bounds), 100);
    scrollView.frame=frame;

    // display with animation
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
        self.customDimmingView.alpha=0.7;
        scrollView.frame=CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 100);
        batchEditing.frame=CGRectOffset(scrollView.bounds, 4, 4);

    } completion:nil];

}
- (IBAction)displayMoreActions:(UIButton *)sender {
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
        self.contactsTableView.tableHeaderView.alpha=0.1;
    }completion:^(BOOL finished) {
        [self.contactsTableView setContentOffset:CGPointMake(0, 44) animated:YES];
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

@end
