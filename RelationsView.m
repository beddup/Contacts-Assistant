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
#import "defines.h"
@interface RelationViewGrid:NSObject

@property(nonatomic)NSInteger centerGridIndex;

@property(nonatomic)NSInteger numberOfContentGrids; //exclude the center grid
@property(readonly,nonatomic)CGSize size;
@property(readonly,nonatomic)NSInteger rowsCount;
@property(readonly,nonatomic)NSInteger columnCount;



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
@property(readwrite,nonatomic)NSInteger columnCount;


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
-(void)setNumberOfContentGrids:(NSInteger)numberOfContentGrids{

    _numberOfContentGrids=numberOfContentGrids;
    [self reCalculate];
    
}

-(void)reCalculate{

    self.rowsCount=MAX(3, (int)sqrtf(self.numberOfContentGrids)+1);
    self.columnCount=MAX((int)(self.numberOfContentGrids/self.rowsCount)+1,3);

    int delta = (int)(self.maxGridSideLength-self.minGridSideLength);

    self.rowsHeights=[@[] mutableCopy];
    self.columnsWidths=[@[] mutableCopy];

    //calculate the widths and heights
    CGFloat totalWidth=0;
    CGFloat totalHeight=0;

    for (int rowIndex=0 ; rowIndex<self.rowsCount; rowIndex++) {

        int randomNumber1= arc4random()%delta;
        CGFloat height=randomNumber1 + self.minGridSideLength;
        [self.rowsHeights addObject:@(height)];
        totalHeight+=height;
    }
    for (int columnIndex=0; columnIndex<self.columnCount;columnIndex++) {
        int randomNumber2=arc4random()%delta;
        CGFloat width=randomNumber2 + self.minGridSideLength;
        [self.columnsWidths addObject:@(width)];
        totalWidth+=width;
    }

    self.size=CGSizeMake(totalWidth, totalHeight);
    self.centerGridIndex=self.rowsCount/2*self.columnCount+self.columnCount/2;
}

-(CGRect)rectofCenterGrid{

    return [self rectOfGrid:self.centerGridIndex];

}

-(CGFloat)minXofColumn:(NSInteger)column{
    if (column == 0) {
        return 0;
    }
    return [self minXofColumn:column-1]+[self.columnsWidths[column-1] floatValue];
}
-(CGFloat)minYofRow:(NSInteger)row{
    if (row == 0) {
        return 0;
    }
    return [self minYofRow:row-1]+[self.rowsHeights[row-1] floatValue];
}
-(CGRect)rectOfGrid:(NSInteger)index{
    // left up corner index is 0 , right down corner is max one

    NSInteger rowIndex=index/self.columnCount;
    NSInteger columnIndex=index % self.columnCount;
    CGFloat minY=[self minYofRow:rowIndex];
    CGFloat minX=[self minXofColumn:columnIndex];

    CGFloat width= [self.columnsWidths[columnIndex] floatValue];
    CGFloat height=[self.rowsHeights[rowIndex] floatValue];
    return CGRectMake(minX, minY, width, height);
}


@end

//-------------------
@interface RelationsView ()

@property(strong,nonatomic)RelationViewGrid *grid;

@property(strong,nonatomic)NSMutableArray *relationGridIndexes;// include same tag view

@property(strong,nonatomic)NSMutableArray *allRelations; // The contact's relation and relation it belong to

@property(strong,nonatomic)NSMutableArray *relationViewsideLengths;
@property(strong,nonatomic)NSMutableArray *relationViewsMinXs;
@property(strong,nonatomic)NSMutableArray *relationViewsMinYs;

@end
@implementation RelationsView

-(void)setContact:(Contact *)contact{

    _contact=contact;
    [self update];
}
-(void)update{
    
    self.allRelations=[[self.contact.relationsWithOtherPeople allObjects]mutableCopy];
    [self.allRelations addObjectsFromArray:[self.contact.belongWhichRelations allObjects]];
    [self updateRelationViews];
}
-(void)updateRelationViews{

    self.grid.numberOfContentGrids=self.allRelations.count + 2; // include the same tag and contact itself relation
    [self calculateGeomtry];
    [self updateRelationGraph];

}

-(void)calculateGeomtry{

    self.bounds=CGRectMake(0, 0, self.grid.size.width, self.grid.size.height);

    self.relationViewsMinXs=[@[] mutableCopy];
    self.relationViewsMinYs=[@[] mutableCopy];
    self.relationViewsideLengths=[@[] mutableCopy];

    for (int i =0 ; i<self.grid.rowsCount*self.grid.columnCount; i++) {

        CGRect containRect=[self.grid rectOfGrid:i];

        CGFloat viewSide=MIN(CGRectGetWidth(containRect)-24, CGRectGetHeight(containRect)-24);
        [self.relationViewsideLengths addObject:@(viewSide)];

        CGFloat viewMaxXOffset=CGRectGetWidth(containRect)-viewSide;
        CGFloat viewMaxYOffset=CGRectGetHeight(containRect)-viewSide;
        CGFloat viewXOffset=arc4random()%((int)viewMaxXOffset);
        CGFloat viewYOffset=arc4random()%((int)viewMaxYOffset);

        [self.relationViewsMinXs addObject:@(CGRectGetMinX(containRect)+viewXOffset)];
        [self.relationViewsMinYs addObject:@(CGRectGetMinY(containRect)+viewYOffset)];
    }

    // place the view(relation & same tag view) in a random grid
    NSMutableArray *avaibleRelationGridIndex=[@[] mutableCopy];
    for (int index=0; index<self.grid.rowsCount*self.grid.columnCount; index++) {
        if (index != self.grid.centerGridIndex) {
            [avaibleRelationGridIndex addObject:@(index)];
        }
    }
    self.relationGridIndexes=[@[] mutableCopy];
    for (int index =0 ; index<self.allRelations.count+1; index++) {
        NSInteger gridIndex=arc4random() % avaibleRelationGridIndex.count;
        [self.relationGridIndexes addObject:avaibleRelationGridIndex[gridIndex]];
        [avaibleRelationGridIndex removeObjectAtIndex:gridIndex];
    }



}
-(void)updateRelationGraph{

    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    for (int index =0 ; index<self.allRelations.count+1; index++) {
        UIView *view=[self viewForRelation:index<self.allRelations.count ? self.allRelations[index]:nil
                                    atGrid:[self.relationGridIndexes[index] integerValue]];
        [self addSubview:view];
    }

    [self setNeedsDisplay];

}

