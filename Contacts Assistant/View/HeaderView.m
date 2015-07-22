//
//  HeaderView.m
//  Contacts Assistant
//
//  Created by Amay on 7/20/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "HeaderView.h"
@interface HeaderView()<UITextFieldDelegate>

@property(weak,nonatomic)UIView *dimmingView;
@property(weak,nonatomic)UIView *viewWhenAdd;

@property(strong,nonatomic)UIImage *addViewBKGImage;
@end

@implementation HeaderView
#pragma  mark -Add New Tag or Contact

static NSInteger AddTagBKGImageViewTag = 11;
static NSInteger AddTagTextFieldTag =12 ;

static NSInteger AddContactBKGImageViewTag = 21;
static NSInteger AddContactManuallyAddButtonTag=22;
static NSInteger AddContactScanQRButtonTag=23;

static CGFloat  AddViewWidth =200;

-(UIImage *)addViewBKGImage{
    if (!_addViewBKGImage) {
        UIEdgeInsets capInsets=UIEdgeInsetsMake(12, 5, 5, 20);
        _addViewBKGImage=[[UIImage imageNamed:@"ListBKGImage"] resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
    }
    return _addViewBKGImage;
}

-(void)dimTableView{

    UIView *highHRKView=self.superview.superview;
    UIView *dimmingView=[[UIView alloc]initWithFrame:highHRKView.bounds];
    dimmingView.backgroundColor=[UIColor lightGrayColor];
    self.dimmingView=dimmingView;
    self.dimmingView.alpha=0.0;
    [highHRKView addSubview:dimmingView];

    UITapGestureRecognizer *tapToDismissAdd=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissAdd:)];
    [self.dimmingView addGestureRecognizer:tapToDismissAdd];
}

-(void)showAddTagViewInRect:(CGRect)rect{

    UIView *highHRKView=self.superview.superview;

    // configure AddTagView
    UIView *addTagView=[[[NSBundle mainBundle]loadNibNamed:@"AddTagView" owner:nil options:nil] lastObject];
    self.viewWhenAdd=addTagView;
    addTagView.frame=CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), AddViewWidth, 0);
    CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), 0);
    [addTagView layoutIfNeeded];

    UIImageView *BKGImageView=(UIImageView *)[addTagView viewWithTag:AddTagBKGImageViewTag];
    BKGImageView.image=self.addViewBKGImage;

    UITextField *textField=(UITextField *)[addTagView viewWithTag:AddTagTextFieldTag];
    textField.delegate=self;

    //display with animation
    [highHRKView addSubview:addTagView];
    [UIView animateWithDuration:0.3
                          delay:0
                      usingSpringWithDamping:0.7
                       initialSpringVelocity:0.5
                        options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationCurveEaseOut |UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         addTagView.frame=rect;
                         self.dimmingView.alpha=0.1;}
                     completion:nil];

}
-(void)showAddContactViewInRect:(CGRect)rect{

    UIView *highHRKView=self.superview.superview;

    // configure AddContactOptionsView
    UIView *addContactOptionsView=[[[NSBundle mainBundle]loadNibNamed:@"AddContactOptionsView" owner:nil options:nil] lastObject];
    self.viewWhenAdd=addContactOptionsView;
    addContactOptionsView.frame=CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), AddViewWidth, 0);

    [addContactOptionsView layoutIfNeeded]; // update subview immediately to make animation more reasonble

    UIImageView *BKGImageView=(UIImageView *)[addContactOptionsView viewWithTag:AddContactBKGImageViewTag];
    BKGImageView.image=self.addViewBKGImage;

    UIButton *addManuallyButton=(UIButton *)[addContactOptionsView viewWithTag:AddContactManuallyAddButtonTag];
    UIButton *addByQRCode=(UIButton *)[addContactOptionsView viewWithTag:AddContactScanQRButtonTag];
    [addManuallyButton addTarget:self action:@selector(addContactManually:) forControlEvents:UIControlEventTouchUpInside];
    [addByQRCode addTarget:self action:@selector(addContactByScanningQR:) forControlEvents:UIControlEventTouchUpInside];

    //display with animation
    [highHRKView addSubview:addContactOptionsView];

    CGFloat delta=CGRectGetMaxY(rect)-CGRectGetHeight(highHRKView.bounds);
    UITableView *tableView=(UITableView *)self.superview;
    NSLog(@"offset:%f,%f",tableView.contentOffset.x,tableView.contentOffset.y);

    [UIView animateWithDuration:0.5
                          delay:0
                      usingSpringWithDamping:0.7
                       initialSpringVelocity:0.5
                        options:UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         if (delta > 0) {
                             [tableView setContentOffset:CGPointMake(tableView.contentOffset.x, tableView.contentOffset.y+delta+5) animated:NO];
                             NSLog(@"offset:%f,%f",tableView.contentOffset.x,tableView.contentOffset.y);
                             addContactOptionsView.frame=CGRectOffset(rect, 0, -delta-5);
                         }else{
                             addContactOptionsView.frame=rect;
                         }
                         self.dimmingView.alpha=0.1;
                     }
                     completion:nil];

}
-(void)add:(UIButton *)button{

    [self dimTableView];

    UIView *highHRKView=self.superview.superview;
    // add imageview to tableview's superview, so imageview wouldn't be dimmed
    CGRect rect=[self convertRect:self.bounds toView:highHRKView];
    switch (self.type) {
        case HeaderTypeTags:{
            CGRect addTagViewFrame=CGRectMake(CGRectGetWidth(rect)-AddViewWidth - 10,  CGRectGetMaxY(rect), AddViewWidth, 50);
            [self showAddTagViewInRect:addTagViewFrame];
            break;
        }
        case HeaderTypeContacts:{
            CGRect addContactViewFrame=CGRectMake(CGRectGetWidth(rect)-AddViewWidth - 10,  CGRectGetMaxY(rect), AddViewWidth, 120);
            [self showAddContactViewInRect:addContactViewFrame];
            break;
        }
    }
}

