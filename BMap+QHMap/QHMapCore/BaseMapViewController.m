//
//  BaseMapViewController.m
//  AmapTest
//
//  Created by imqiuhang on 14/11/14.
//  Copyright (c) 2014年 imqiuhang. All rights reserved.
//

#import "BaseMapViewController.h"
#import "MSUtil.h"
@interface BaseMapViewController ()
{
    UIView *container;
}
@end

@implementation BaseMapViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self initLoaingView];
}

#
#pragma mark 各种初实例始化

-(void)initLoaingView{
    container = [[UIView alloc] initWithFrame:CGRectMake(0, 64, screenWidth, screenHeight-44)];
    [container setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin];
    
    UIView *cusloadingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mapLoading"]];
    [cusloadingView setFrame:CGRectMake(5, 3, 30, 30)];
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation                     = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue             = [NSNumber numberWithFloat: M_PI * 2.0 ];
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    rotationAnimation.duration            = 1;
    rotationAnimation.RepeatCount         = 100000;
    rotationAnimation.cumulative          = NO;
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.fillMode            = kCAFillModeForwards;
    cusloadingView.centerX                = container.width/2;
    cusloadingView.centerY                = container.height/2;
    [container addSubview:cusloadingView];
    
    [cusloadingView.layer addAnimation:rotationAnimation forKey:@"Rotation"];
    
    UILabel*loadingLabel         = [[UILabel alloc] initWithFrame:CGRectMake(5, 40, 120, 20)];
    loadingLabel.font            = [UIFont systemFontOfSize:12];
    loadingLabel.backgroundColor = [UIColor clearColor];
    loadingLabel.textColor       = [UIColor lightGrayColor];
    loadingLabel.textAlignment   = NSTextAlignmentCenter;
    loadingLabel.text            = @"拼命加载中...";
    loadingLabel.centerX         = container.width/2;
    loadingLabel.top             = cusloadingView.bottom+10;
    [container addSubview:loadingLabel];
    
}

- (void)cusShowLoaingView {
    [self cusHideLoaingView];
    [self.view addSubview:container];
}

- (void)cusHideLoaingView {
    [container removeFromSuperview];
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}


@end
