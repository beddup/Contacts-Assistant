//
//  ContactNetView.m
//  Contacts Assistant
//
//  Created by Amay on 7/15/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "ContactNetView.h"
#import "TagView.h"
#import "ContactView.h"




@interface ContactNetView ()<UIScrollViewDelegate>


@property (weak,nonatomic)UIView *topBar;

@property (weak,nonatomic)UIScrollView *elementsDisplayArea;

@property (strong,nonatomic) NSMutableArray *elementsViews; //exclude top element view

@property(nonatomic) NSInteger elementsCount;

@end

@implementation ContactNetView

-(NSMutableArray*)elementsViews{
    if (!_elementsViews) {
        _elementsViews = [@[] mutableCopy];
    }
    return _elementsViews;
}

-(void)setDataSource:(id<ContactNetViewDataSource>)dataSource{
    _dataSource=dataSource;

    NSInteger topElementIndex=0;

    self.elementsCount=[self.dataSource numberOfElementsUnderTopElement:topElementIndex];

    // create top element
    ElementView *ownerView=[[ElementView alloc]initWithElementType:ElementViewTypeOwner];
    ownerView.elementName=[self.dataSource nameOfTopElement:topElementIndex];
    NSLog(@"elementname:%@",ownerView.elementName);
    ownerView.elementImage=[self.dataSource imageOfTopElement:topElementIndex];
    [self.contentView addSubview:ownerView];
    self.topElementView=ownerView;

//    create navigaiton element
    ElementView *ownerViewAtNavigation=[[ElementView alloc]initWithElementType:ElementViewTypeOwner];
    ownerViewAtNavigation.elementName=ownerView.elementName;
    ownerViewAtNavigation.elementImage=ownerView.elementImage;
    ownerViewAtNavigation.frame=CGRectMake(4, 0, 44, 44);
    [self.navigationScrollView addSubview:ownerViewAtNavigation];
    [self.navigationViews addObject:ownerViewAtNavigation];



//     create elements
    for (NSInteger elementIndex=0; elementIndex<[self.dataSource numberOfElementsUnderTopElement:topElementIndex]; elementIndex++) {
        ElementView *elementView=[[ElementView alloc]initWithElementType:[self.dataSource typeOfElement:elementIndex underTopElement:topElementIndex]];
        elementView.elementName=[self.dataSource nameOfElement:elementIndex underTopElement:topElementIndex];
        elementView.elementImage=[self.dataSource imageOfElement:elementIndex underTopElement:topElementIndex];
        NSLog(@"elementname:%@",elementView.elementName);
        [self.contentView addSubview:elementView];
        [self.elementsViews addObject:elementView];
    }
    //calculate geometry info
    [self calculateGeometryInfo];




    //create relation

}
-(void)calculateGeometryInfo{
    
}
-(void)layoutSubviews{
    //set navigationScrollView geometry
    self.navigationScrollView.frame=CGRectMake(0,0,CGRectGetWidth(self.bounds), 44);
    self.navigationScrollView.contentSize=self.navigationScrollView.bounds.size;

    //set contentView geometry
    self.contentView.frame=CGRectMake(0, CGRectGetMaxY(self.navigationScrollView.frame), CGRectGetWidth(self.bounds), CGRectGetHeight(self.frame)-CGRectGetHeight(self.navigationScrollView.frame));

    //set topElementView geometry
    CGFloat contentWidth=CGRectGetWidth(self.contentView.frame);
    CGFloat contentHeight=CGRectGetHeight(self.contentView.frame);
    self.topElementView.frame=CGRectMake(contentWidth/2-25, contentHeight/2-35, 50, 70);

    //set other element views geometry
    for (NSInteger elementIndex=0; elementIndex<self.elementsViews.count; elementIndex++) {
        ElementView *view=self.elementsViews[elementIndex];
        view.frame=CGRectMake(contentWidth*((float)(arc4random()%100))/100, contentHeight*((float)(arc4random()%100))/100,view.suggestedSize.width, view.suggestedSize.height);

    }

}



#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{
    //add top bar


}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}




@end
