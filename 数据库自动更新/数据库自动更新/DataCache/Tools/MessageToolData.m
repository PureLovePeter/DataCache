//
//  ToolData.m
//  Jump
//
//  Created by peter.zhang on 2017/4/19.
//  Copyright © 2017年 redstar. All rights reserved.
//

#import "MessageToolData.h"
#import "MessageFMDB.h"
#import "FMDB.h"

@implementation MessageToolData

+ (void)creatTable{
    NSMutableArray *mutArray = [NSMutableArray array];
    
    /**------>>此处创建对象添加需要缓存的表,加入到数组中-----**/
    People *people = [[People alloc]init];
    [mutArray addObject:people];
    
    Car *car = [[Car alloc]init];
    [mutArray addObject:car];
    
//    House *house = [[House alloc]init];
//    [mutArray addObject:house];

    /**数据库自动检查字段和表存不存在的更新**/
    [[MessageFMDB sharedMessageFMDB] createCacheTableWithModelArray:[mutArray copy]];
}

+ (void)insertDataToPeopleTable:(People *)model{
    BOOL isExist = [[MessageFMDB sharedMessageFMDB] juglePeopleIsExist:model];
    //更新
    if (isExist) {
        [[MessageFMDB sharedMessageFMDB] updateIMPeopleTable:model];
    }else{//加入
        [[MessageFMDB sharedMessageFMDB] insertIMPeopleTable:model];
    }
}


+ (NSArray *)peopleDataLoadFromeDBWithArray:(NSArray *)modelArray{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    NSMutableArray *data = [NSMutableArray array];
    if ([db open]) {
        for (People *model in modelArray) {
            NSString * sql = [NSString stringWithFormat:@"select * from People where userId = %ld ",model.userID] ;
            FMResultSet * rs = [db executeQuery:sql];
            while ([rs next])
            {
                model.name = [rs stringForColumn:@"name"];
                model.age = [NSNumber numberWithInt:[rs intForColumn:@"age"]];
                model.gender = [NSNumber numberWithInt:[rs intForColumn:@"gender"]];
                model.color =[rs stringForColumn:@"color"];
            }
            [rs close];
            [data addObject:model];
        }
        [db close];
    }
    return data;
}


+ (BOOL)deletPeopleTable{
   return  [[MessageFMDB sharedMessageFMDB] deleteTableWithTanleName:@"People"];
}

#pragma mark -----------------Car
/**
 插入Car数据
 
 @param  model 解析的数据源
 */
+ (void)insertDataToCarTable:(Car *)model{
    BOOL isExist = [[MessageFMDB sharedMessageFMDB] jugleCarIsExist:model];
    //更新
    if (isExist) {
        [[MessageFMDB sharedMessageFMDB] updateIMCarTable:model];
    }else{//加入
        [[MessageFMDB sharedMessageFMDB] insertIMCarTable:model];
    }
}


/**
 从数据库中加载数据
 
 @return 数据源数组
 */
+ (NSArray *)carDataLoadFromeDBWithArray:(NSArray *)modelArray{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    NSMutableArray *data = [NSMutableArray array];
    if ([db open]) {
        for (Car *model in modelArray) {
            NSString * sql = [NSString stringWithFormat:@"select * from Car where userId = %ld ",model.userID] ;
            FMResultSet * rs = [db executeQuery:sql];
            while ([rs next])
            {
                model.size = [rs stringForColumn:@"size"];
                model.money = [NSNumber numberWithLong:[rs longForColumn:@"money"]];
                model.brand = [rs stringForColumn:@"brand"];
                model.color =[rs stringForColumn:@"color"];
            }
            [rs close];
            [data addObject:model];
        }
        [db close];
    }
    return data;
}

/**
 删除数据表数据
 
 @return 是否删除成功
 */
+ (BOOL)deletCarTable{
    return  [[MessageFMDB sharedMessageFMDB] deleteTableWithTanleName:@"Car"];
}



#pragma mark -----------------House
/**
 插入House数据
 
 @param  model 解析的数据源
 */
+ (void)insertDataToHouseTable:(House *)model{
    BOOL isExist = [[MessageFMDB sharedMessageFMDB] jugleHouseIsExist:model];
    //更新
    if (isExist) {
        [[MessageFMDB sharedMessageFMDB] updateIMHouseTable:model];
    }else{//加入
        [[MessageFMDB sharedMessageFMDB] insertIMHouseTable:model];
    }
}


/**
 从数据库中加载数据
 
 @return 数据源数组
 */
+ (NSArray *)houseDataLoadFromeDBWithArray:(NSArray *)modelArray{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    NSMutableArray *data = [NSMutableArray array];
    if ([db open]) {
        for (House *model in modelArray) {
            NSString * sql = [NSString stringWithFormat:@"select * from House where userId = %ld ",model.userID] ;
            FMResultSet * rs = [db executeQuery:sql];
            while ([rs next])
            {
                model.size = [rs stringForColumn:@"size"];
                model.money = [NSNumber numberWithLong:[rs longForColumn:@"money"]];
                model.city = [rs stringForColumn:@"city"];
                model.color = [rs stringForColumn:@"color"];
                model.number = [NSNumber numberWithInt:[rs intForColumn:@"number"]];
            }
            [rs close];
            [data addObject:model];
        }
        [db close];
    }
    return data;
}

/**
 删除数据表数据
 
 @return 是否删除成功
 */
+ (BOOL)deletHouseTable{
    return  [[MessageFMDB sharedMessageFMDB] deleteTableWithTanleName:@"House"];
}
@end
