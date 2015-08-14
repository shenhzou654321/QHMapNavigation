//
//  MapSearchViewController.m
//  weekend
//
//  Created by imqiuhang on 14/12/6.
//  Copyright (c) 2014年 imqiuhang. All rights reserved.
//

#import "MapSearchViewController.h"
#import "BusInfoCell.h"
#import "ShowLineViewController.h"
#import "MSUtil.h"
#import "ListNoResultCell.h"
#import "ChooseLocationViewController.h"
#define btnPosition 70
#define btnHeigh 40
#define searchPosImgDefaultTag 999

typedef enum {
    mapNoResult   = 0,
    mapNone       = 1,
    mapBadNetWork = 2,
    mapBadService = 3
}Maptype;

@interface MapSearchViewController ()<BMKRouteSearchDelegate,BMKGeoCodeSearchDelegate,BMKLocationServiceDelegate>
{
    UILabel            *startLable;
    UILabel            *destinationLable;
    NSArray            *showWayBtnChoosedImages;
    NSArray            *showWayBtnUnChooseImages;
    NSMutableArray     *showWayImageViews;
    NSMutableArray     *showWayDownLineView;
    UIImageView        *chooseCustomPositionImageView;
    UIButton           *chooseCustomPositionBtn;
    UIView             *topView;
    UIButton           *changeStartDestinationBtn;
    
    
    BOOL               firstIn;
    Maptype            maptype;
    searchType         mySearchType;
    BMKRouteSearch     *routeSearch;
    NSMutableArray     *routeInfo;
    NSMutableArray     *turnInfo;
    BMKGeoCodeSearch   *geocodesearch;
    NSString           *city;
    BMKLocationService *locService;
    
    
}
@end

@implementation MapSearchViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    firstIn = YES;
    self.navigationController.navigationBar.alpha=1.0f;
    
    maptype      = mapNone;
    mySearchType = searchBus;
    
    [self initView];
    [self initLocation];
    routeSearch = [[BMKRouteSearch alloc] init];
    routeSearch.delegate = self;
    
    //当用户在地图中选择了起始位置会受到这个通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadLocation:) name:@"USERLOCATIONCHANGED" object:nil];
}
#pragma mark init
- (void)initLocation {
    [self cusShowLoaingView];
    locService = [[BMKLocationService alloc] init];
    locService.delegate = self;
    [locService startUserLocationService];
    destinationLocation = [MapCommUtility locationToBaidu:self.mapSearchViewInfo.destinationLocation];
    
}

#pragma mark Events

- (void)reloadLocation:(NSNotification*)aNotification
{
    routeSearch.delegate   = self;
    geocodesearch.delegate = self;
    locService.delegate    = self;
    NSDictionary*curLocationInfo = aNotification.object;
    CustomMapLocation*curCusLoc  = curLocationInfo[@"location"];
    if (curLocationInfo[@"city"]!=nil) {
        city                  = curLocationInfo[@"city"];
    }
    if (chooseCustomPositionImageView.tag == searchPosImgDefaultTag) {
        startLocation         = curCusLoc.location;
        startLable.text       = curLocationInfo[@"locationTitle"];
    }else{
        destinationLocation   = curCusLoc.location;
        destinationLable.text = curLocationInfo[@"locationTitle"];
    }
    [self beginSearch];
}
-(void)getLocation{
    geocodesearch = [[BMKGeoCodeSearch alloc]init];
    geocodesearch.delegate = self;
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeocodeSearchOption.reverseGeoPoint = startLocation;
    BOOL flag = [geocodesearch reverseGeoCode:reverseGeocodeSearchOption];
    
    if(flag) {
        MSLog(@"反geo检索发送成功");
    }else {
        MSLog(@"反geo检索发送失败");
        [self cusHideLoaingView];
        maptype = mapBadService;
        [self->dataTableView reloadData];
    }
    
}

