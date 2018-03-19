//
//  CashFMDB.m
//  iOS-HR
//
//  Created by peter on 16/5/10.
//  Copyright © 2016年 headhunter-HR. All rights reserved.
//

#import "MessageFMDB.h"
#import "FMDB.h"
#import "handleMessage.h"

@implementation MessageFMDB

//创建CacheFMDB类的对象
static MessageFMDB* _instance = nil;
+ (instancetype)sharedMessageFMDB
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init] ;
        
    }) ;
    return _instance ;
}

/**
 创建首页候选人表格，包含 新推荐和待处理
 */
- (void)createCacheTableWithModelArray:(NSArray *)modelArray
{
    if (!modelArray.count) {
        return;
    }
    NSLog(@"缓存数据库路径:%@",kCacheDBPath);

    handleMessage *handel = [[handleMessage alloc]init];
    NSMutableArray * mutArray = [NSMutableArray array];
    for (id obj in modelArray) {
        NSString * sqlString = [handel sqliteStingWithTableName:NSStringFromClass([obj class]) model:obj];
        [mutArray addObject:sqlString];
    }
    /**删除旧的聊天表**/
    NSString * doc = PATH_OF_DOCUMENT;
    NSString * path = [doc stringByAppendingPathComponent:@"users.sqlite"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
    //判断数据库路径是否存在，是否需要新增数据库表
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:kCacheDBPath]) {
        FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
        if ([db open]) {
            [db beginTransaction];
            BOOL res = true;
            @try {
                for (NSString * string in mutArray) {
                    [db executeUpdate:string];
                }
            }
            @catch (NSException *exception) {
                res = false;
                [db rollback];
            }
            @finally {
                if (res && [db commit]) {
                    NSLog(@"succ to creating db table");
                }else{
                    NSLog(@"error when creating db table");
                }
            }
            [db close];
        } else {
            NSLog(@"error when open db");
        }
    }else if([self needUpdateTabelArray:modelArray]) {
        //需要更新的表的名字
        NSArray *tabelName = [self needUpdateTable:modelArray];
        //新建数据表
        [self createNewTable:tabelName modelArray:modelArray];
    }else{
        NSLog(@"缓存数据库已经存在路径,不需要新增数据库表:%@",kCacheDBPath);
    }
    //自动更新机制 表的对应的model变化，需要对表做相应的增加和删除操做
    for (NSObject *obj in modelArray) {
        //runtime 获取现有model的所有属性string
        NSArray *array = [handel ivarsArrayWithModel:obj];
        //对比数据库和现有的属性sting
        [self checkAndUpdateTable:obj newAttribe:array];
    }
}


/**
 多个表是不是要更新

 @param array 更新表的数组
 @return 是否需要更新
 */
- (BOOL)needUpdateTabelArray:(NSArray *)array{
    for (NSObject *obj in array) {
        NSString *string = NSStringFromClass([obj class]);
        if(![self needUpdateTabel:string]) {
            return YES;
        }
    }
    return NO;
}

/**
 需要更新哪些表

 @param array 需要更新表的数组
 @return 有哪些字段
 */
- (NSArray *)needUpdateTable:(NSArray*)array{
    NSMutableArray *mut = [NSMutableArray array];
    for (NSObject *obj in array) {
        NSString *string = NSStringFromClass([obj class]);
        if (![self needUpdateTabel:string]) {
            [mut addObject:string];
        }
    }
    return [mut copy];
}

/**
 新增表

 @param array 表名字数组
 */
- (void)createNewTable:(NSArray *)array modelArray:(NSArray *)modelArray{
    for (NSObject *obj in modelArray) {
        NSString *string = NSStringFromClass([obj class]);
        if ([array containsObject:string]) {
            handleMessage *handel = [[handleMessage alloc]init];
            NSString * tableSqilet = [handel sqliteStingWithTableName:NSStringFromClass([obj class]) model:obj];
            [self createATable:tableSqilet];
        }
    }
}


/**
 创建一个表

 @param string 新建立表的语句
 */
