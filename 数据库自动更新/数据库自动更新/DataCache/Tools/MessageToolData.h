//
//  ToolData.h
//  Jump
//
//  Created by peter.zhang on 2017/4/19.
//  Copyright © 2017年 redstar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "People.h"
#import "Car.h"
#import "House.h"

@interface MessageToolData : NSObject


/**
 创建缓存的表
 */
+ (void)creatTable;


#pragma mark -----------------People
/**
 插入People数据
 
 @param  model 解析的数据源
 */
+ (void)insertDataToPeopleTable:(People *)model;


/**
 从数据库中加载数据
 
 @return 数据源数组
 */
+ (NSArray *)peopleDataLoadFromeDBWithArray:(NSArray *)modelArray;

/**
 删除数据表数据
 
 @return 是否删除成功
 */
+ (BOOL)deletPeopleTable;


#pragma mark -----------------Car
/**
 插入Car数据
 
 @param  model 解析的数据源
 */
+ (void)insertDataToCarTable:(Car *)model;


/**
 从数据库中加载数据
 
 @return 数据源数组
 */
+ (NSArray *)carDataLoadFromeDBWithArray:(NSArray *)modelArray;

/**
 删除数据表数据
 
 @return 是否删除成功
 */
+ (BOOL)deletCarTable;



#pragma mark -----------------House
/**
 插入House数据
 
 @param  model 解析的数据源
 */
+ (void)insertDataToHouseTable:(House *)model;


/**
 从数据库中加载数据
 
 @return 数据源数组
 */
+ (NSArray *)houseDataLoadFromeDBWithArray:(NSArray *)modelArray;

/**
 删除数据表数据
 
 @return 是否删除成功
 */
+ (BOOL)deletHouseTable;

@end
