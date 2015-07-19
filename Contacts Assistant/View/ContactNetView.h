//
//  ContactNetView.h
//  Contacts Assistant
//
//  Created by Amay on 7/15/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ElementView.h"

@protocol ContactNetViewDataSource <NSObject>

-(NSUInteger)numberOfTopElements; //exclude the centered element
-(NSString *)nameOfTopElement:(NSUInteger)topElementIndex;
-(ElementViewType)typeOfTopElement:(NSUInteger)topElementIndex;
-(UIImage *)imageOfTopElement:(NSUInteger)topElementIndex;


-(NSUInteger)numberOfElementsUnderTopElement:(NSUInteger)topElementIndex; //exclude the top element
-(NSString *)nameOfElement:(NSUInteger)element:Index underTopElement:(NSUInteger)topElementIndex;
-(ElementViewType)typeOfElement:(NSUInteger)elementIndex underTopElement:(NSUInteger)topElementIndex;
-(UIImage *)imageOfElement:(NSUInteger)elementIndex underTopElement:(NSUInteger)topElementIndex;

-(NSString *)relationOfElementAtIndex:(NSUInteger)index1 isElementAtIndex:(NSUInteger)index2;

@end

@protocol ContactNetViewDelegate <NSObject>



@end

@interface ContactNetView : UIView

@property(weak,nonatomic)id<ContactNetViewDataSource>dataSource;
@property(weak,nonatomic)id<ContactNetViewDelegate>delegate;

@end
