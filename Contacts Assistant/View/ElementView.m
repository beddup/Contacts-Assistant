//
//  ElementView.m
//  Contacts Assistant
//
//  Created by Amay on 7/18/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ElementView.h"
#import "TagView.h"
#import "ContactView.h"
@interface ElementView()

@property(weak,nonatomic)UIView *contentView;
@property(nonatomic)CGPoint contentViewOffset;


@end


@implementation ElementView

-(void)setElementName:(NSString *)elementName{
    _elementName=elementName;
    [self.contentView setNeedsDisplay];
}

-(void)setIsChosen:(BOOL)isChosen{
    _isChosen=isChosen;
    [self setNeedsDisplay];
}

-(void)setElementImage:(UIImage *)elementImage{
    _elementImage=elementImage;
    [self.contentView setNeedsDisplay];
}

-(CGSize)suggestedSize{
    return CGSizeZero;
}

-(instancetype)initWithElementType:(ElementViewType)elementViewType elementName:(NSString *)name{
    self=[super initWithFrame:CGRectZero];
    if (self) {
        [self setup];
        _elementViewType=elementViewType;
        _elementName=name;
        UIView *contentView;
        switch (elementViewType) {
            case ElementViewTypeContact:{
                contentView=[[ContactView alloc]initWithFrame:CGRectZero];
                break;
            }
            case ElementViewTypeOwner:{
                contentView=[[TagView alloc]initWithFrame:CGRectZero];
                break;
            }
            default:
                contentView=[[TagView alloc]initWithFrame:CGRectZero];
        }

        [self addSubview:contentView];
        self.contentView=contentView;
    }
    return  self;

}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
static CGFloat const LineLength = 40;
static CGFloat const ContentHeight = 44;
static CGFloat const SpaceBetweenContentAndAction = 20;
static CGFloat const DistanceFromActionXToRight = 27; //space between actio and right=6, action width=21;

- (void)drawRect:(CGRect)rect {

    CGContextRef context= UIGraphicsGetCurrentContext();

    CGFloat width=CGRectGetWidth(rect);
    CGFloat height=CGRectGetHeight(rect);

    // draw line
    UIBezierPath *linePath=[UIBezierPath bezierPath];
    [linePath moveToPoint:CGPointMake(0,height/2)];
    [linePath addLineToPoint:CGPointMake(LineLength+self.contentViewOffset.x, height/2)];

    //calculate the content view geometry

    CGFloat MAXContentWidth=width-LineLength-SpaceBetweenContentAndAction-DistanceFromActionXToRight;
    CGFloat contentWidth = MAXContentWidth;
    CGRect frame=CGRectMake(LineLength, CGRectGetHeight(rect)/2-ContentHeight, contentWidth, ContentHeight);
    self.contentView.frame=CGRectOffset(frame, self.contentViewOffset.x, 0);

    if (!self.contentViewOffset.x) {
        return;
    }

    //draw action
    CGRect actionPart1Rect=CGRectMake(CGRectGetMaxX(self.contentView.frame)+SpaceBetweenContentAndAction, CGRectGetMinY(self.contentView.frame), 5, CGRectGetHeight(self.contentView.frame));
    UIBezierPath *actionPart1=[UIBezierPath bezierPathWithRoundedRect:actionPart1Rect cornerRadius:1.0];
    UIColor *fillColor=[UIColor colorWithRed:0 green:0 blue:1 alpha:self.contentViewOffset.x/SpaceBetweenContentAndAction];
    [fillColor setFill];
    [actionPart1 fill];

    UIBezierPath *actionPart2=[actionPart1 copy];
    [actionPart2 applyTransform:CGAffineTransformMakeTranslation(8, 0)];

    UIBezierPath *actionPart3=[actionPart2 copy];
    [actionPart3 applyTransform:CGAffineTransformMakeTranslation(8, 0)];

    CGContextRestoreGState(context);
}

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{
    self.backgroundColor=[UIColor clearColor];
}

-(instancetype)initWithFrame:(CGRect)frame{
    return [self initWithElementType:ElementViewTypeTag elementName:@"Unknown"];
}

@end