-(void)changePos {
    CLLocationCoordinate2D curLocation = startLocation;
    startLocation            = destinationLocation;
    destinationLocation      = curLocation;
    
    NSString *curTitleString = startLable.text;
    startLable.text          = destinationLable.text;
    destinationLable.text            = curTitleString;
    
    [self->dataTableView reloadData];
    
    if (chooseCustomPositionImageView.tag==searchPosImgDefaultTag) {
        chooseCustomPositionImageView.tag = searchPosImgDefaultTag-1;
        chooseCustomPositionImageView.top += 30;
        chooseCustomPositionBtn.top       += 30;
    } else {
        chooseCustomPositionImageView.tag = searchPosImgDefaultTag;
        chooseCustomPositionImageView.top -= 30;
        chooseCustomPositionBtn.top       -= 30;
    }
    
    [self beginSearch];
}

- (void)chooseLocationInMap {
    ChooseLocationViewController *chooseView = [[ChooseLocationViewController alloc] init];
    chooseView.startLocation = startLocation;
    [self.navigationController pushViewController:chooseView animated:YES];
}

- (void)changeSearch:(UIButton*)sender {
    switch (sender.tag) {
        case 100:
            mySearchType = searchBus;
            break;
        case 101:
            mySearchType = searchWalk;
            break;
        case 102:
            mySearchType = searchCar;
            break;
        default:
            break;
    }
    for(int i=0;i<showWayImageViews.count;i++) {
        if(i == sender.tag-100) {
            UIImageView *cur_ImageView   = showWayImageViews[i];
            cur_ImageView.image          = [UIImage imageNamed:showWayBtnChoosedImages[i]];
            UIView*cur_lineView          = showWayDownLineView[i];
            cur_lineView.backgroundColor = [UIColor colorWithRed:122/255.0f green:124/255.0f blue:128/255.0f alpha:1.0f];
        }else {
            UIImageView *cur_ImageView   = showWayImageViews[i];
            cur_ImageView.image=[UIImage imageNamed:showWayBtnUnChooseImages[i]];
            
            UIView *cur_lineView         = showWayDownLineView[i];
            cur_lineView.backgroundColor = [UIColor clearColor];
            
        }
    }
    [self beginSearch];
}

#pragma mark -
#pragma searchEvent

- (void)beginSearch {
    
    [self doReload];
    if (!firstIn) {
        [self cusShowLoaingView];
    }
    BMKPlanNode *start = [[BMKPlanNode alloc] init];
    BMKPlanNode *end   = [[BMKPlanNode alloc] init];
    start.pt = startLocation;
    end.pt   = destinationLocation;
    BOOL flag;
    switch (mySearchType) {
        case searchBus: {
            BMKTransitRoutePlanOption *transitRouteSearchOption = [[BMKTransitRoutePlanOption alloc]init];
            transitRouteSearchOption.city = city;
            transitRouteSearchOption.from = start;
            transitRouteSearchOption.to   = end;
            flag = [routeSearch transitSearch:transitRouteSearchOption];
            
            break;
        }
        case searchWalk: {
            BMKWalkingRoutePlanOption *walkingRoutePlanOption = [[BMKWalkingRoutePlanOption alloc] init];
            walkingRoutePlanOption.from = start;
            walkingRoutePlanOption.to   = end;
            flag = [routeSearch walkingSearch:walkingRoutePlanOption];
            break;
        }
        case searchCar: {
            BMKDrivingRoutePlanOption*drivingRouteSearchOption = [[BMKDrivingRoutePlanOption alloc]init];
            drivingRouteSearchOption.from = start;
            drivingRouteSearchOption.to   = end;
            flag = [routeSearch drivingSearch:drivingRouteSearchOption];
            break;
        }
        default:
            break;
    }
    
    if(flag) {
        //搜索发起成功
        
    }else {
        //搜索发起失败
        [self cusHideLoaingView];
        maptype   = mapBadService;
        routeInfo = [[NSMutableArray alloc] init];
        [self->dataTableView reloadData];
    }
    
}
#pragma mark -
#pragma searchDelegate
- (void)didUpdateUserLocation:(BMKUserLocation *)userLocation {
    if (userLocation.location!=nil) {
        startLocation = userLocation.location.coordinate;
    }else{
        [locService startUserLocationService];
        MSLog(@"重新开始定位,如需处理请在此!");
    }
    [self getLocation];
    [locService stopUserLocationService];
}

