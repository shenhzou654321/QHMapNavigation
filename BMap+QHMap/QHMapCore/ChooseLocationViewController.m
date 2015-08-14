//
//  ChooseLocationViewController.m
//  AmapTest
//
//  Created by imqiuhang on 14/11/16.
//  Copyright (c) 2014年 imqiuhang. All rights reserved.
//

#import "ChooseLocationViewController.h"
#import "MSUtil.h"
#import "DDAnnotation.h"
#import "CustomMapAnnView.h"
#define userLocationing     @"正在为您定位..."
#define failLocationStr     @"暂时无法获取位置信息"

@interface ChooseLocationViewController ()<BMKMapViewDelegate,BMKGeoCodeSearchDelegate,BMKLocationServiceDelegate>
{
    NSDictionary           *locationInfo;
    UITapGestureRecognizer *touchMapTap;
    DDAnnotation           *curAnn;
    BMKMapView             *chooseMapView;
    BMKGeoCodeSearch       *geocodesearch;
    BMKLocationService     *locService;
}

@end

@implementation ChooseLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initMapView];
}

-(void)initMapView
{
    
    locService = [[BMKLocationService alloc] init];
    locService.delegate = self;
    [locService startUserLocationService];
    
    chooseMapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, 64, screenWidth, screenHeight-44)];
    chooseMapView.delegate         = self;
    chooseMapView.delegate         = self;
    chooseMapView.centerCoordinate = self.startLocation;
    chooseMapView.zoomLevel        = chooseMapView.maxZoomLevel;
    [self.view addSubview:chooseMapView];
    
    touchMapTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchMapViewEvent:)];
    [chooseMapView addGestureRecognizer:touchMapTap];
    
    geocodesearch = [[BMKGeoCodeSearch alloc]init];
    geocodesearch.delegate = self;
}

- (void)searchReGeocodeWithCoordinate:(CLLocationCoordinate2D)coordinate {
    
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeocodeSearchOption.reverseGeoPoint = coordinate;
    BOOL flag = [geocodesearch reverseGeoCode:reverseGeocodeSearchOption];
    
    if(flag){
        MSLog(@"反geo检索发送成功");
    } else {
        MSLog(@"反geo检索发送失败");
    }
}

#pragma mark - MAMapViewDelegate

- (void)didUpdateUserLocation:(BMKUserLocation *)userLocation {
    if (userLocation.location!=nil) {
        
        chooseMapView.centerCoordinate  = userLocation.location.coordinate;
        chooseMapView.zoomLevel         = chooseMapView.maxZoomLevel;
        chooseMapView.userTrackingMode  = BMKUserTrackingModeFollow;
        chooseMapView.showsUserLocation = YES;
        
        [locService stopUserLocationService];
    }
}

- (void)didFailToLocateUserWithError:(NSError *)error {
    MSLog(@"暂时无法为您定位，如需处理请在此处处理");
}

- (void)rightBtnClicked {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"USERLOCATIONCHANGED" object:locationInfo];
    [self.navigationController popViewControllerAnimated:YES];
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation {
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        static NSString *bmkPointAnnotationIdenyifi = @"BMKPointAnnotation";
        
        BMKAnnotationView *poiAnnotationView = (BMKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:bmkPointAnnotationIdenyifi];
        if (poiAnnotationView == nil) {
            poiAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:bmkPointAnnotationIdenyifi];
        }
        DDAnnotation *ann                = annotation;
        poiAnnotationView.annotation     = annotation;
        poiAnnotationView.canShowCallout = YES;
        
        UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, poiAnnotationView.height)];
        UIView*LineView   = [[UIView alloc] initWithFrame:CGRectMake(5, 0, 0.5, poiAnnotationView.height)];
        LineView.backgroundColor = [UIColor splitlineGray];
        
        UIButton*rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(3, 0, 30, poiAnnotationView.height)];
        [rightBtn setImage:[UIImage imageNamed:@"mylocalGo"] forState:UIControlStateNormal];
        [rightBtn addTarget:nil action:@selector(rightBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        
        poiAnnotationView.image = [UIImage imageNamed:@"choosePostInMap"];
        [rightView addSubview:LineView];
        [rightView addSubview:rightBtn];
        
        if (![ann.title isEqualToString:userLocationing]&&![ann.title isEqualToString:failLocationStr]) {
            poiAnnotationView.rightCalloutAccessoryView = rightView;
        }else {
            poiAnnotationView.rightCalloutAccessoryView = nil;
        }
        return poiAnnotationView;
    }
    return nil;
}

#pragma mark - AMapSearchDelegate

- (void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error {
    if (error == 0) {
        
        [chooseMapView removeAnnotations:chooseMapView.annotations];
        CLLocationCoordinate2D coordinate = result.location;
        curAnn=[[DDAnnotation alloc] init];
        curAnn.title      =@"您选择的位置是:";
        curAnn.subtitle   = result.address;
        curAnn.coordinate = coordinate;
        
        [chooseMapView addAnnotation:curAnn];
        [chooseMapView selectAnnotation:curAnn animated:YES];
        locationInfo = [[NSDictionary alloc]init];
        locationInfo  =@{
                         @"locationTitle":curAnn.subtitle,
                         @"location":[CustomMapLocation customLocationMakeWithCLL:result.location],
                         @"city":result.addressDetail.city
                         };
    }else {
        curAnn.title = failLocationStr;
    }
}
#pragma mark - Handle Gesture

- (void)touchMapViewEvent:(UITapGestureRecognizer *)touchPoint {
    if (touchPoint.numberOfTouches==1) {
        
        CLLocationCoordinate2D coordinate = [chooseMapView convertPoint:[touchPoint locationInView:chooseMapView]
                                                   toCoordinateFromView:chooseMapView];
        [chooseMapView removeAnnotations:chooseMapView.annotations];
        
        curAnn = [[DDAnnotation alloc] init];
        curAnn.title      = userLocationing;
        curAnn.coordinate = coordinate;
        [chooseMapView addAnnotation:curAnn];
        [chooseMapView selectAnnotation:curAnn animated:YES];
        [self searchReGeocodeWithCoordinate:coordinate];
    }
    
    
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    chooseMapView.delegate = nil;
    chooseMapView          = nil;
    geocodesearch.delegate = nil;
    geocodesearch          = nil;
}
-(void)dealloc{
    MSLog(@"chooseLocationView dealloc");
}

@end
