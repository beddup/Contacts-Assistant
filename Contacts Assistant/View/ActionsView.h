//
//  ActionsView.h
//  Contacts Assistant
//
//  Created by Amay on 7/22/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    ActionViewBatchEditingView,
    ActionViewBatchMoreFunctionsView,
} ActionViewType;

@protocol ActionsViewDelegate <NSObject>

-(void)actionButtonTapped:(NSInteger)buttonTag;  // the most left button tag is 81, and its nearest right button is 82, and so on

@end
@interface ActionsView : UIView

@property(nonatomic)ActionViewType type;
@property(weak,nonatomic)id <ActionsViewDelegate>delegate;

@end