- (void)didFailToLocateUserWithError:(NSError *)error {
    [locService startUserLocationService];
    MSLog(@"重新开始定位,如需处理请在此!");
}

- (void)onGetTransitRouteResult:(BMKRouteSearch*)searcher result:(BMKTransitRouteResult*)result errorCode:(BMKSearchErrorCode)error
{
    [self cusHideLoaingView];
    if (error == BMK_SEARCH_NO_ERROR) {
        [self getBusResult:result];
    }else{;
        maptype=mapNoResult;
        [self->dataTableView reloadData];
    }
    
}
- (void)onGetWalkingRouteResult:(BMKRouteSearch *)searcher result:(BMKWalkingRouteResult *)result errorCode:(BMKSearchErrorCode)error {
    [self cusHideLoaingView];
    if (error == BMK_SEARCH_NO_ERROR) {
        [self getWalkResult:result];
    }else{
        
        maptype=mapNoResult;
        [self->dataTableView reloadData];
    }
}
- (void)onGetDrivingRouteResult:(BMKRouteSearch *)searcher result:(BMKDrivingRouteResult *)result errorCode:(BMKSearchErrorCode)error {
    [self cusHideLoaingView];
    if (error == BMK_SEARCH_NO_ERROR) {
        [self getCarResult:result];
    }else{
        maptype = mapNoResult;
        [self->dataTableView reloadData];
    }
}

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error {
    [self cusHideLoaingView];
    firstIn = NO;
    if (error == 0) {
        startLable.text = result.address;
        city=result.addressDetail.city;
        [self beginSearch];
    }else{
        startLable.text = @"定位失败";
        maptype = mapBadService;
        [self->dataTableView reloadData];
    }
}

#pragma mark -
#pragma mark searchData

- (void)getBusResult:(BMKTransitRouteResult*)result {
    
    routeInfo = [[NSMutableArray alloc] init];
    if (result.routes.count==0) {
        return ;
    }else {
        for(BMKTransitRouteLine* plan in result.routes) {
            
            NSMutableArray*busStopNameArr=[[NSMutableArray alloc] init];
            int busStopCount = 0;
            int distance     = plan.distance;
            BMKTime*time     = plan.duration;
            for (int i=0; i<plan.steps.count; i++) {
                BMKTransitStep* transitStep = [plan.steps objectAtIndex:i];
                if (transitStep.stepType==BMK_BUSLINE ||transitStep.stepType==BMK_SUBWAY) {
                    [busStopNameArr addObject:transitStep.vehicleInfo.title];
                    busStopCount+=transitStep.vehicleInfo.passStationNum;
                }
            }
            
            NSString*busStopName = [busStopNameArr componentsJoinedByString:@"-"];
            NSDictionary*curResult=@{@"busStopName":busStopName,
                                     @"busStopCount":[NSString stringWithFormat:@"%i",busStopCount],
                                     @"distance":[NSString stringWithFormat:@"%@",[MSUtil covertDistance:distance]],
                                     @"time":time,
                                     @"plan":plan
                                     };
            [routeInfo addObject:curResult];
        }
        
    }
    [self->dataTableView reloadData];
}
- (void)getWalkResult:(BMKWalkingRouteResult*)result {
    routeInfo = [[NSMutableArray alloc] init];
    BMKWalkingRouteLine* plan = result.routes[0];//现在只返回一条
    int distance = plan.distance;
    BMKTime*time = plan.duration;
    //???   这里taxi都是0元 why
    //int taxiPrice=result.taxiInfo.totalPrice;
    int taxiPrice=10+(distance/1000)*3;
    NSDictionary*curResult=@{@"title":[NSString stringWithFormat:@"%@  %@",[self getTime:time],[MSUtil covertDistance:distance]],
                             @"taxiPrice":[NSString stringWithFormat:@"打车约%i元",taxiPrice],
                             @"plan":plan
                             };
    [routeInfo addObject:curResult];
    turnInfo = [[NSMutableArray alloc] init];
    for (int i=0; i<plan.steps.count; i++) {
        BMKWalkingStep* transitStep = [plan.steps objectAtIndex:i];
        [turnInfo addObject:transitStep.entraceInstruction];
    }
    [self->dataTableView reloadData];
    
}

