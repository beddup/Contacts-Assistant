//
//  OperationsView.m
//  Contacts Assistant
//
//  Created by Amay on 7/15/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "OperationsView.h"
@interface OperationsView()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *BKGImageView;
@property(strong,nonatomic)NSArray *operationIconName;
@property(strong,nonatomic)NSArray *operationName;
@end

@implementation OperationsView

-(NSArray *)operationIconName{
    if (!_operationIconName) {
        _operationIconName=@[@"defualtOperationIcon",@"defualtOperationIcon",@"defualtOperationIcon",@"defualtOperationIcon",@"defualtOperationIcon"];
    }
    return _operationIconName;
}
-(NSArray*)operationName{
    if (!_operationName) {
        _operationName=@[@"New Contact",@"Scan QR Code",@"Exchange Card",@"Send SMS",@"Send eMail"];
    }
    return _operationName;
}
#pragma mark -UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    switch (indexPath.row) {
        case 0:{
            [self.delegate operationViewCreatNewContact:self];
            break;
        }
        case 1:{
            [self.delegate operationViewExchangeCard:self];
            break;
        }
        case 2:{
            [self.delegate operationViewScanQRCode:self];
            break;
        }
        case 3:{
            [self.delegate operationViewSendSMS:self];
            break;
        }
        case 4:{
            [self.delegate operationViewSendEmail:self];
            break;
        }
        default:
            break;
    }
}
#pragma mark -UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.operationName.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"operation cell"];
    if (!cell) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"operation cell"];
//        cell.backgroundColor=[UIColor clearColor];
    }
    cell.imageView.image=[UIImage imageNamed:self.operationIconName[indexPath.row]];
    cell.textLabel.text=self.operationName[indexPath.row];
    return cell;
}
-(void)awakeFromNib{
    self.backgroundColor=[UIColor clearColor];
}
@end
