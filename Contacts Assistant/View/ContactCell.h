//
//  ContactView.h
//  Contacts Assistant
//
//  Created by Amay on 7/17/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ElementView.h"

@interface ContactCell : UITableViewCell

@property(copy,nonatomic)NSString *contactName;
@property(strong,nonatomic)UIImage *contactImage;


-(CGSize)suggestedSize;

@end
