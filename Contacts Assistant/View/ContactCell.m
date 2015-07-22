//
//  ContactView.m
//  Contacts Assistant
//
//  Created by Amay on 7/17/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ContactCell.h"

@interface ContactCell()

@property(strong,nonatomic)UIImage *defaultBKGImage;

@end

@implementation ContactCell
#pragma mark - properties

-(UIImage *)defaultBKGImage{
    return [UIImage imageNamed:@"DefaultContactImage"];
}

-(void)setContactName:(NSString *)contactName{
    _contactName=contactName;
    [self setNeedsDisplay];
}
-(void)setContactImage:(UIImage *)contactImage{
    _contactImage=contactImage;
    [self setNeedsDisplay];
}

-(CGSize)suggestedSize{
    return CGSizeMake(44, 44);
}
#pragma mark - draw
static CGFloat const DefaultHeight=44;
static CGFloat const DefaultFontSize=10;
static CGFloat const SpaceBetweenImageAndContactName=4;

- (void)drawRect:(CGRect)rect {

    //calculate Geometry Info
    CGFloat height=CGRectGetHeight(rect);
    CGFloat width=CGRectGetWidth(rect);
    CGFloat minSide=MIN(height, width);
    CGFloat fontSize=DefaultFontSize * (minSide/DefaultHeight);
    NSAttributedString *attributedTagName=[[NSAttributedString alloc] initWithString:self.contactName
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize weight:UIFontWeightLight],NSForegroundColorAttributeName:[UIColor darkGrayColor]}];

    CGFloat maxImageHeight = height-attributedTagName.size.height-SpaceBetweenImageAndContactName;
    CGFloat imageWidthAndHeight= maxImageHeight<= width ? maxImageHeight : width;
    CGFloat wholeHeightOfImageAndName=imageWidthAndHeight+SpaceBetweenImageAndContactName+attributedTagName.size.height;

    CGRect maxImageRect=CGRectMake(width/2-imageWidthAndHeight/2, height/2-wholeHeightOfImageAndName/2, imageWidthAndHeight, imageWidthAndHeight);
    CGRect contactNameRect=CGRectMake(width/2-attributedTagName.size.width/2, CGRectGetMaxY(maxImageRect)+SpaceBetweenImageAndContactName, width, attributedTagName.size.height);

    //draw contactName
    [attributedTagName drawInRect:contactNameRect];

    //draw image
    UIBezierPath *circleBorder=[UIBezierPath bezierPathWithOvalInRect:CGRectInset(maxImageRect, 2, 2)];
    circleBorder.lineWidth=1.5;
    [[UIColor lightGrayColor] setStroke];
    [[UIColor whiteColor] setFill];
    [circleBorder stroke];
    [circleBorder fill];
    [circleBorder addClip];
    [self.contactImage ? self.contactImage : self.defaultBKGImage drawInRect:maxImageRect];
}


@end
