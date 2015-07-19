//
//  SearchAssistantView.h
//  Contacts Assistant
//
//  Created by Amay on 7/14/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchAssistantView : UIView <UITableViewDataSource,UITableViewDelegate>

@property(strong,nonatomic)NSOrderedSet *searchAdvice;

@property(copy) void(^keyWordSelectedHandler)(NSDictionary *keyWord);

@end