- (void)createATable:(NSString *)string{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        [db executeUpdate:string];
        [db close];
    }
}

/**
 检查数据库的表是否存在

 @param tableName 表名字
 @return 需不需要更新表
 */
- (BOOL)needUpdateTabel:(NSString *)tableName{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL need = NO;
    if ([db open]) {
        //得到所有的表表名
        FMResultSet *rs = [db executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", tableName];
        
        while ([rs next])
        {
            // just print out what we've got in a number of formats.
            NSInteger count = [rs intForColumn:@"count"];
            if (0 == count)
            {
                need = NO;
            }
            else
            {
                need = YES;
            }
        }
        [rs close];
        [db close];
    }
    return need;
}


/**
 判断新老表中有没有新增字段

 @param objName 表名字
 @param newAttribe 新的属性
 */
- (void)checkAndUpdateTable:(NSObject*)objName newAttribe:(NSArray *)newAttribe{
    //数据库中现有的字段
    NSMutableArray *sqliteArray = [NSMutableArray array];
    NSString *tableName = NSStringFromClass([objName class]);
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        NSString * sql = [NSString stringWithFormat:@"select * from %@",tableName] ;
        FMResultSet * rs = [db executeQuery:sql];
        NSDictionary * dict =   [rs columnNameToIndexMap];
        [sqliteArray addObjectsFromArray:[dict allKeys]];
        [db close];
    }
    //需要更新的字段
    NSMutableArray *needUpdateName =[NSMutableArray array];
    for (NSString *string in newAttribe) {
        NSString * lowercaseString = [string lowercaseString];
        if (![sqliteArray containsObject:lowercaseString]) {
            [needUpdateName addObject:string];
        }
    }
    handleMessage *handel = [[handleMessage alloc]init];
    if (needUpdateName.count > 0) {
        NSArray *array = [handel attribleArray:needUpdateName model:objName];
        //更新
        [self updateTabelupdateString:array tableName:tableName];
    }
}


/**
 增加新的表字段
 @param updateArray 更新的表字段名
 @param tableName 表名
 */
- (void)updateTabelupdateString:(NSArray *)updateArray tableName:(NSString *)tableName{
    
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        for (NSString *updateString in updateArray) {
            NSString* SysMessageSql = [NSString stringWithFormat:@"alter table %@ add %@",tableName,updateString];
            BOOL resSysMessage = [db executeUpdate:SysMessageSql];
            if (resSysMessage) {
                NSLog(@"新增%@表字段%@成功",tableName,updateString);
            }else{
                NSLog(@"新增%@表字段%@失败",tableName,updateString);
            }
        }
        [db close];
    }
}

/**
 是否需要update相应的表格

 @param tableName 表名字
 @return 是否需要更新
 */
- (BOOL)isNeedUpdateTableName:(NSString *)tableName
{
    BOOL isNeedUpdate = NO;
    int64_t uid = 1008;
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ where userId = %lld",tableName,uid];
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next]) {
            long lastTime = [rs longForColumn:@"lastUpdateTime"];
            NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
            if (nowTime - lastTime > kUpdateMarginTime) {
                isNeedUpdate = YES;
            }
            break;
        }
        [rs close];
        [db close];
    }
    return isNeedUpdate;
}


/**
 判断数据库表是不是存在

 @param tableName 表名字
 @return 是否存在
 */
- (BOOL)jugeTableIsExistWithName:(NSString *)tableName{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL isExist = NO;
    int64_t uid = 1008;
    if ([db open]) {
        NSString * sql = [NSString stringWithFormat:@"select * from %@ where userId = %lld  ",tableName , uid ] ;
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next])
        {
            isExist = YES;
            break;
        }
        [rs close];
        [db close];
        
    }
    return isExist;

}

/**
 删除某个表
 
 @param tableName 表名字
 @return 删除是否成功
 */
- (BOOL)deleteTableWithTanleName:(NSString *)tableName{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL deletSeccess = NO;
    if ([db open]) {
        NSString *string = [NSString stringWithFormat:@"delete from %@ where 1=1",tableName];
        BOOL res = [db executeUpdate:string];
        if (!res) {
            deletSeccess = NO;
        } else {
            deletSeccess = YES;
        }
        [db close];
    }
    return deletSeccess;
}


