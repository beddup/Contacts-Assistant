//
//  RelationsView.m
//  Contacts Assistant
//
//  Created by Amay on 8/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "RelationsView.h"
#import "Contact+Utility.h"
#import "Relation.h"
@interface RelationViewGrid:NSObject

@property(nonatomic)CGPoint center;
@property(nonatomic)NSInteger numberOfContentGrids; //exclude the center grid
@property(readonly,nonatomic)CGSize size;
@property(readonly,nonatomic)NSInteger rowsCount;

-(instancetype)initWithMaxGridSideLength:(CGFloat)maxGridSideLength
                       minGridSideLength:(CGFloat) minGridSideLength;
-(CGRect)rectOfGrid:(NSInteger)index;
-(CGRect)rectofCenterGrid;
@end

@interface RelationViewGrid ()

@property(nonatomic)CGFloat maxGridSideLength;
@property(nonatomic)CGFloat minGridSideLength;

@property(strong,nonatomic)NSMutableArray *columnsWidths;
@property(strong,nonatomic)NSMutableArray *rowsHeights;

@property(readwrite,nonatomic)CGSize size;
@property(readwrite,nonatomic)NSInteger rowsCount;


@end
@implementation RelationViewGrid
#pragma mark - public API
-(instancetype)initWithMaxGridSideLength:(CGFloat)maxGridSideLength
                       minGridSideLength:(CGFloat)minGridSideLength{
    self= [super init];
    if (self) {
        _maxGridSideLength=MAX(maxGridSideLength, minGridSideLength);
        _minGridSideLength=MIN(maxGridSideLength, minGridSideLength);
    }
    return self;
}
-(CGRect)rectofCenterGrid{

    NSInteger index=self.rowsHeights.count/2;
    CGFloat width= [self.columnsWidths[index] floatValue];
    CGFloat height=[self.rowsHeights[index] floatValue];

    return CGRectMake(self.center.x-width/2, self.center.y-height/2, width, height);

}

-(CGRect)rectOfGrid:(NSInteger)index{
    // left up corner index is 0 , right down corner is max one

    NSInteger gridRow=index/self.columnsWidths.count;
    NSInteger gridColumn=index % self.rowsHeights.count;

    CGFloat width= [self.columnsWidths[gridColumn] floatValue];
    CGFloat height=[self.rowsHeights[gridRow] floatValue];

    CGRect centerGrid=[self rectofCenterGrid];

    NSInteger rowOfCenterGrid=self.rowsHeights.count/2;
    int row = rowOfCenterGrid;
    CGFloat y= CGRectGetMinY(centerGrid);
    do {
        if (rowOfCenterGrid > gridRow) {
            row--;
            y-=[self.rowsHeights[row] floatValue];
        }else if (rowOfCenterGrid < gridRow){
            y+=[self.rowsHeights[row] floatValue];
            row++;
        }else{
            break;
        }
    } while (row != gridRow);

    NSInteger columnOfCenterGrid=self.columnsWidths.count/2;
    int column = columnOfCenterGrid;
    CGFloat x= CGRectGetMinX(centerGrid);
    do {
        if (columnOfCenterGrid > gridColumn) {
            column--;
            x-=[self.columnsWidths[column] floatValue];
        }else if (columnOfCenterGrid < gridColumn){
            x+=[self.columnsWidths[column] floatValue];
            column++;
        }else{
            break;
        }
    } while (column != gridColumn);

    return CGRectMake(x, y, width, height);

}

-(void)setNumberOfContentGrids:(NSInteger)numberOfContentGrids{

    _numberOfContentGrids=numberOfContentGrids;
    [self reCalculate];

}

-(void)reCalculate{
    NSInteger rowsCount=MAX(3,(int)sqrtf(self.numberOfContentGrids));
    if (rowsCount * rowsCount < self.numberOfContentGrids) {
        rowsCount++;
    }
    if (rowsCount%2 == 0) {
        rowsCount ++;
    }
    self.rowsCount=rowsCount;
    int delta = (int)(self.maxGridSideLength-self.minGridSideLength);

    self.rowsHeights=[@[] mutableCopy];
    self.columnsWidths=[@[] mutableCopy];

    //calculate the widths and heights
    CGFloat totalWidth=0;
    CGFloat totalHeight=0;

    for (int index=0 ; index<rowsCount; index++) {

        int randomNumber1= arc4random()%delta;
        CGFloat width=randomNumber1 + self.minGridSideLength;
        [self.columnsWidths addObject:@(width)];
        totalWidth+=width;

        int randomNumber2=arc4random()%delta;
        CGFloat height=randomNumber2 + self.minGridSideLength;
        [self.rowsHeights addObject:@(height)];
        totalHeight+=height;
    }
    self.size=CGSizeMake(totalWidth, totalHeight);
}

@end

//-------------------
@interface RelationsView ()

