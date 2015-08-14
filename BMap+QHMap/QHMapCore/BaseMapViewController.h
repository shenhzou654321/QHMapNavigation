//
//  BaseMapViewController.h
//  AmapTest
//
//  Created by imqiuhang on 14/11/14.
//  Copyright (c) 2014年 imqiuhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"
#import "UIView+QHUiViewCtg.h"
#import "MapCommUtility.h"
#import "CAdefine.h"
typedef enum {
    searchBus,
    searchWalk,
    searchCar
}searchType;

@interface BaseMapViewController :UIViewController
{
    UITableView *dataTableView;
}
- (void)cusShowLoaingView;
- (void)cusHideLoaingView;
@end
