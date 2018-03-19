//
//  CashFMDB.h
//  iOS-HR
//
//  Created by peter on 16/5/10.
//  Copyright © 2016年 headhunter-HR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "People.h"
#import "Car.h"
#import "House.h"

#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define kCacheDBPath [PATH_OF_DOCUMENT stringByAppendingPathComponent:@"demo.sqlite"]
#define kUpdateMarginTime (0)

@interface MessageFMDB : NSObject

/**
 创建一个单利的数据库更新类

 @return 单利类
 */
+ (instancetype)sharedMessageFMDB;


/**
 创建数据库缓存表

 @param modelArray 需要缓存的数据库对象数组
 */
- (void)createCacheTableWithModelArray:(NSArray *)modelArray;


/**
 更新表的发布时间
 
 @param PublishTime 发布时间
 */
- (void)updateTableName:(NSString *)tableName PublishTime:(int64_t)PublishTime;


/**
 插入表数据
 
 @param tableModle modle
 @param updateArray
 @return 是否成功插入数据
 例子：
 - (void)insertDataToPositionTableFromArray:(NSArray *)array
 {
     if (!array.count) {
     return;
     }
     PositionTable *positionTable = [[PositionTable alloc]init];
     转化为需要储存的数组中的数组
     NSArray *changeArray = [positionTable modleWithModle:array];
     插入数据
     [self insertDataWithTable:positionTable updateArray:changeArray];
 }
 */
- (BOOL)insertDataWithTable:(id)tableModle updateArray:(NSArray *)updateArray;


/**
 清空表内容

 @param tableName 表名字
 @return 是否成功清空
 */
- (BOOL)deleteTableWithTanleName:(NSString *)tableName;


#pragma mark ----------------people-----------

/**
 判断用户是否存在

 @param model People
 @return 是否存在
 */
- (BOOL)juglePeopleIsExist:(People *)model;


/**
 更新People表

 @param model People
 */
- (void)updateIMPeopleTable:(People *)model;



/**
 插入People数据

 @param model People
 */
- (void)insertIMPeopleTable:(People *)model;



#pragma mark ----------------Car-----------

/**
 判断用户是否存在
 
 @param model Car
 @return 是否存在
 */
- (BOOL)jugleCarIsExist:(Car *)model;


/**
 更新Car表
 
 @param model Car
 */
- (void)updateIMCarTable:(Car *)model;



/**
 插入Car数据
 
 @param model Car
 */
- (void)insertIMCarTable:(Car *)model;



#pragma mark ----------------House-----------

/**
 判断用户是否存在
 
 @param model House
 @return 是否存在
 */
- (BOOL)jugleHouseIsExist:(House *)model;


/**
 更新House表
 
 @param model House
 */
- (void)updateIMHouseTable:(House *)model;



/**
 插入House数据
 
 @param model House
 */
- (void)insertIMHouseTable:(House *)model;


@end