-(UIButton *)buttonForContact:(Contact *)contact{
    UIButton *button=[[UIButton alloc]init];
    [button setTitleColor:IconColor forState:UIControlStateNormal];
    [button setTitle:contact ? contact.contactName: @"同标签下\n联系人"
            forState:UIControlStateNormal];
    button.tag=[contact.contactID integerValue];
    button.titleLabel.font=[UIFont systemFontOfSize:15];
    button.titleLabel.numberOfLines=2;
    button.titleLabel.textAlignment=NSTextAlignmentCenter;
    [button addTarget:self
               action:contact ? @selector(relationSelected:):@selector(sameTagContactsSelected:)
     forControlEvents:UIControlEventTouchUpInside];
    return button;

}
-(UIView *)viewForRelation:(Relation *)relation atGrid:(NSInteger)index{

    CGFloat sideLength=[self.relationViewsideLengths[index] floatValue];
    CGFloat minX=[self.relationViewsMinXs[index] floatValue];
    CGFloat minY=[self.relationViewsMinYs[index] floatValue];
    CGRect frame=CGRectMake(minX, minY, sideLength, sideLength);

    UIView *view=[[UIView alloc]initWithFrame:frame];
    view.backgroundColor=[UIColor whiteColor];
    view.layer.cornerRadius=CGRectGetWidth(frame)/2;
    view.layer.borderColor=[IconColor CGColor];
    view.layer.borderWidth=1.0;

    if (!relation) {
        // same tag view
        UIButton *sameTagButton=[self buttonForContact:nil];
        sameTagButton.frame=view.bounds;
        [view addSubview:sameTagButton];
        return view;
    }

    BOOL isMyRelation=[relation.whoseRelation.contactID isEqualToNumber:self.contact.contactID];
    Contact *contact=isMyRelation ? relation.otherContact : relation.whoseRelation;

    UIButton *contactButton=[self buttonForContact:contact];
    contactButton.frame=view.bounds;
    [view addSubview:contactButton];

    UILabel *relationLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, sideLength/2, sideLength, sideLength/2)];
    relationLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightLight];
    relationLabel.textAlignment=NSTextAlignmentCenter;
    relationLabel.text= relation.relationName ;
    relationLabel.numberOfLines=2;
    relationLabel.textColor=isMyRelation ? [UIColor orangeColor] : IconColor;
    relationLabel.text= isMyRelation ? relation.relationName : [@"的 " stringByAppendingString:relation.relationName];
    [view addSubview:relationLabel];

    return view;

}
#pragma mark - actions
-(void)relationSelected:(UIButton *)button{

    Contact *otherContact= [Contact contactOfContactID:(int)button.tag];
    [self.delegate dismissRelationBetween:self.contact otherContact:otherContact];
}

-(void)sameTagContactsSelected:(UIButton *)button{
    [self.delegate showAllContactsWhoHaveSameTagWithContact:self.contact];
}

-(void)relationDeleted:(Relation *)relation{

    [self.allRelations removeObject:relation];
    [self updateRelationViews];

}

#pragma mark -draw
-(void)drawRect:(CGRect)rect{
    //center

    CGFloat sideLength=[self.relationViewsideLengths[self.grid.centerGridIndex] floatValue];
    CGFloat minX=[self.relationViewsMinXs[self.grid.centerGridIndex] floatValue];
    CGFloat minY=[self.relationViewsMinYs[self.grid.centerGridIndex] floatValue];

    // draw center grid
    CGPoint center=CGPointMake(minX+sideLength/2,minY+sideLength/2);

    //draw line
    [[UIColor orangeColor] setStroke];
    for (int index=0 ; index<self.allRelations.count+1; index++) {
        NSInteger gridIndex=[self.relationGridIndexes[index] integerValue];
        CGFloat sideLength=[self.relationViewsideLengths[gridIndex] floatValue];
        CGPoint theCenter=CGPointMake([self.relationViewsMinXs[gridIndex] floatValue]+ sideLength/2,[self.relationViewsMinYs[gridIndex] floatValue]+sideLength/2);
        UIBezierPath *line=[UIBezierPath bezierPath];
        [line moveToPoint:center];
        [line addLineToPoint:theCenter];

        if(index < self.allRelations.count){
            Relation *relation=self.allRelations[index];
            BOOL isMyRelation=[relation.whoseRelation.contactID isEqualToNumber:self.contact.contactID];
            isMyRelation ? [[[UIColor orangeColor] colorWithAlphaComponent:0.5] setStroke]: [[IconColor colorWithAlphaComponent:0.5] setStroke];
        }else{
            [[[UIColor orangeColor] colorWithAlphaComponent:0.5] setStroke];
        }
        line.lineWidth=0.5;
        CGFloat pattern[2]={4.0,2.0};
        [line setLineDash:pattern count:2 phase:0];

        [line stroke];

    }

    // draw center grid ( the contact)
    CGRect contentRect=CGRectMake(minX, minY, sideLength, sideLength);
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