@property(strong,nonatomic)RelationViewGrid *grid;
@property(strong,nonatomic)NSMutableArray *contactButtons;
//@property(strong,nonatomic)NSArray *relations;
@property(strong,nonatomic)NSMutableOrderedSet *otherContacts;
@property(strong,nonatomic)NSMutableArray *relationStrings;

@property(strong,nonatomic)NSMutableArray *relationViewsideLengths;
@property(strong,nonatomic)NSMutableArray *relationViewsCenterXs;
@property(strong,nonatomic)NSMutableArray *relationViewsCenterYs;

@end
@implementation RelationsView

-(void)setContact:(Contact *)contact{

    _contact=contact;
    [self updateRelationViews];
}
-(void)updateRelationViews{

    self.otherContacts=[NSMutableOrderedSet orderedSet];
    self.relationStrings=[@[] mutableCopy];
    for (Relation *relation in self.contact.relationsWithOtherPeople) {
        if (![self.otherContacts containsObject:relation.otherContact]) {
            [self.otherContacts addObject:relation.otherContact];
            [self.relationStrings addObject:relation.relationName];
        }else{
            NSInteger index = [self.otherContacts indexOfObject:relation.otherContact];
            NSString *relationString=self.relationStrings[index];
            self.relationStrings[index]=[NSString stringWithFormat:@"%@,%@",relationString,relation.relationName];
        }
    }

    self.grid.numberOfContentGrids=self.otherContacts.count + 2; // include the same tag and contact itself relation

    [self calculateGeomtry];
    [self updateRelationGraph];

}
-(void)calculateGeomtry{

    self.grid.center=CGPointMake(self.grid.size.width/2, self.grid.size.height/2);
    self.bounds=CGRectMake(0, 0, self.grid.size.width, self.grid.size.height);

    self.relationViewsCenterXs=[@[] mutableCopy];
    self.relationViewsCenterYs=[@[] mutableCopy];
    self.relationViewsideLengths=[@[] mutableCopy];

    for (int i =0 ; i<self.grid.numberOfContentGrids; i++) {

        CGRect containRect=[self.grid rectOfGrid:i];

        CGFloat viewSide=MIN(CGRectGetWidth(containRect)-24, CGRectGetHeight(containRect)-24);
        [self.relationViewsideLengths addObject:@(viewSide)];

        CGFloat viewMaxXOffset=CGRectGetWidth(containRect)-viewSide;
        CGFloat viewMaxYOffset=CGRectGetHeight(containRect)-viewSide;
        CGFloat viewXOffset=arc4random()%((int)viewMaxXOffset);
        CGFloat viewYOffset=arc4random()%((int)viewMaxYOffset);

        [self.relationViewsCenterXs addObject:@(CGRectGetMinX(containRect)+viewXOffset+viewSide/2)];
        [self.relationViewsCenterYs addObject:@(CGRectGetMinY(containRect)+viewYOffset+viewSide/2)];
    }

}
-(void)updateRelationGraph{

    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSInteger centerGridIndex=(self.grid.rowsCount * self.grid.rowsCount)/2;

    for (int index =0 ; index<self.grid.numberOfContentGrids; index++) {
        if (index == self.grid.numberOfContentGrids-1 && index<centerGridIndex) {
            break;
        }
        UIView *view=[self viewForGrid:index];
        [self addSubview:view];
    }
    [self setNeedsDisplay];

}
-(UIView *)viewForGrid:(NSInteger)index{

    NSInteger centerGridIndex=(self.grid.rowsCount * self.grid.rowsCount)/2;

    if (index==centerGridIndex) {
        return nil;
    }

    CGFloat sideLength=[self.relationViewsideLengths[index] floatValue];
    CGFloat centerX=[self.relationViewsCenterXs[index] floatValue];
    CGFloat centerY=[self.relationViewsCenterYs[index] floatValue];

    // get relation info
    NSInteger relationInfoIndex= index < centerGridIndex ? index : index-1;
    Contact *contact= relationInfoIndex < self.otherContacts.count ? self.otherContacts[relationInfoIndex] : nil;
    NSString *relationName= relationInfoIndex < self.otherContacts.count ? self.relationStrings[relationInfoIndex] : nil;

    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(centerX-sideLength/2,centerY-sideLength/2,sideLength,sideLength)];
    view.backgroundColor=[UIColor whiteColor];
    view.layer.cornerRadius=sideLength/2;
    view.layer.borderColor=[[UIColor lightGrayColor] CGColor];
    view.layer.borderWidth=1.0;

    UIButton *button=[[UIButton alloc]initWithFrame:view.bounds];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitle:contact ? contact.contactName:@"同标签下\n联系人"
            forState:UIControlStateNormal];
    button.tag=[contact.contactID integerValue];
    button.titleLabel.font=[UIFont systemFontOfSize:15];
    button.titleLabel.numberOfLines=2;
    button.titleLabel.textAlignment=NSTextAlignmentCenter;
    [view addSubview:button];
    [button addTarget:self
               action:contact ?@selector(relationSelected:):@selector(sameTagContactsSelected:)
     forControlEvents:UIControlEventTouchUpInside];

    if (relationName) {
        CGRect relationLabelRect= CGRectMake(0, sideLength/2, sideLength, sideLength/2);
        UILabel *relationLabel=[[UILabel alloc]initWithFrame:relationLabelRect];
        relationLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        relationLabel.textAlignment=NSTextAlignmentCenter;
        relationLabel.text=relationName;
        relationLabel.numberOfLines=2;
        relationLabel.textColor=[UIColor lightGrayColor];
        [view addSubview:relationLabel];
    }

    return view;

}
-(void)relationSelected:(UIButton *)button{

    Contact *otherContact= [Contact contactOfContactID:button.tag];
    self.relationSelected(self.contact,otherContact);
}

