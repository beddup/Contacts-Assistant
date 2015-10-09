//
//  ContactView.h
//  Contacts Assistant
//
//  Created by Amay on 7/17/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tag.h"

typedef enum : NSUInteger {
    ContactCellModeNormal=0,
    ContactCellModeSMS,
    ContactCellModeEmail,
} ContactCellMode;



@interface ContactCell : UITableViewCell

@property(strong,nonatomic)Contact *contact;
@property(nonatomic)ContactCellMode mode;

/*
 考虑显示的内容：
 1. 目前不定位于社交，不显示图片
 2. 重点显示的内容
    － 姓名
    － 公司、部门、job title
 3. 便捷电话、邮件、短信的按钮
 4. 显示最新关于 contact 的事项 
 5. 添加关于contact的事项
 */

@end