- (void)getCarResult:(BMKDrivingRouteResult*)result {
    routeInfo=[[NSMutableArray alloc] init];
    BMKDrivingRouteLine* plan=result.routes[0];
    int distance=plan.distance;
    BMKTime*time=plan.duration;
    int taxiPrice=10+(distance/1000)*3;
    NSDictionary*curResult=@{@"title":[NSString stringWithFormat:@"%@  %@",[self getTime:time],[MSUtil covertDistance:distance]],
                             @"taxiPrice":[NSString stringWithFormat:@"打车约%i元",taxiPrice],
                             @"plan":plan
                             };
    [routeInfo addObject:curResult];
    
    turnInfo=[[NSMutableArray alloc] init];
    for (int i=0; i<plan.steps.count; i++){
        BMKDrivingStep* transitStep = [plan.steps objectAtIndex:i];
        [turnInfo addObject:transitStep.entraceInstruction];
    }
    [self->dataTableView reloadData];
}

- (NSString*)getTime:(BMKTime*)bTime {
    NSString*timeTip=@"";
    if (bTime.dates) {
        timeTip=[NSString stringWithFormat:@"%i天",bTime.dates];
    }
    if (bTime.hours) {
        timeTip=[NSString stringWithFormat:@"%@%i小时",timeTip,bTime.hours];
    }
    if (bTime.minutes) {
        timeTip=[NSString stringWithFormat:@"%@%i分钟",timeTip,bTime.minutes];
    }
    return timeTip;
}

