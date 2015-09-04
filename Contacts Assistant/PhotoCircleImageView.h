//
//  PlayerPhotoImageView.h
//  Two Beat One
//
//  Created by Amay on 5/26/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCircleImageView : UIView

@property(strong,nonatomic)UIImage *photo;

-(void)startAnimating;
-(void)stopAnimating;

@end
