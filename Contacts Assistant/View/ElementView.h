//
//  ElementView.h
//  Contacts Assistant
//
//  Created by Amay on 7/18/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum : NSUInteger {
    ElementViewTypeOwner=0,
    ElementViewTypeTag,
    ElementViewTypeContact,
} ElementViewType;

@interface ElementView : UIView

@property(copy,nonatomic)NSString *elementName;
@property(strong,nonatomic)UIImage *elementImage;
@property(nonatomic) BOOL isChosen;

@property(nonatomic)ElementViewType elementViewType;

-(instancetype)initWithElementType:(ElementViewType)elementViewType elementName:(NSString *)name;

@end