- (UIImage*)getTurnImgeWithStr:(NSString*)turnStr {
    
    NSDictionary *turnImage=@{@"靠左":@"walk_turn_littleLeft",
                              @"左前":@"walk_turn_littleLeft",
                              @"靠右":@"walk_turn_littleRight",
                              @"右前":@"walk_turn_littleRight",
                              @"左转":@"walk_turn_left",
                              @"右转":@"walk_turn_right",
                              @"调头":@"walk_turn_back",
                              @"直行":@"walk_turn_go",
                              @"直走":@"walk_turn_go",
                              @"向前":@"walk_turn_go",
                              @"default":@"walk_turn_default"
                              };
    
    for(int i=0;i<turnImage.allKeys.count;i++){
        if([turnStr rangeOfString:turnImage.allKeys[i]].location!=NSNotFound){
            return [UIImage imageNamed:turnImage[turnImage.allKeys[i]]];
        }
    }
    return [UIImage imageNamed:turnImage[@"default"]];
}
#pragma mark -
#pragma mark TableViewDelegate
- (void)doReload {
    maptype   = mapNone;
    routeInfo = [[NSMutableArray alloc] init];
    turnInfo  = [[NSMutableArray alloc] init];
    [self->dataTableView reloadData];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (maptype!=mapNone||indexPath.section!=0) {
        return;
    }else {
        NSDictionary *curRouteDic = [routeInfo objectAtIndex:indexPath.row];
        NSString *subTitle;
        NSString *title;
        if (mySearchType==searchBus) {
            subTitle=[self getSubTitle:curRouteDic];
            title = curRouteDic[@"busStopName"];
        }else{
            subTitle = curRouteDic[@"taxiPrice"];
            title    = curRouteDic[@"title"];
        }
        ShowLineViewController *showLineView = [[ShowLineViewController alloc] init];
        showLineView.info = @{@"title":title,@"subTitle":subTitle,@"plan":curRouteDic[@"plan"]};
        showLineView.mySearchType = mySearchType;
        [self.navigationController pushViewController:showLineView animated:YES];
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (maptype==mapNone&&mySearchType!=searchBus) {
        return 2;
    }
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (maptype==mapNone) {
        if (section==0) {
            return routeInfo.count;
        }else {
            return turnInfo.count;
        }
        
    }else{
        return 1;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(maptype!=mapNone) {
        return self->dataTableView.height;
    }else {
        if (indexPath.section==0) {
            return 70;
        }else {
            return 30;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (maptype!=mapNone) {

        ListNoResultCell *noResultCell = [tableView ListNoResultCell];
        noResultCell.width = screenWidth;
        if (maptype==mapNoResult) {
            [noResultCell setInfo:MapNoResult position:screenHeight/4-50];
        }else if(maptype==mapBadNetWork) {
            [noResultCell setInfo:MapBadNetWork position:screenHeight/4-50];
        }else if(maptype==mapBadService) {
            [noResultCell setInfo:MapBadService position:screenHeight/4-50];
        }
        return noResultCell;
    }
    if (indexPath.section==0) {
        BusInfoCell *cell=[tableView BusInfoCell];
        NSDictionary*curRouteDic=[routeInfo objectAtIndex:indexPath.row];
        if (mySearchType==searchBus) {
            cell.title.text      = curRouteDic[@"busStopName"];
            cell.subTitle.text   = [self getSubTitle:curRouteDic];
            cell.lineView.hidden = NO;
        }
        if (mySearchType==searchCar||mySearchType==searchWalk) {
            if (indexPath.section==0) {
                cell.title.text    = curRouteDic[@"title"];
                cell.subTitle.text = curRouteDic[@"taxiPrice"];
                cell.lineView.hidden=YES;
            }
            
        }
        return cell;
    }else {
        static NSString *cellWithIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellWithIdentifier];
        if(nil==cell) {
            cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1   reuseIdentifier:cellWithIdentifier];
        }
        cell.textLabel.text          = [turnInfo objectAtIndex:indexPath.row];
        cell.textLabel.font          = [UIFont systemFontOfSize:12];
        cell.textLabel.textColor     = titleLableColor;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 2;
        cell.imageView.image         = [self getTurnImgeWithStr:turnInfo[indexPath.row]];
        cell.selectionStyle          = UITableViewCellSelectionStyleNone;
        
        return cell;
        
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section==1&&turnInfo.count>0) {
        return 30.f;
    }
    return 0.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self->dataTableView.width, 30)];
    headView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    UILabel *headLable = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 150, 20)];
    headLable.font      = [UIFont systemFontOfSize:14];
    headLable.text      = @"路线规划";
    headLable.textColor = titleLableColor;
    headLable.centerY   = headView.height/2;
    [headView addSubview:headLable];
    if (section==1&&turnInfo.count>0) {
        return headView;
    }
    return nil;
}
- (NSString*)getSubTitle:(NSDictionary*)subInfo {
    NSMutableArray*subTitleArr = [[NSMutableArray alloc] init];
    [subTitleArr addObject:[NSString stringWithFormat:@"总站数:%@",subInfo[@"busStopCount"]]];
    [subTitleArr addObject:[NSString stringWithFormat:@"大约用时:%@",[self getTime:subInfo[@"time"]]]];
    [subTitleArr addObject:[NSString stringWithFormat:@"距离%@米",subInfo[@"distance"]]];
    NSString*subTitle = [subTitleArr componentsJoinedByString:@" | "];
    return subTitle;
}

