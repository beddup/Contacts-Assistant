//
//  EventDetailView.m
//  Contacts Assistant
//
//  Created by Amay on 7/30/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "EventDetailView.h"
#import "Contact.h"
@interface EventDetailView()

@property (weak, nonatomic) IBOutlet UIImageView *eventIndicator;
@property (weak, nonatomic) IBOutlet UITextView *eventDescriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeLabel;
@property (weak, nonatomic) IBOutlet UIView *relatedPeopleView;

@property (weak, nonatomic) IBOutlet UIButton *changeContactsButton;
@property (weak, nonatomic) IBOutlet UIButton *changeTimeButton;
@property (weak, nonatomic) IBOutlet UIButton *changePlaceButton;

@property(strong,nonatomic)NSArray *contacts;

@end


@implementation EventDetailView

-(void)setEvent:(Event *)event{

    _event=event;

    self.contacts=[event.contactsWhichAttend allObjects];

    [self confirgureEventIndicator];

    [self configureDescriptionView];

    [self configureTimeLabel];

    [self configurePlaceLabel];

    [self configureRelatedPeopleView];

}

- (IBAction)changeContacts:(id)sender {
}

- (IBAction)changeTime:(id)sender {
}

- (IBAction)changePlace:(id)sender {
}



-(void)confirgureEventIndicator{
    NSTimeInterval delta=[self.event.date timeIntervalSinceNow];
    if (delta < -60*15) {
        // the event has passed 15mins
        self.eventIndicator.image=[UIImage imageNamed:@"GrayIndicator"];
    }else if (delta < 24 * 60 * 60  ){
        //in 1 day
        self.eventIndicator.image=[UIImage imageNamed:@"OrangeIndicator"];
    }else{
        //more than 1day
        self.eventIndicator.image=[UIImage imageNamed:@"YellowIndocator"];
    }

}
-(void)configureDescriptionView{

    self.eventDescriptionTextView.text=self.event.event;

    self.changeContactsButton.hidden=YES;
    self.changePlaceButton.hidden=YES;
    self.changeTimeButton.hidden=YES;

}
-(void)configureTimeLabel{

   self.timeLabel.text = [NSDateFormatter localizedStringFromDate:self.event.date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];

}

-(void)configurePlaceLabel{

    self.placeLabel.text=@"事项地点";

}

-(void)configureRelatedPeopleView{

    for (int i = 0 ;i< self.contacts.count;i++) {
        Contact *contact=(Contact *)self.contacts[i];

        UIButton *button=[[UIButton alloc]init];
        NSAttributedString *attributedTitle=[[NSAttributedString alloc]initWithString:contact.contactName attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor],NSFontAttributeName:[UIFont systemFontOfSize:14]}];
        [button setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        button.bounds=CGRectMake(0, 0, attributedTitle.size.width*1.2+20, 30);
        [self.relatedPeopleView addSubview:button];
        button.tag=i;
        [button addTarget:self action:@selector(contactButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    }

}

-(void)contactButtonTouched:(UIButton *)button{
    Contact *contact=self.contacts[button.tag];

    // do something with contact;

}

-(void)layoutSubviews{

    
    //eventDescriptionTextView frame
    self.eventDescriptionTextView.bounds=CGRectMake(0, 0, self.eventDescriptionTextView.contentSize.width, self.eventDescriptionTextView.contentSize.height);

    //relatedPeopleView
    if (self.relatedPeopleView.subviews.count >0) {
        CGFloat maxWidth=CGRectGetWidth(self.relatedPeopleView.bounds);
        CGFloat maxXOfLastEvaluatedButton=4;
        CGFloat minYOfLastEvaluatedButton=4;
        CGFloat spaceBetweenButton=4; //horitonally and verrically
        for (int i=0 ; i<self.relatedPeopleView.subviews.count; i++) {
            // contact button 's frame
            UIButton *button=(UIButton *)self.relatedPeopleView.subviews[i];
            if (CGRectGetWidth(button.bounds)< maxWidth-maxXOfLastEvaluatedButton-spaceBetweenButton) {

                button.frame=CGRectMake(maxXOfLastEvaluatedButton+spaceBetweenButton, minYOfLastEvaluatedButton, CGRectGetWidth(button.bounds), CGRectGetHeight(button.bounds));

            }else{

                minYOfLastEvaluatedButton=minYOfLastEvaluatedButton+CGRectGetHeight(button.bounds)+spaceBetweenButton;
                button.frame=CGRectMake(spaceBetweenButton, minYOfLastEvaluatedButton, CGRectGetWidth(button.bounds), CGRectGetHeight(button.bounds));
            }
            maxXOfLastEvaluatedButton=CGRectGetMaxX(button.bounds);
        }

        //relatedPeopleView 's frame
        self.relatedPeopleView.bounds=CGRectMake(0, 0, CGRectGetWidth(self.relatedPeopleView.bounds), minYOfLastEvaluatedButton+30+spaceBetweenButton);
    }

}


#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.backgroundColor=[UIColor clearColor];
    self.eventDescriptionTextView.editable=NO;
    self.eventDescriptionTextView.scrollEnabled=NO;


}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

@end