-(void)dismissAdd:(UITapGestureRecognizer *)gesture{

    if (gesture.state ==UIGestureRecognizerStateEnded) {
        [self dismissAddView];
    }
}
-(void)addContactManually:(UIButton *)button{
    NSLog(@"addContactManually");
    [self dismissAddView];

}
-(void)addContactByScanningQR:(UIButton *)button{
    NSLog(@"addContactByScanningQR");
    [self dismissAddView];

}
-(void)dismissAddView{

    [self.viewWhenAdd removeFromSuperview];
    [self.dimmingView removeFromSuperview];

}
#pragma mark - UITextFieldDelegate
-(void)textFieldDidEndEditing:(UITextField *)textField{
    NSLog(@"add new tag:%@",textField.text);
    // heare should trim the space at the front and behind
    [self.delegate addNewTagNamed:textField.text];
    [self dismissAddView];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (![textField.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]].length) {
        return NO;
    }
    BOOL isExisting=[self.delegate tagNameExists:textField.text];
    if (!isExisting) {
        [textField resignFirstResponder];
    }
    return !isExisting;
}

#pragma  mark - setup

-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    UIButton *addButton = [[UIButton alloc]init];
    [self.contentView addSubview:addButton];
    [addButton setTitle:@"Add" forState:UIControlStateNormal];
    [addButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(add:) forControlEvents:UIControlEventTouchUpInside];
    self.addButton=addButton;

    // why use constarint , because if override layoutsubviews ,the textLabel would not display
    NSLayoutConstraint *trailingConstraint=[NSLayoutConstraint constraintWithItem:addButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-8];
    NSLayoutConstraint *centerY=[NSLayoutConstraint constraintWithItem:addButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    [self.contentView addConstraints:@[trailingConstraint,centerY]];

    [self.addButton setTranslatesAutoresizingMaskIntoConstraints:NO];

}
-(instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self=[super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}
@end
