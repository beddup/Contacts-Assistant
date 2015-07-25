//
//  EmailReceiversView.h
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmailReceiversView : UIView

@property(copy)void (^cancelEmailHandler)();

-(void)addContactAtIndex:(NSInteger)index withName:(NSString *)name andEmails:(NSArray *)numbers;
-(void)removeContactAtIndex:(NSInteger)index;


@end
