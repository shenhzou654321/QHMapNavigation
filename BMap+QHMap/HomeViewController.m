//
//  HomeViewController.m
//  BMap+QHMap
//
//  Created by imqiuhang on 15/1/16.
//  Copyright (c) 2015年 your Co. Ltd. All rights reserved.
//

#import "HomeViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor whiteColor];
    
}


- (IBAction)done:(id)sender {
#warning 在APPDelegate里面一定要将bmkMapManager设为全局的  每一个应用都需要单独设置key 现在这个key是测试用的 到百度地图官网申请！！！
    
#warning 一定要在自己的应用的info.plist里面加上这句：NSLocationWhenInUseUsageDescription 类型为string  设置不然无法定位！！！
    
#warning 这里的坐标是谷歌坐标系的  如果你直接用的是百度坐标系的 请看LargeMapViewController.m里面的那个警告
    
    //你也可以传好几个目标点进去  测试我就只传了个九溪十八弯。。。。
    NSArray*info=@[[LargeMapViewInfo LargeMapViewInfoMakeWithTitle:self.titleInput.text
                                                        andAddress:self.nameInput.text
                                                       andLocation:CLLocationCoordinate2DMake([self.latInput.text floatValue], [self.lonInput.text floatValue])
                                                     andImageIndex:12]];
    
    LargeMapViewController*largeMapView=[[LargeMapViewController alloc] init];
    largeMapView.info=info;
    [self.navigationController pushViewController:largeMapView animated:YES];
}


@end
