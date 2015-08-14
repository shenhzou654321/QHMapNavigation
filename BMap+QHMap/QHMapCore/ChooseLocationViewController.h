//
//  ChooseLocationViewController.h
//  AmapTest
//
//  Created by imqiuhang on 14/11/16.
//  Copyright (c) 2014年 imqiuhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseMapViewController.h"
@interface ChooseLocationViewController : BaseMapViewController
/**
 *  开始定位到定位成功前展示在地图区域的位置坐标,如果不给默认展示的背景天安门
 */
@property (nonatomic) CLLocationCoordinate2D startLocation;

@end
