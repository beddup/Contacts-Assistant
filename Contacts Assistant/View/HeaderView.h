//
//  HeaderView.h
//  Contacts Assistant
//
//  Created by Amay on 7/20/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    HeaderTypeTags,
    HeaderTypeContacts,
} HeaderType;
@class HeaderView;

@protocol HeaderViewDelegate <NSObject>

-(void)addNewContact;
-(void)addNewTagNamed:(NSString *)tagName;
-(BOOL)tagNameExists:(NSString *)tagName;

@end
@interface HeaderView : UITableViewHeaderFooterView

@property(weak,nonatomic)id<HeaderViewDelegate>delegate;

@property(nonatomic)HeaderType type;
@property(weak,nonatomic)UIButton *addButton;

@end
