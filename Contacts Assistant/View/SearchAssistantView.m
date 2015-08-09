//
//  SearchAssistantView.m
//  Contacts Assistant
//
//  Created by Amay on 7/14/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "SearchAssistantView.h"
#import "VisualizedContactsViewController.h"
#import "ContactsManager.h"
#import "Tag.h"
#import "Contact.h"
@interface SearchAssistantView()

@property (weak, nonatomic) IBOutlet UITableView *searchAdviceTV;

@end

@implementation SearchAssistantView
@synthesize searchAdvice=_searchAdvice;


-(void)setSearchAdvice:(NSDictionary *)searchAdvice{

    _searchAdvice=searchAdvice;
    [self.searchAdviceTV reloadData];
}

#pragma mark - TVDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger tagCount = [self.searchAdvice[AdvicedTagsKey] count];
    if (indexPath.row < tagCount) {
        self.advicedTagSelectedHandler([self.searchAdvice[AdvicedTagsKey] objectAtIndex:indexPath.row]);

    }else{
        self.advicedContactSelectedHandler([self.searchAdvice[AdvicedContactsKey] objectAtIndex:indexPath.row-tagCount]);
    }

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 36.0;
}
#pragma mark - TVDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.searchAdvice[AdvicedTagsKey] count] + [self.searchAdvice[AdvicedContactsKey] count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"search advice"];

    if (!cell) {
            cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"search advice"];
            cell.textLabel.textColor=[UIColor darkGrayColor];
            cell.textLabel.font=[UIFont systemFontOfSize:13.0 weight:UIFontWeightLight];
            cell.textLabel.lineBreakMode=NSLineBreakByTruncatingTail;
            cell.textLabel.textAlignment=NSTextAlignmentLeft;

            cell.detailTextLabel.textColor=[UIColor lightGrayColor];
            cell.detailTextLabel.font=[UIFont systemFontOfSize:10.0 weight:UIFontWeightLight];
            cell.detailTextLabel.textAlignment=NSTextAlignmentRight;
    }
    NSInteger tagCount = [self.searchAdvice[AdvicedTagsKey] count];
    if (indexPath.row < tagCount) {
        cell.textLabel.text=[(Tag *)[self.searchAdvice[AdvicedTagsKey] objectAtIndex:indexPath.row] tagName];
        cell.detailTextLabel.text=@"标签";
    }else{
        cell.textLabel.text = [(Contact *)[self.searchAdvice[AdvicedContactsKey] objectAtIndex:indexPath.row-tagCount] contactName];
        cell.detailTextLabel.text=@"联系人";
    }

    return cell;

}

#pragma  mark - setup

-(void)awakeFromNib{
    [self setup];
}
-(void)setup{
    
    self.contentMode=UIViewContentModeScaleToFill;
    self.opaque=YES;

    // configure table header view
    UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 25)];
    label.text=@"搜索建议";
    label.textColor=[UIColor lightGrayColor];
    label.textAlignment=NSTextAlignmentCenter;
    label.font=[UIFont systemFontOfSize:14 weight:UIFontWeightLight];
    self.searchAdviceTV.tableHeaderView=label;

}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

@end
