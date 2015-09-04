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
@interface TagNavigationView()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(strong,nonatomic)NSArray *tags;

@end

@implementation TagNavigationView

#pragma  mark - UITableViewDataSource

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

    UIButton *buttonfooter=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 0, 44)];
    self.tableView.tableFooterView=buttonfooter;
    [buttonfooter setTitle:@"管理标签" forState:UIControlStateNormal];
    [buttonfooter setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    buttonfooter.titleLabel.font=[UIFont systemFontOfSize:17];
    [buttonfooter addTarget:self action:@selector(manageTags:) forControlEvents:UIControlEventTouchUpInside];

    UILabel *headerLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 25)];
    self.tableView.tableHeaderView=headerLabel;
    headerLabel.textColor=[UIColor lightGrayColor];
    headerLabel.text=@"选择标签筛选联系人";
    headerLabel.font=[UIFont systemFontOfSize:14];
    headerLabel.textAlignment=NSTextAlignmentCenter;

    self.tags = [[Tag allTags] sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
        return obj1.ownedContacts.count <= obj2.ownedContacts.count;
    }];


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
