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
@property (weak, nonatomic) IBOutlet UIButton *backToParentTagButton;

@property(strong,nonatomic)NSArray *tags;

@end

@implementation TagNavigationView
@synthesize tags=_tags;

#pragma mark - Properties
-(void)setCurrentTag:(Tag *)currentTag{
    _currentTag=currentTag;
    self.tags=[currentTag.childrenTags allObjects];
    self.backToParentTagButton.hidden=[currentTag isRootTag];
}

-(NSArray *)tags{
    if (!_tags) {
        _tags=@[];
    }
    return _tags;
}
-(void)setTags:(NSArray *)tags{
    _tags=tags;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
}

#pragma mark - actions
- (IBAction)backToParentTag:(UIButton *)sender {
    self.currentTag=self.currentTag.parentTag;
}
- (IBAction)manageTags:(UIButton *)sender {
    self.manageTags();
}
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
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    }
    Tag *tag=self.tags[indexPath.row];
    cell.tagName=tag.tagName;

    return cell;
}
#pragma  mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.didSelectTag(self.tags[indexPath.row]);
    
}
-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.currentTag=self.tags[indexPath.row];
}













@end
