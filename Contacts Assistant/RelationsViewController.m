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
@interface RelationsViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property(weak,nonatomic)RelationsView *relationsView;

@end

@implementation RelationsViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    [self configureNavigationBar];
    [self configureScrollView];

}
-(void)viewDidLayoutSubviews{

    CGFloat width=CGRectGetWidth(self.relationsView.bounds);
    CGFloat height=CGRectGetHeight(self.relationsView.bounds);

    self.containerScrollView.contentSize=CGSizeMake(MAX(width, self.view.bounds.size.width), MAX(height, self.view.bounds.size.height));

    self.relationsView.center=CGPointMake(self.containerScrollView.contentSize.width/2, self.containerScrollView.contentSize.height/2);
}

-(void)configureNavigationBar{
    UIBarButtonItem *barButton=[[UIBarButtonItem alloc]initWithTitle:@"增加关联"
                                                               style:UIBarButtonItemStylePlain target:self
                                                              action:@selector(addRelation:)];
    self.navigationItem.rightBarButtonItem=barButton;
}

-(void)setContact:(Contact *)contact{
    _contact=contact;
    self.relationsView.contact=contact;
}

-(void)configureScrollView{

    RelationsView *view=[[RelationsView alloc]init];
    view.contact=self.contact;
    view.relationSelected=^(Contact *contact, Contact *otherContact){

        NSArray *relations=[contact.relationsWithOtherPeople allObjects];

        NSArray *relationsWithOtherContact=[relations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"otherContact.contactID.integerValue = %d",otherContact.contactID.integerValue]];

        NSString *alertTitle=[NSString stringWithFormat:@"解除与%@的关联",otherContact.contactName];
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil message:alertTitle preferredStyle:UIAlertControllerStyleActionSheet];
        for (Relation *relation in relationsWithOtherContact) {
            NSString *title=[NSString stringWithFormat:@"解除 %@ 关联",relation.relationName];
            UIAlertAction *action=[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [[ContactsManager sharedContactManager] removeRelation:relation];
                [self.relationsView relationDeleted:relation];
            }];
            [alertController addAction:action];
        }
        UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];

    };

    view.sameTagContactsSelected=^(Contact *contact){
        ContactsUnderSameTagViewController *vc=[[ContactsUnderSameTagViewController alloc]initWithStyle:UITableViewStylePlain];
        vc.contact=self.contact;
        [self.navigationController pushViewController:vc animated:YES];
    };
    self.relationsView=view;
    [self.containerScrollView addSubview:view];

}

-(IBAction)finishAddRelation:(UIStoryboardSegue *)segue{
    [self.relationsView updateRelationViews];
}
-(void)addRelation:(UIBarButtonItem *)barbutton{
    [self performSegueWithIdentifier:@"newRelation" sender:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if ([segue.identifier isEqualToString:@"newRelation"]) {
        UINavigationController *nav=(UINavigationController*)segue.destinationViewController;
        AddRelationViewController *vc=[nav.viewControllers firstObject];
        vc.contact=self.contact;
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
