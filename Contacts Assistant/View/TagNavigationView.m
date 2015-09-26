//
//  TagNavigationView.m
//  Contacts Assistant
//
//  Created by Amay on 7/22/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "TagNavigationView.h"
#import "AppDelegate.h"
#import "TagCell.h"
#import "Tag+Utility.h"
#import "defines.h"
@interface TagNavigationView()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(strong,nonatomic)NSArray *tags;

@property(weak,nonatomic)UIButton *managerButton;
@property(weak,nonatomic)UILabel *titleLabel;

@end

@implementation TagNavigationView

#pragma  mark - UITableViewDataSource

-(void)layoutSubviews{
    CGRect tableHeaderBounds=self.tableView.tableHeaderView.bounds;
    self.titleLabel.frame=CGRectMake(self.tableView.separatorInset.left, 0, CGRectGetWidth(tableHeaderBounds), CGRectGetHeight(tableHeaderBounds));
    self.managerButton.frame=CGRectMake(CGRectGetWidth(tableHeaderBounds)-self.tableView.separatorInset.right-60, 0,60,CGRectGetHeight(tableHeaderBounds));
}
-(void)updateTags{

    self.tags=[Tag allTagsSortedByOwnedContactsCountAndTagName];
    [self.tableView reloadData];
    [APP saveContext];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.tags.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TagCell *cell=(TagCell *)[tableView dequeueReusableCellWithIdentifier:@"Tag Cell"];
    if (!cell) {
        cell= [[TagCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Tag Cell"];
        cell.separatorInset=UIEdgeInsetsMake(0, 15, 0, 15);
    }
    Tag *tag=self.tags[indexPath.row];
    cell.myTag=tag;    
    return cell;
}

#pragma  mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    self.didSelectTag(self.tags[indexPath.row]);
    
}

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    UIView *headerView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 36)];
    self.tableView.tableHeaderView=headerView;

    UILabel *titleLabel=[[UILabel alloc]init];
    self.titleLabel=titleLabel;
    [headerView addSubview:titleLabel];
    titleLabel.textColor=[UIColor lightGrayColor];
    titleLabel.text=@"选择标签筛选联系人";
    titleLabel.font=[UIFont systemFontOfSize:15];
    titleLabel.textAlignment=NSTextAlignmentLeft;

    UIButton *manageButton=[[UIButton alloc]init];
    self.managerButton=manageButton;
    [headerView addSubview:manageButton];
    [manageButton setTitle:@"管理标签" forState:UIControlStateNormal];
    manageButton.titleLabel.font=[UIFont systemFontOfSize:15];
    [manageButton setTitleColor:IconColor
                       forState:UIControlStateNormal];
    [manageButton addTarget:self action:@selector(manageTags:) forControlEvents:UIControlEventTouchUpInside];

    self.tags=[Tag allTagsSortedByOwnedContactsCountAndTagName];

}

-(void)manageTags:(UIButton *)button{
    self.manageTags();
}

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}












@end