/**
 更新表的发布时间
 
 @param PublishTime 发布时间
 */
- (void)updateTableName:(NSString *)tableName PublishTime:(int64_t)PublishTime{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        NSString *string = [NSString stringWithFormat:@"UPDATE %@ SET modifyTime = %lld",tableName,PublishTime];
        BOOL res = [db executeUpdate:string];
        if (!res) {
            NSLog(@"error to UPDATE db data");
        } else {
            NSLog(@"succ to UPDATE db data");
        }
        [db close];
    }
    
}

/**
 插入表数据
 
 @param tableModle modle
 @param updateArray
 @return 是否成功插入数据
 */
- (BOOL)insertDataWithTable:(id)tableModle updateArray:(NSArray *)updateArray{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL insertSccess = NO;
    if (updateArray.count > 0) {
        handleMessage *handel = [[handleMessage alloc]init];
        if ([db open]) {
            NSString * hunterSql = [handel insertStringWithTableName:NSStringFromClass([tableModle class]) model:tableModle];
            for (NSArray * array in updateArray) {
                insertSccess = [db executeUpdate:hunterSql withArgumentsInArray:array];
            }
            if (insertSccess) {
                NSLog(@"%@表插入数据成功",tableModle);
            }else{
                NSLog(@"%@表插入数据失败",tableModle);
            }
            [db close];
        }
    }
    return insertSccess;
    
}


/**
 判断用户是否存在
 
 @param model People 用户
 @return 是否存在
 */
- (BOOL)juglePeopleIsExist:(People *)model{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL find = NO;
    NSNumber *userId = @(model.userID);
    if ([db open]) {
        NSString * sql = @"SELECT COUNT(*) FROM People WHERE userID = ?";
        NSError *error;
        BOOL validateSQL = [db validateSQL:sql error:&error];
        if (validateSQL) {
            int count = [db intForQuery:sql,userId];
            if (count>0) {
                find = true;
            }
        }else{
            return false;
        }
        
        [db close];
    }
    return find;
}


/**
 更新People表
 
 @param model People 
 */
- (void)updateIMPeopleTable:(People *)model{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    handleMessage *handel = [[handleMessage alloc]init];
    BOOL insertSccess = NO;
    if ([db open]) {
        People *people = [[People alloc]init];
        NSString * hunterSql = [handel updateStringWithTableName:NSStringFromClass([people class]) model:people updateKey:@"userID"];
        /**转化为需要储存的数组中的数组**/
        NSArray *changeArray = [people modleWithModle:model];
        insertSccess = [db executeUpdate:hunterSql withArgumentsInArray:changeArray];
        if (insertSccess) {
            NSLog(@"%@表插入数据成功",people);
        }else{
            NSLog(@"%@表插入数据失败",people);
        }
        [db close];
    }
}



/**
 插入People数据
 
 @param model People 用户
 */
- (void)insertIMPeopleTable:(People *)model{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    handleMessage *handel = [[handleMessage alloc]init];
    BOOL insertSccess = NO;
    if ([db open]) {
        People *people = [[People alloc]init];
        NSString * hunterSql = [handel insertStringWithTableName:NSStringFromClass([people class]) model:people];
        /**转化为需要储存的数组中的数组**/
        NSArray *changeArray = [people modleWithModle:model];
        insertSccess = [db executeUpdate:hunterSql withArgumentsInArray:changeArray];
        if (insertSccess) {
            NSLog(@"%@表插入数据成功",people);
        }else{
            NSLog(@"%@表插入数据失败",people);
        }
        [db close];
    }
}

#pragma mark ----------------Car-----------

/**
 判断用户是否存在
 
 @param model Car
 @return 是否存在
 */
