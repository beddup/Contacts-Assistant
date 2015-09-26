//
//  TagsTableViewController.m
//  Contacts Assistant
//
//  Created by Amay on 9/6/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "TagsTableViewController.h"
#import "Tag+Utility.h"
#import "defines.h"
@interface TagsTableViewController()<UITextFieldDelegate>

@property(weak,nonatomic)UITextField *createNewTagTF;

@property(strong,nonatomic)UIImage *createNewTagTFBKGImage;

@end


@implementation TagsTableViewController
-(void)viewDidLoad{
    [super viewDidLoad];
    [self configureTableHeaderView];
    self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TFDidChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.createNewTagTF resignFirstResponder];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

-(CGFloat)heightOfTableHeaderView{
    return 44;
}
-(void)configureTableHeaderView{
    // configure header view to create new tag

    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, [self heightOfTableHeaderView])];
    self.tableView.tableHeaderView=view;
    UITextField *createNewTagTF=[[UITextField alloc]init];
    createNewTagTF.font=[UIFont systemFontOfSize:15];
    createNewTagTF.textColor=IconColor;
    [view addSubview:createNewTagTF];
    self.createNewTagTF=createNewTagTF;

    createNewTagTF.placeholder=@"创建一个新标签";

    createNewTagTF.returnKeyType=UIReturnKeyDone;
    createNewTagTF.delegate=self;

    createNewTagTF.frame=[self frameOfNewTagTF];

    [self.createNewTagTF setBackground:self.createNewTagTFBKGImage];
    
}

-(void)TFDidChanged:(NSNotification *)notificaiton{

    UITextField *textField=notificaiton.object;
    if (textField== self.createNewTagTF) {
        self.createNewTagTF.frame=[self frameOfNewTagTF];
    }
    [self TFChanged:textField];

}
-(void)TFChanged:(UITextField *)tf{
    // override by subclass
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{

    if (textField == self.createNewTagTF) {
        NSString *newTagName=[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!newTagName.length) {
            return NO;
        }
        BOOL flag=[Tag tagExists:newTagName];
        if (flag) {
            return NO;
        }
        Tag *tag=[Tag createTagWithName:newTagName];
        [self didCreateNewTag:tag];
        [textField resignFirstResponder];
    }
    return YES;
}
-(void)didCreateNewTag:(Tag *)tag{
    // override by subclass
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.createNewTagTF) {
        [self resetNewTagTF];
    }
}
-(UIImage *)createNewTagTFBKGImage{
    if (!_createNewTagTFBKGImage) {
        UIImage *image=[UIImage imageNamed:@"TagViewUnSelectedBKG"];
        _createNewTagTFBKGImage=[image resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 16) resizingMode:UIImageResizingModeStretch];
    }
    return _createNewTagTFBKGImage;
}
-(void)resetNewTagTF{
    self.createNewTagTF.text=nil;
    self.createNewTagTF.frame=[self frameOfNewTagTF];
}

-(CGRect)frameOfNewTagTF{

    NSAttributedString *attributedstring=self.createNewTagTF.attributedText;
    if (!attributedstring.length) {
        attributedstring =[[NSAttributedString alloc]initWithString:self.createNewTagTF.placeholder attributes:@{NSFontAttributeName:self.createNewTagTF.font}];
    }
    CGFloat width= attributedstring.size.width + 20 +16 ;
    width = width > CGRectGetWidth(self.tableView.bounds)-30 ? CGRectGetWidth(self.tableView.bounds)-30 : width;

    CGRect rect=CGRectMake(self.tableView.separatorInset.left, 8, width, 36);
    return rect;
    
}

@end
