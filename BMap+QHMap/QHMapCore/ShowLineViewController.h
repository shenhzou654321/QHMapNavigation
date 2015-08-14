//
//  ShowLineViewController.h
//  AmapTest
//
//  Created by imqiuhang on 14/11/15.
//  Copyright (c) 2014年 imqiuhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseMapViewController.h"

@interface ShowLineViewController : BaseMapViewController

/**info includes
 *title
 *subTitle
 *route
 */
@property (nonatomic,strong) NSDictionary * info;

@property (nonatomic,assign) searchType   mySearchType;



@end
