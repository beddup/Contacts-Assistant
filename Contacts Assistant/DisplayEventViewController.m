//
//  EventsViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "DisplayEventViewController.h"
#import "EventDetailView.h"

@interface DisplayEventViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *eventDetailScrollContainer;
@property(weak,nonatomic)EventDetailView *detailView;

@end

@implementation DisplayEventViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"事项";
    [self addContentToScrollView];
    // Do any additional setup after loading the view.
}

- (void)addContentToScrollView{

    EventDetailView *detailView=[[[NSBundle mainBundle]loadNibNamed:@"EventDetailView" owner:nil options:nil]lastObject];
    detailView.event=self.event;
    self.detailView=detailView;
    [self.eventDetailScrollContainer addSubview:detailView];

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.eventDetailScrollContainer.contentSize=CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.detailView.bounds)+50);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