-(void)relationDeleted:(Relation *)relation{

    Contact *otherContact=relation.otherContact;
    NSInteger index=[self.otherContacts indexOfObject:otherContact];
    NSString *relationString=self.relationStrings[index];
    if ([relationString isEqualToString:relation.relationName]) {
//        [self.otherContacts removeObjectAtIndex:index];
//        [self.relationStrings removeObjectAtIndex:index];
//        self.grid.numberOfContentGrids=self.otherContacts.count+2;
        [self updateRelationViews];
    }else{
        NSMutableArray *stringArray=[[relationString componentsSeparatedByString:@","]mutableCopy];
        [stringArray removeObject:relation.relationName];
        if (stringArray.count) {
            self.relationStrings[index]=[stringArray componentsJoinedByString:@","];
        }else{
//            [self.otherContacts removeObjectAtIndex:index];
//            [self.relationStrings removeObjectAtIndex:index];
//            self.grid.numberOfContentGrids=self.otherContacts.count+2;
            [self updateRelationViews];
        }
    }
    [self updateRelationGraph];
}

-(void)sameTagContactsSelected:(UIButton *)button{
    self.sameTagContactsSelected(self.contact);
}
-(NSMutableArray *)contactButtons{
    if (!_contactButtons) {
        _contactButtons=[@[] mutableCopy];
    }
    return _contactButtons;
}

-(void)drawRect:(CGRect)rect{
    // draw center grid
    CGPoint center=CGPointMake(CGRectGetMinX(rect)+CGRectGetWidth(rect)/2, CGRectGetMinY(rect)+CGRectGetHeight(rect)/2);
    self.grid.center=center;


    //draw line
    [[UIColor lightGrayColor] setStroke];

    NSInteger centerGridIndex=(self.grid.rowsCount * self.grid.rowsCount)/2;
    for (int index=0 ; index<self.grid.numberOfContentGrids; index++) {
        if (index == self.grid.numberOfContentGrids-1 && index<centerGridIndex) {
            break;
        }
        CGPoint theCenter=CGPointMake([self.relationViewsCenterXs[index] floatValue],[self.relationViewsCenterYs[index] floatValue]);
        UIBezierPath *line=[UIBezierPath bezierPath];
        [line moveToPoint:center];
        [line addLineToPoint:theCenter];
        [line stroke];
    }

    CGRect centerGridRect=[self.grid rectofCenterGrid];
    CGFloat centerGridSideLength=MIN(CGRectGetWidth(centerGridRect), CGRectGetHeight(centerGridRect))-20;
    CGRect contentRect=CGRectMake(center.x-centerGridSideLength/2, center.y-centerGridSideLength/2, centerGridSideLength, centerGridSideLength);
    UIBezierPath *circle=[UIBezierPath bezierPathWithOvalInRect:contentRect];
    [[UIColor orangeColor] setFill];
    [circle fill];

    NSMutableParagraphStyle *ps=[[NSMutableParagraphStyle alloc]init];
    ps.alignment=NSTextAlignmentCenter;
    ps.lineBreakMode=NSLineBreakByTruncatingTail;
    NSAttributedString *centerContactName=[[NSAttributedString alloc]initWithString:self.contact.contactName attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont systemFontOfSize:15],NSParagraphStyleAttributeName:ps}];
    [centerContactName drawInRect:CGRectMake(CGRectGetMinX(contentRect), CGRectGetMidY(contentRect)-centerContactName.size.height/2, CGRectGetWidth(contentRect), 20)];

}

#pragma  mark - setup

static CGFloat const DefaultMaxGridSideLength = 150.0;
static CGFloat const DefaultMinGridSideLength = 100.0;

-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.backgroundColor=[UIColor clearColor];
    self.grid=[[RelationViewGrid alloc]initWithMaxGridSideLength:DefaultMaxGridSideLength
                                               minGridSideLength:DefaultMinGridSideLength];

}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

@end
