//
//  MapCommUtility.h
//  weekend
//
//  Created by caomei on 14/12/8.
//  Copyright (c) 2014年 MiBang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMapKit.h"

@interface MapCommUtility : NSObject

+ (BMKCoordinateRegion) regionForAnnotations:(NSArray*) anns;
+ (CLLocationCoordinate2D)locationToBaidu:(CLLocationCoordinate2D)location;
+ (CLLocationCoordinate2D)gpsLocationToBaidu:(CLLocationCoordinate2D)location;
+ (NSString*)removeFormatWithStr:(NSString*)str;
+ (BMKCoordinateRegion) regionForCarAnnotations:(NSArray *)anns;

@end

@interface MapCommView : NSObject

+ (UIView*)getGoHereViewWithTitle:(NSString*)title
                      andSubTitle:(NSString*)subtitle
                      andLocation:(CLLocationCoordinate2D)location
                         andFrame:(CGRect)frame;

+ (UIButton*)getGoHereBtnWithFrame:(CGRect)frame
                            andSel:(SEL)event;

+ (UIButton*)getGoHereBtnWithFrame:(CGRect)frame
                        andSelName:(NSString*)eventName;

@end

@interface CustomMapLocation : NSObject

@property (nonatomic) CLLocationCoordinate2D location;

+ (instancetype)customLocationMake:(float)lat
                            andLon:(float)lon;

+ (instancetype)customLocationMakeWithCLL:(CLLocationCoordinate2D)cllLocation;

+ (instancetype)customLocationMakeWithGoogleLoc:(CLLocationCoordinate2D)cllLocation;

+ (instancetype)customLocationMakeWithGPSLoc:(CLLocationCoordinate2D)cllLocation;

@end



