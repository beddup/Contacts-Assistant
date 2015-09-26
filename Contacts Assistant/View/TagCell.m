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

@property(strong,nonatomic)UIImage *tagBKGImage;

@property(strong,nonatomic)NSAttributedString *tagName;
@property(strong,nonatomic)NSAttributedString *countString;

@property(weak,nonatomic)UIButton *closeButton;
@property(nonatomic)CGFloat widthOfBKGImageView;
@end

@implementation TagCell

#pragma mark - Properties
-(NSParagraphStyle *)psWithAlignment:(NSTextAlignment)alignment{
    NSMutableParagraphStyle *ps=[[NSMutableParagraphStyle alloc]init];
    ps.alignment=alignment;
    ps.lineBreakMode=NSLineBreakByTruncatingTail;
    return ps;
}
-(void)setMyTag:(Tag *)myTag{

    _myTag=myTag;
    self.tagName=[[NSAttributedString alloc]initWithString:self.myTag.tagName ? self.myTag.tagName : @""
                                                attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont systemFontOfSize:15],NSParagraphStyleAttributeName:[self psWithAlignment:NSTextAlignmentLeft]}];
    self.countString=[[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@ 位联系人",@(self.myTag.ownedContacts.count)]
                                                    attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor],NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightLight],NSParagraphStyleAttributeName:[self psWithAlignment:NSTextAlignmentRight]}];
    self.widthOfBKGImageView=[self calculateWidthOfBKGImageView];

    [self setNeedsDisplay];

}

-(void)setHasCloseButton:(BOOL)hasCloseButton{
    _hasCloseButton=hasCloseButton;
    self.widthOfBKGImageView=[self calculateWidthOfBKGImageView];

    [self setNeedsDisplay];

}

-(UIImage *)tagBKGImageSelected{
    return  [[UIImage imageNamed:@"TagViewSelectedBKG"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, TagBKGImageCapInsetRight) resizingMode:UIImageResizingModeStretch];
}

-(UIImage *)tagBKGImageUnselected{
    return  [[UIImage imageNamed:@"TagViewUnSelectedBKG"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, TagBKGImageCapInsetRight) resizingMode:UIImageResizingModeStretch];
}

static CGFloat TagBKGImageCapInsetRight =16.0;
static CGFloat HSpace=8;
static CGFloat ButtonWidth = 44.0;
static CGFloat CountLabelWidth = 80.0;

-(CGFloat)calculateWidthOfBKGImageView{

    CGFloat BKGImageViewTrailing=0;
    if (self.hasCloseButton) {
        BKGImageViewTrailing=ButtonWidth+HSpace;
    }else if (self.accessoryType != UITableViewCellAccessoryNone){
        BKGImageViewTrailing=ButtonWidth/2+HSpace+CountLabelWidth;
    }
    else{
        BKGImageViewTrailing=self.separatorInset.right+CountLabelWidth+HSpace;
    }
    CGFloat availableWidth=CGRectGetWidth(self.contentView.frame)-self.separatorInset.left-BKGImageViewTrailing;
    CGFloat fullyDisplayedBKGWidth= self.tagName.size.width + 20  +TagBKGImageCapInsetRight;
    return  fullyDisplayedBKGWidth > availableWidth ? availableWidth : fullyDisplayedBKGWidth;

}
#pragma mark - draw
-(void)drawRect:(CGRect)rect{

    CGRect BKGImageRect=CGRectMake(self.separatorInset.left, CGRectGetHeight(rect)/6, self.widthOfBKGImageView, CGRectGetHeight(rect)*2/3);

    [self.tagBKGImage drawInRect:BKGImageRect];

    CGRect tagNameRect=CGRectMake(CGRectGetMinX(BKGImageRect)+HSpace, CGRectGetMidY(rect)-self.tagName.size.height/2, CGRectGetWidth(BKGImageRect)-TagBKGImageCapInsetRight-HSpace, self.tagName.size.height);
    [self.tagName drawAtPoint:tagNameRect.origin];

    if (self.hasCloseButton) {
        // no accessory
        self.closeButton.frame = CGRectMake(CGRectGetWidth(rect)-ButtonWidth, CGRectGetMinY(rect), ButtonWidth, CGRectGetHeight(rect));
    }else{
        CGFloat countLabelTrailing=self.separatorInset.right;
        if (self.accessoryType != UITableViewCellAccessoryNone) {
            countLabelTrailing=ButtonWidth/2+HSpace;
        }
        CGRect countStringRect=CGRectMake(CGRectGetWidth(rect)-CountLabelWidth-countLabelTrailing, CGRectGetMidY(rect)-self.countString.size.height/2, CountLabelWidth, self.countString.size.height);
        [self.countString drawAtPoint:countStringRect.origin];
    }

}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];

    self.tagBKGImage= selected && !self.hasCloseButton ? [self tagBKGImageSelected] : [self tagBKGImageUnselected];
    [self setNeedsDisplay];

}

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.tagBKGImage=[self tagBKGImageUnselected];

    UIButton * closeButton=[[UIButton alloc]init];
    [closeButton setBackgroundImage:[UIImage imageNamed:@"removeTagIcon"] forState:UIControlStateNormal];
    [self addSubview:closeButton];
    self.closeButton=closeButton;
    [closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

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