- (void)initView {
    
    self.view.BackgroundColor = [UIColor groupTableViewBackgroundColor];
    showWayBtnChoosedImages   = @[@"btnBus_choose",@"btnWalk_choose",@"btnCar_choose"];
    showWayBtnUnChooseImages = @[@"btnBus_unchoose",@"btnWalk_unchoose",@"btnCar_unchoose"];
    
    NSArray *btnTitleArr = @[@"公交",@"步行",@"自驾"];
    
    topView    = [[UIView alloc] initWithFrame:CGRectMake(0, 64, screenWidth, 110)];
    startLable = [[UILabel alloc]initWithFrame:CGRectMake(35, 10, screenWidth-100, 30)];
    destinationLable   = [[UILabel alloc]initWithFrame:CGRectMake(35, 45, screenWidth-100, 20)];
    chooseCustomPositionBtn  = [[UIButton alloc]initWithFrame:CGRectMake(35, 10, screenWidth-50, 30)];
    [chooseCustomPositionBtn addTarget:nil action:@selector(chooseLocationInMap) forControlEvents:UIControlEventTouchUpInside];
    
    startLable.Font                     = [UIFont systemFontOfSize:13];
    destinationLable.Font               = [UIFont systemFontOfSize:13];
    startLable.textColor                = titleLableColor;
    destinationLable.textColor          = subTitleLableColor;
    startLable.text                     = @"正在为您定位";
    
    destinationLable.text               = self.mapSearchViewInfo.destinationName;
    
    chooseCustomPositionImageView       = [[UIImageView alloc] initWithFrame:CGRectMake(screenWidth-70, 10, 40, 30)];
    chooseCustomPositionImageView.image = [UIImage imageNamed:@"searchPos"];
    chooseCustomPositionImageView.tag   = searchPosImgDefaultTag;
    changeStartDestinationBtn           = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 70)];
    
    [changeStartDestinationBtn addTarget:nil action:@selector(changePos) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *changePosImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 25, 12, 22)];
    changePosImage.image        = [UIImage imageNamed:@"changePos"];
    topView.backgroundColor     = [UIColor whiteColor];
    UIImageView *topPointImage  = [[UIImageView alloc]initWithFrame:CGRectMake(10, 15, 10, 52)];
    topPointImage.image         =[UIImage imageNamed:@"topPoint"];
    UIView *startToEndLineView  = [[UIView alloc]initWithFrame:CGRectMake(35, 40, screenWidth-50, 0.5)];
    startToEndLineView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"splitbg"]];
    
    [topView addSubview:chooseCustomPositionImageView];
    [topView addSubview:startToEndLineView];
    [topView addSubview:startLable];
    [topView addSubview:destinationLable];
    [topView addSubview:chooseCustomPositionBtn];
    [topView addSubview:changeStartDestinationBtn];
    [topView addSubview:changePosImage];
    topView.layer.shadowColor  = [UIColor blackColor].CGColor;
    topView.layer.shadowRadius = 2.0f;
    
    [self.view addSubview:topView];
    
    showWayImageViews = [[NSMutableArray alloc]init];
    showWayDownLineView   = [[NSMutableArray alloc]init];
    UIView*btnView = [[UIView alloc]initWithFrame:CGRectMake(0, btnPosition, screenWidth, btnHeigh)];
    
    for(int i=0;i<btnTitleArr.count;i++) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(i*(screenWidth/3), 0, screenWidth/3, 50)];
        btn.tag =i+100;
        [btn addTarget:self action:@selector(changeSearch:) forControlEvents:UIControlEventTouchUpInside];
        
        float positionX = screenWidth*(CGFloat)((2.0f*i+1.0f)/6.0f);
        UIImageView *cur_ImageView = [[UIImageView alloc]initWithFrame:CGRectMake(positionX- 20 , 0, 40,40)];
        UIView *lineView;
        if (i==0) {
            lineView = [[UIView alloc ]initWithFrame:CGRectMake(5, 37, screenWidth/3.0f-5, 3)];
            cur_ImageView.image      = [UIImage imageNamed:showWayBtnChoosedImages[i]];
            lineView.backgroundColor = [UIColor colorWithRed:122/255.0f green:124/255.0f blue:128/255.0f alpha:1.0f];
            
        }else if (i==1) {
            lineView  =[[UIView alloc]initWithFrame:CGRectMake(screenWidth/3.0f, 37,screenWidth/3.0f, 3)];
            cur_ImageView.image      = [UIImage imageNamed:showWayBtnUnChooseImages[i]];
            lineView.backgroundColor = [UIColor clearColor];
            
        }else {
            lineView = [[UIView alloc ]initWithFrame:CGRectMake(2*screenWidth/3.0f, 37,screenWidth/3.0f-5,3)];
            cur_ImageView.image      = [UIImage imageNamed:showWayBtnUnChooseImages[i]];
            lineView.backgroundColor = [UIColor clearColor];
            
        }
        UIView*cutLineView = [[UIView alloc] initWithFrame:CGRectMake(i*screenWidth/3.0f, 5, 0.5, 30)];
        cutLineView.backgroundColor = [UIColor colorWithRed:200/255.0f green:200/255.0f blue:200/255.0f alpha:1.0f];
        
        cur_ImageView.contentMode     = UIViewContentModeCenter;
        cur_ImageView.backgroundColor = [UIColor clearColor];
        [showWayImageViews addObject:cur_ImageView];
        
        UIView* topLineView = [[UIView alloc]initWithFrame:CGRectMake(0, -0.5, screenWidth, 0.5)];
        topLineView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"splitbg"]];
        
        [btnView addSubview:btn];
        [btnView addSubview:topLineView];
        btnView.backgroundColor = [UIColor colorWithRed:248/255.0f green:248/255.0f blue:248/255.0f alpha:1.0f];
        [btnView addSubview:lineView];
        [showWayDownLineView addObject:lineView];
        [btnView addSubview:cur_ImageView];
        [btnView addSubview:cutLineView];
        
    }
    
    self->dataTableView =[[UITableView alloc] initWithFrame:CGRectMake(0, 184, screenWidth, screenHeight-164)];
    dataTableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    dataTableView.delegate        = self;
    dataTableView.dataSource      = self;
    dataTableView.backgroundColor = [UIColor whiteColor];
    
    [topView addSubview:btnView];
    [self.view addSubview:dataTableView];
    
}

