//
//  TagView.m
//  Contacts Assistant
//
//  Created by Amay on 7/17/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "TagCell.h"
@interface TagCell ()

@property(weak,nonatomic)UIImageView *BKGImageView;
@property(strong,nonatomic)UIImage *tagBKGImageUnselected;
@property(strong,nonatomic)UIImage *tagBKGImageSelected;
@property(weak,nonatomic)UILabel *tagNameLabel;

@end


@implementation TagCell

#pragma mark - Properties

-(void)setTagName:(NSString *)tagName{
    self.tagNameLabel.text=tagName;
    [self setNeedsDisplay];
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

    CGFloat fullyDisplayedBKGWidth= self.tagNameLabel.attributedText.size.width *1.2 +TagBKGImageCapInsetRight;
    return  fullyDisplayedBKGWidth > CGRectGetWidth(self.bounds)-self.separatorInset.left ? CGRectGetWidth(self.bounds)-self.separatorInset.left : fullyDisplayedBKGWidth;

}

- (void)drawRect:(CGRect)rect {

    self.BKGImageView.frame=CGRectMake(self.separatorInset.left, CGRectGetHeight(rect)/2-36/2, [self widthOfBKGImageView], 36);
    self.tagNameLabel.frame=CGRectOffset(self.BKGImageView.frame, 4, 0);

}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];
    self.BKGImageView.image= selected ? [self tagBKGImageSelected] : [self tagBKGImageUnselected];
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
    [self.contentView addSubview:label];
    self.tagNameLabel=label;


}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

@end
