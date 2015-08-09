//
//  TagView.m
//  Contacts Assistant
//
//  Created by Amay on 7/17/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "TagCell.h"
#import "Tag+Utility.h"
@interface TagCell ()

@property(weak,nonatomic)UIImageView *BKGImageView;
@property(strong,nonatomic)UIImage *tagBKGImageUnselected;
@property(strong,nonatomic)UIImage *tagBKGImageSelected;
@property(weak,nonatomic)UILabel *tagNameLabel;
@property(weak,nonatomic)UILabel *contactsCountLable;

@property(weak,nonatomic)UIButton *closeButton;

@end


@implementation TagCell

#pragma mark - Properties

-(void)setMyTag:(Tag *)myTag{

    _myTag=myTag;
    self.tagNameLabel.text=myTag.tagName;
    self.contactsCountLable.text= [NSString stringWithFormat:@"%@ 位联系人",@([myTag numberOfAllOwnedContacts])];
    [self layoutIfNeeded];

}
-(UIImage *)tagBKGImageSelected{
    if (!_tagBKGImageSelected) {
        _tagBKGImageSelected=[[UIImage imageNamed:@"TagViewSelectedBKG"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, TagBKGImageCapInsetRight) resizingMode:UIImageResizingModeStretch];
    }
    return _tagBKGImageSelected;
}
-(UIImage *)tagBKGImageUnselected{
    if (!_tagBKGImageUnselected) {
        _tagBKGImageUnselected=[[UIImage imageNamed:@"TagViewUnSelectedBKG"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, TagBKGImageCapInsetRight) resizingMode:UIImageResizingModeStretch];
    }
    return _tagBKGImageUnselected;
}

static CGFloat TagBKGImageCapInsetRight =16.0;

-(CGFloat )widthOfBKGImageView{

    CGFloat closeButtonWidth=self.hasCloseButton ? 44 : 64 ;
    CGFloat availableWidth=CGRectGetWidth(self.contentView.frame)-self.separatorInset.left-self.separatorInset.right-closeButtonWidth-12;
    CGFloat fullyDisplayedBKGWidth= self.tagNameLabel.attributedText.size.width + 20  +TagBKGImageCapInsetRight;
    return  fullyDisplayedBKGWidth > availableWidth ? availableWidth : fullyDisplayedBKGWidth;

}

-(void)layoutSubviews{

    CGRect rect=self.bounds;

    if (self.hasCloseButton) {
        self.closeButton.frame = CGRectMake(CGRectGetWidth(rect)-44, CGRectGetMinY(rect), 44, CGRectGetHeight(rect));
    }else{
        self.contactsCountLable.frame=CGRectMake(CGRectGetWidth(rect)-80-self.separatorInset.right, CGRectGetMinY(rect), 80, CGRectGetHeight(rect));
    }

    self.BKGImageView.frame = CGRectMake(self.separatorInset.left, CGRectGetHeight(rect)/6, [self widthOfBKGImageView], CGRectGetHeight(rect)*2/3);

    self.tagNameLabel.frame = CGRectInset(self.BKGImageView.frame,16, 0);
    self.tagNameLabel.frame = CGRectOffset(self.tagNameLabel.frame, -4, 0);


}


-(void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];
    self.BKGImageView.image= selected && !self.hasCloseButton ? [self tagBKGImageSelected] : [self tagBKGImageUnselected];
}

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{


    UIImageView *imageView=[[UIImageView alloc]initWithImage:self.tagBKGImageUnselected];
    [self.contentView addSubview:imageView];
    self.BKGImageView=imageView;

    UILabel *label=[[UILabel alloc]init];
    label.textColor=[UIColor whiteColor];
    label.font=[UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    label.textAlignment=NSTextAlignmentLeft;
    label.lineBreakMode=NSLineBreakByTruncatingTail;
    [self.contentView addSubview:label];
    self.tagNameLabel=label;

    UILabel *countLabel=[[UILabel alloc]init];
    countLabel.textColor=[UIColor lightGrayColor];
    countLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightLight];
    countLabel.textAlignment=NSTextAlignmentRight;
    [self.contentView addSubview:countLabel];
    self.contactsCountLable=countLabel;


    UIButton * button=[[UIButton alloc]init];
    [button setBackgroundImage:[UIImage imageNamed:@"removeTagIcon"] forState:UIControlStateNormal];
    [self.contentView addSubview:button];
    self.closeButton=button;
    [button addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];


}
-(void)closeButtonTapped:(UIButton *)button{

    self.closeButtonTapped(self.myTag);


}
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

@end
