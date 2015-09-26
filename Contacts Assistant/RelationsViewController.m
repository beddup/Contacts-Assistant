//
//  RelationsViewController.m
//  Contacts Assistant
//
//  Created by Amay on 7/25/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "RelationsViewController.h"
#import "RelationsView.h"
#import "Contact.h"
#import "AddRelationViewController.h"
#import "Relation.h"
#import "ContactsManager.h"
#import "ContactsUnderSameTagViewController.h"
#import "ContactDetailsViewController.h"
@interface RelationsViewController ()<RelationsViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property(weak,nonatomic)RelationsView *relationsView;

@end

@implementation RelationsViewController
#pragma mark - life cycle
- (void)viewDidLoad {

    [super viewDidLoad];
    [self configureNavigationBar];
    [self configureScrollView];

}
-(void)viewDidLayoutSubviews{

    [self updateSVContentSize];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark navigation bar itmes and actions
-(void)configureNavigationBar{
    UIBarButtonItem *barButton=[[UIBarButtonItem alloc]initWithTitle:@"增加关联"
                                                               style:UIBarButtonItemStylePlain target:self
                                                              action:@selector(addRelation:)];
    self.navigationItem.rightBarButtonItem=barButton;
}
-(IBAction)finishAddRelation:(UIStoryboardSegue *)segue{
    [self.relationsView update];
    [self.delegate relationsChanged];
}
-(void)addRelation:(UIBarButtonItem *)barbutton{
    [self performSegueWithIdentifier:@"newRelation" sender:nil];
}


-(void)setContact:(Contact *)contact{
    _contact=contact;
    self.relationsView.contact=contact;

    [self updateSVContentSize];

}
#pragma mark - sroll view
-(void)configureScrollView{

    RelationsView *relationsView=[[RelationsView alloc]init];
    relationsView.contact=self.contact;

    relationsView.delegate=self;
    self.relationsView=relationsView;
    [self.containerScrollView addSubview:relationsView];
    
}

-(void)updateSVContentSize{

    CGFloat width=CGRectGetWidth(self.relationsView.bounds);
    CGFloat height=CGRectGetHeight(self.relationsView.bounds);
    self.containerScrollView.contentSize=CGSizeMake(MAX(width, self.view.bounds.size.width), MAX(height, self.view.bounds.size.height));
    self.relationsView.center=CGPointMake(self.containerScrollView.contentSize.width/2, self.containerScrollView.contentSize.height/2);

}
#pragma mark -RelationsViewDelegate
-(void)dismissRelationBetween:(Contact *)contact1 otherContact:(Contact *)contact2{

        NSArray *relationsOfContact1=[contact1.relationsWithOtherPeople allObjects];
        NSArray *relationsWithContact2=[relationsOfContact1 filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"otherContact.contactID.integerValue = %d",contact2.contactID.integerValue]];

        NSArray *relationsOfContact2=[contact2.relationsWithOtherPeople allObjects];
        NSArray *relationsWithContact1=[relationsOfContact2 filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"otherContact.contactID.integerValue = %d",contact1.contactID.integerValue]];

        NSArray *relations=[relationsWithContact2 arrayByAddingObjectsFromArray:relationsWithContact1];

        NSString *alertTitle=[NSString stringWithFormat:@"解除%@与%@之间的关联",contact1.contactName,contact2.contactName];
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil message:alertTitle preferredStyle:UIAlertControllerStyleActionSheet];
        for (Relation *relation in relations) {
            NSString *title=[NSString stringWithFormat:@"解除 %@ 关联",relation.relationName];
            UIAlertAction *action=[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self.contact removeRelationsWithOtherPeopleObject:relation];
                [self.contact removeBelongWhichRelationsObject:relation];
                [relation.managedObjectContext deleteObject:relation];
                [self.relationsView relationDeleted:relation];
                [self.delegate relationsChanged];
            }];
            [alertController addAction:action];
        }
        UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];

}
-(void)showAllContactsWhoHaveSameTagWithContact:(Contact *)contact{

    ContactsUnderSameTagViewController *vc=[[ContactsUnderSameTagViewController alloc]initWithStyle:UITableViewStylePlain];
    vc.contact=self.contact;
    [self.navigationController pushViewController:vc animated:YES];

}
#pragma mark navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"newRelation"]) {
        UINavigationController *nav=(UINavigationController*)segue.destinationViewController;
        AddRelationViewController *vc=[nav.viewControllers firstObject];
        vc.contact=self.contact;
    }
    
}

@end