- (void)back {
    if(self.mapSearchViewInfo.isFromCell) {
        self.navigationController.navigationBar.alpha = 0;
    } else {
        self.navigationController.navigationBar.alpha = 1.f;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    routeSearch.delegate   = nil;
    geocodesearch.delegate = nil;
    locService.delegate    = nil;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    routeSearch.delegate   = self;
    geocodesearch.delegate = self;
    locService.delegate    = self;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
- (void)dealloc {
    routeSearch.delegate   = nil;
    routeSearch            = nil;
    geocodesearch.delegate = nil;
    geocodesearch          = nil;
    locService.delegate    = nil;
    locService             = nil;
    MSLog(@"mapSearchView dealloc");
}
@end

@implementation MapSearchViewInfo

+ (instancetype)mapSearchViewInfoMakeWithName:(NSString *)aDestinationName andLocation:(CLLocationCoordinate2D)aDestinationLocation andIsFromCell:(BOOL)aIsFromCell andRemarkInfo:(MapSearchViewInfo *)aRemarkInfo {
    
    MapSearchViewInfo*mapSearchViewInfo   = [[MapSearchViewInfo alloc] init];
    mapSearchViewInfo.destinationName     = aDestinationName;
    mapSearchViewInfo.destinationLocation = aDestinationLocation;
    mapSearchViewInfo.isFromCell          = aIsFromCell;
    mapSearchViewInfo.remarkInfo          = aRemarkInfo;
    return mapSearchViewInfo;
}


@end
