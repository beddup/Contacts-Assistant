//
//  SearchAssistantView.m
//  Contacts Assistant
//
//  Created by Amay on 7/14/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "SearchAssistantView.h"
#import "VisualizedContactsViewController.h"

@interface SearchAssistantView()

@property (weak, nonatomic) IBOutlet UITableView *searchAdviceTV;

@end

@implementation SearchAssistantView
@synthesize searchAdvice=_searchAdvice;

-(NSOrderedSet *)searchAdvice{
    if (!_searchAdvice) {
        _searchAdvice=[NSOrderedSet orderedSetWithObjects:@"Frienasdfasfsdsdsdafdd",@"Family",@"Stranger",@"Others",nil];
    }
    return _searchAdvice;
}
-(void)setSearchAdvice:(NSOrderedSet *)searchAdvice{

    _searchAdvice=searchAdvice;
    [self.searchAdviceTV reloadData];
}

#pragma mark - TVDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    NSLog(@"selected");
    self.keyWordSelectedHandler(self.searchAdvice[indexPath.row]);
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 36.0;
}
#pragma mark - TVDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.searchAdvice.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"search advice"];

    if (!cell) {
            cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"search advice"];
            cell.textLabel.textColor=[UIColor darkGrayColor];
            cell.textLabel.font=[UIFont systemFontOfSize:13.0 weight:UIFontWeightLight];
            cell.textLabel.lineBreakMode=NSLineBreakByTruncatingTail;
            cell.textLabel.textAlignment=NSTextAlignmentLeft;

            cell.detailTextLabel.textColor=[UIColor lightGrayColor];
            cell.detailTextLabel.font=[UIFont systemFontOfSize:10.0 weight:UIFontWeightLight];
            cell.detailTextLabel.textAlignment=NSTextAlignmentRight;
        cell.backgroundColor=[UIColor lightGrayColor];
            
    }

    cell.textLabel.text=self.searchAdvice[indexPath.row];
    cell.detailTextLabel.text=@"tag";

    return cell;

}

#pragma  mark - setup

-(void)awakeFromNib{
    [self setup];
}
-(void)setup{
    
    self.contentMode=UIViewContentModeScaleToFill;
    self.opaque=YES;

}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

@end
