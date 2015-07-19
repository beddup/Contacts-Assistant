//
//  TagView.m
//  Contacts Assistant
//
//  Created by Amay on 7/17/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "TagView.h"
@interface TagView ()

@property(strong,nonatomic)UIImage *bkgImageUnchosen;
@property(strong,nonatomic)UIImage *bkgImageChosen;

@end


@implementation TagView

#pragma mark - Properties
-(UIImage *)bkgImageChosen{
    if (!_bkgImageChosen) {
        _bkgImageChosen=[[UIImage imageNamed:@"TagViewChosenBKG"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 16)
                                                                                 resizingMode:UIImageResizingModeStretch];
    }
    return _bkgImageChosen;
}
-(UIImage *)bkgImageUnchosen{
    if (!_bkgImageUnchosen) {
        _bkgImageUnchosen=[[UIImage imageNamed:@"TagViewUnchosenBKG"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 16)
                                                                                    resizingMode:UIImageResizingModeStretch];
    }
    return _bkgImageUnchosen;
}
-(void)setIsChosen:(BOOL)isChosen{
    _isChosen=isChosen;
    [self setNeedsDisplay];
}

-(void)setTagName:(NSString *)tagName{
    _tagName=tagName;
    [self setNeedsDisplay];
}

-(CGSize)suggestedSize{
    // may lazy
    NSAttributedString *string=[[NSAttributedString alloc] initWithString:self.tagName
                                                               attributes:@{NSFontAttributeName:[UIFont systemFontOfSize: 13 weight:UIFontWeightLight]}];
    return CGSizeMake(string.size.width*1.2+16, 44);
}
#pragma mark - Draw
static CGFloat const DefaultHeight=44;
static CGFloat const DefaultFontSize=13;

- (void)drawRect:(CGRect)rect {

    // draw image
    [self.isChosen ? self.bkgImageChosen:self.bkgImageUnchosen drawInRect:rect];

    // draw string
    CGFloat fontSize= DefaultFontSize * (CGRectGetHeight(rect)/DefaultHeight);

    NSAttributedString *attributedTagName=[[NSAttributedString alloc] initWithString:self.tagName
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize: fontSize weight:UIFontWeightLight],NSForegroundColorAttributeName:[UIColor whiteColor]}];
    CGFloat width=CGRectGetWidth(rect);
    CGFloat height=CGRectGetHeight(rect);
    CGRect tagNameRect=CGRectMake(4, height/2-attributedTagName.size.height/2, width-16, attributedTagName.size.height);
    [attributedTagName drawInRect:tagNameRect];

}

@end
