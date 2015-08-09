//
//  SearchAssistantView.h
//  Contacts Assistant
//
//  Created by Amay on 7/14/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Contact,Tag;
@interface SearchAssistantView : UIView <UITableViewDataSource,UITableViewDelegate>

@property(strong,nonatomic)NSDictionary *searchAdvice;

@property(copy) void(^advicedContactSelectedHandler)(Contact *selectedContact);
@property(copy) void(^advicedTagSelectedHandler)(Tag *selectedTag);

@end