- (BOOL)jugleCarIsExist:(Car *)model{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL find = NO;
    NSNumber *userId = @(model.userID);
    if ([db open]) {
        NSString * sql = @"SELECT COUNT(*) FROM Car WHERE userID = ?";
        NSError *error;
        BOOL validateSQL = [db validateSQL:sql error:&error];
        if (validateSQL) {
            int count = [db intForQuery:sql,userId];
            if (count>0) {
                find = true;
            }
        }else{
            return false;
        }
        
        [db close];
    }
    return find;
}


/**
 更新Car表
 
 @param model Car
 */
- (void)updateIMCarTable:(Car *)model{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    handleMessage *handel = [[handleMessage alloc]init];
    BOOL insertSccess = NO;
    if ([db open]) {
        Car *car = [[Car alloc]init];
        NSString * hunterSql = [handel updateStringWithTableName:NSStringFromClass([car class]) model:car updateKey:@"userID"];
        /**转化为需要储存的数组中的数组**/
        NSArray *changeArray = [car modleWithModle:model];
        insertSccess = [db executeUpdate:hunterSql withArgumentsInArray:changeArray];
        if (insertSccess) {
            NSLog(@"%@表插入数据成功",car);
        }else{
            NSLog(@"%@表插入数据失败",car);
        }
        [db close];
    }
}



/**
 插入Car数据
 
 @param model Car
 */
- (void)insertIMCarTable:(Car *)model{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    handleMessage *handel = [[handleMessage alloc]init];
    BOOL insertSccess = NO;
    if ([db open]) {
        Car *car = [[Car alloc]init];
        NSString * hunterSql = [handel insertStringWithTableName:NSStringFromClass([car class]) model:car];
        /**转化为需要储存的数组中的数组**/
        NSArray *changeArray = [car modleWithModle:model];
        insertSccess = [db executeUpdate:hunterSql withArgumentsInArray:changeArray];
        if (insertSccess) {
            NSLog(@"%@表插入数据成功",car);
        }else{
            NSLog(@"%@表插入数据失败",car);
        }
        [db close];
    }
}



#pragma mark ----------------House-----------

/**
 判断用户是否存在
 
 @param model House
 @return 是否存在
 */
- (BOOL)jugleHouseIsExist:(House *)model{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL find = NO;
    NSNumber *userId = @(model.userID);
    if ([db open]) {
        NSString * sql = @"SELECT COUNT(*) FROM House WHERE userID = ?";
        NSError *error;
        BOOL validateSQL = [db validateSQL:sql error:&error];
        if (validateSQL) {
            int count = [db intForQuery:sql,userId];
            if (count>0) {
                find = true;
            }
        }else{
            return false;
        }
        
        [db close];
    }
    return find;
}


/**
 更新House表
 
 @param model House
 */
- (void)updateIMHouseTable:(House *)model{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    handleMessage *handel = [[handleMessage alloc]init];
    BOOL insertSccess = NO;
    if ([db open]) {
        House *house = [[House alloc]init];
        NSString * hunterSql = [handel updateStringWithTableName:NSStringFromClass([house class]) model:house updateKey:@"userID"];
        /**转化为需要储存的数组中的数组**/
        NSArray *changeArray = [house modleWithModle:model];
        insertSccess = [db executeUpdate:hunterSql withArgumentsInArray:changeArray];
        if (insertSccess) {
            NSLog(@"%@表插入数据成功",house);
        }else{
            NSLog(@"%@表插入数据失败",house);
        }
        [db close];
    }
}



/**
 插入House数据
 
 @param model House
 */
- (void)insertIMHouseTable:(House *)model{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    handleMessage *handel = [[handleMessage alloc]init];
    BOOL insertSccess = NO;
    if ([db open]) {
        House *house = [[House alloc]init];
        NSString * hunterSql = [handel insertStringWithTableName:NSStringFromClass([house class]) model:house];
        /**转化为需要储存的数组中的数组**/
        NSArray *changeArray = [house modleWithModle:model];
        insertSccess = [db executeUpdate:hunterSql withArgumentsInArray:changeArray];
        if (insertSccess) {
            NSLog(@"%@表插入数据成功",house);
        }else{
            NSLog(@"%@表插入数据失败",house);
        }
        [db close];
    }
}


@end
