//
//  CashFMDB.m
//  iOS-HR
//
//  Created by peter on 16/5/10.
//  Copyright © 2016年 headhunter-HR. All rights reserved.
//

#import "CacheFMDB.h"
#import "FMDB.h"

#import "HRCandidate.h"
#import "handleSqliteTable.h"
#import "CandiateTable.h"
#import "PositionTable.h"
#import "CommonHunterTable.h"
#import "Position.h"
#import "Hunter.h"

//候选人表格路径
#define kCacheDBPath [PATH_OF_DOCUMENT stringByAppendingPathComponent:@"cacheDB.sqlite"]
#define kCacheCurrentVersion 0
#define kUpdateMarginTime (0)

#define kCandiateTable @"CandiateTable"

@implementation CacheFMDB


//创建CacheFMDB类的对象
static CacheFMDB* _instance = nil;
+ (instancetype)sharedCacheFMDB
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init] ;
        
    }) ;
    return _instance ;
}


//创建首页候选人表格，包含 新推荐和待处理
- (void)createCacheTable
{
    //类的model
    _modelArray = [NSMutableArray array];
    
    handleSqliteTable *handel = [[handleSqliteTable alloc]init];
    //候选人
    CandiateTable *candidate = [[CandiateTable alloc]init];
    [_modelArray addObject:candidate];
    NSString * candiateSql = [handel sqliteStingWithTableName:NSStringFromClass([candidate class]) model:candidate];
    //职位列表
    PositionTable *position = [[PositionTable alloc]init];
    [_modelArray addObject:position];
    NSString * positionSql = [handel sqliteStingWithTableName:NSStringFromClass([position class]) model:position];

    //常用猎头列表
    CommonHunterTable *hunter = [[CommonHunterTable alloc]init];
    [_modelArray addObject:hunter];
    NSString * hunterSql = [handel sqliteStingWithTableName:NSStringFromClass([hunter class]) model:hunter];
    
    //CandiateTable statusId 字段为控制 候选人表的 0新推荐、1面试待确认、2面试中、3简历待定、4面试待定、5已offer、6面试待安排、7已拒绝、8已入职、9已过保、10待处理(包含1-8的状态)
    
    //判断数据库路径是否存在，是否需要新增数据库表
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:kCacheDBPath]) {
        
        FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
        
        if ([db open]) {
            [db beginTransaction];
            BOOL res = true;
            @try {
                [db executeUpdate:candiateSql];
                [db executeUpdate:positionSql];
                [db executeUpdate:hunterSql];
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
    }else if([self needUpdateTabelArray:_modelArray]) {
//        NSLog(@"缓存数据库已经存在路径,但需要新增数据库表:%@",kCacheDBPath);
        //需要更新的表的名字
        NSArray *tabelName = [self needUpdateTable:_modelArray];
        //新建数据表
        [self createNewTable:tabelName];
    }else{
//        NSLog(@"缓存数据库已经存在路径,不需要新增数据库表:%@",kCacheDBPath);
    }
    //自动更新机制 表的对应的model变化，需要对表做相应的增加和删除操做
    for (NSObject *obj in _modelArray) {
        //runtime 获取现有model的所有属性string
        NSArray *array = [handel ivarsArrayWithModel:obj];
        //对比数据库和现有的属性sting
        [self checkAndUpdateTable:obj newAttribe:array];
    }
}

//多个表是不是要更新
- (BOOL)needUpdateTabelArray:(NSArray *)array{
    for (NSObject *obj in array) {
        NSString *string = NSStringFromClass([obj class]);
//        NSLog(@"=====%d",[self needUpdateTabel:string]);
        if(![self needUpdateTabel:string]) {
            return YES;
        }
    }
    return NO;
}

//需要更新哪些表
- (NSArray *)needUpdateTable:(NSArray*)array{
    NSMutableArray *mut = [NSMutableArray array];
    for (NSObject *obj in array) {
        NSString *string = NSStringFromClass([obj class]);
//        NSLog(@"=====%d",[self needUpdateTabel:string]);
        if (![self needUpdateTabel:string]) {
            [mut addObject:string];
        }
    }
    return [mut copy];
}

//新增表
- (void)createNewTable:(NSArray *)array{
    for (NSObject *obj in _modelArray) {
        NSString *string = NSStringFromClass([obj class]);
        if ([array containsObject:string]) {
            handleSqliteTable *handel = [[handleSqliteTable alloc]init];
            NSString * tableSqilet = [handel sqliteStingWithTableName:NSStringFromClass([obj class]) model:obj];
            [self createATable:tableSqilet];
        }
    }
}

//创建一个表
- (void)createATable:(NSString *)string{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        [db executeUpdate:string];
        [db close];
    }
}

//检查数据库的表是否存在
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
//            NSLog(@"缓存数据库isTableOK %ld", (long)count);
            
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



//判断新老表中有没有新增字段
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
    handleSqliteTable *handel = [[handleSqliteTable alloc]init];
    if (needUpdateName.count > 0) {
        NSArray *array = [handel attribleArray:needUpdateName model:objName];
        //更新
        [self updateTabelupdateString:array tableName:tableName];
    }
}
//增加新的表字段
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
 *  是否需要update相应的表格
 *
 *  @param tableName
 *
 *  @return 是否需要更新
 */
- (BOOL)isNeedUpdateTableName:(NSString *)tableName
{
    BOOL isNeedUpdate = NO;
    int64_t uid = [UserManeger shareInstance].currentUser.uid;
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

- (BOOL)isNeedUpdateCandidateTableWithStatusId:(int)statusId{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL isNeedUpdate = NO;
    int64_t uid = [UserManeger shareInstance].currentUser.uid;
    if ([db open]) {
        NSString * sql = [NSString stringWithFormat:@"select * from CandiateTable where userId = %lld and statusId = %d", uid, statusId] ;
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next])
        {
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



//删除CandiateTable数据
- (void)deleteCandiateTableDataWithStatusId:(int)statusId
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        NSString * sql = @"delete from CandiateTable where statusId = ?";
        BOOL res = [db executeUpdate:sql,[NSString stringWithFormat:@"%d",statusId]];
        if (!res) {
            NSLog(@"error to delete db data");
        } else {
            NSLog(@"succ to deleta db data");
        }
        [db close];
    }
}



//删除PositionTable数据
- (void)deletePositionTableData
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        BOOL res = [db executeUpdate:@"delete from PositionTable where 1=1"];
        if (!res) {
            NSLog(@"error to delete db data");
        } else {
            NSLog(@"succ to deleta db data");
        }
        [db close];
    }
}



//删除CommonHunterTable数据
- (void)deleteCommonHunterTableData
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        BOOL res = [db executeUpdate:@"delete from CommonHunterTable where 1=1"];
        if (!res) {
            NSLog(@"error to delete db data");
        } else {
            NSLog(@"succ to deleta db data");
        }
        [db close];
    }
}


- (BOOL)jugeTableIsExistWithStatusId:(int)statusId
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL isExist = NO;
    int64_t uid = [UserManeger shareInstance].currentUser.uid;
    if ([db open]) {
        NSString * sql = [NSString stringWithFormat:@"select * from CandiateTable where userId = %lld and statusId = %d ",uid ,statusId] ;
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

- (BOOL)jugeTableIsExistWithName:(NSString *)tableName{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL isExist = NO;
    int64_t uid = [UserManeger shareInstance].currentUser.uid;
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

- (NSArray *)loadTableDataWithStatusId:(int)statusId{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    NSMutableArray *data = [NSMutableArray array];
    int64_t uid = [UserManeger shareInstance].currentUser.uid;
    if ([db open]) {
        NSString * sql = [NSString stringWithFormat:@"select * from CandiateTable where userId = %lld and statusId = %d ",uid ,statusId] ;
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next])
        {
            HRCandidate *candidate = [[HRCandidate alloc]init];
            candidate.candidateId = [NSNumber numberWithLong:[rs longForColumn:@"candidateId"]];
            candidate.candidateStatus = [NSNumber numberWithInt:[rs intForColumn:@"candidateStatus"]];
            candidate.candidateAvatar = [rs stringForColumn:@"candidateAvatar"];
            candidate.candidateName = [rs stringForColumn:@"candidateName"];
            candidate.standardized = [NSNumber numberWithBool:[rs boolForColumn:@"standardized"]];
            candidate.startWorkYear = [NSNumber numberWithLong:[rs longForColumn:@"startWorkYear"]];
            candidate.candidateDegreeId = [NSNumber numberWithLong:[rs longForColumn:@"candidateDegreeId"]];
            candidate.candidateRecommendTime = [NSNumber numberWithLongLong:[rs longLongIntForColumn:@"candidateRecommendTime"]];
            candidate.positionId = [NSNumber numberWithLong:[rs longForColumn:@"positionId"]];
            candidate.positionName = [rs stringForColumn:@"positionName"];
            candidate.dynamicTime = [NSNumber numberWithLongLong:[rs longLongIntForColumn:@"dynamicTime"]];
            candidate.companyId = [NSNumber numberWithLong:[rs longForColumn:@"companyId"]];
            candidate.companyName = [rs stringForColumn:@"companyName"];
            candidate.isNewRecommandResume = [NSNumber numberWithBool:[rs boolForColumn:@"isNewRecommandResume"]];
            candidate.isUrgentPosition = [NSNumber numberWithBool:[rs boolForColumn:@"isUrgentPosition"]];
            candidate.hrFeedbackHours = [NSNumber numberWithLong:[rs longForColumn:@"hrFeedbackHours"]];
            candidate.priorityHours = [NSNumber numberWithLong:[rs longForColumn:@"priorityHours"]];
            candidate.resumeUrl = [rs stringForColumn:@"resumeUrl"];
            candidate.hrReadTime = [NSNumber numberWithLongLong:[rs longLongIntForColumn:@"hrReadTime"]];
            candidate.guaranteeMonths = [NSNumber numberWithLong:[rs longForColumn:@"guaranteeMonths"]];
            candidate.hhId = [NSNumber numberWithLongLong:[rs longLongIntForColumn:@"hhId"]];
            candidate.hhDisplayName = [rs stringForColumn:@"hhDisplayName"];
            candidate.hhPhone = [rs stringForColumn:@"hhPhone"];
            candidate.hhEmail = [rs stringForColumn:@"hhEmail"];
            candidate.hhIsMobileUser = [NSNumber numberWithBool:[rs boolForColumn:@"hhIsMobileUser"]];
            candidate.candidatePhone = [rs stringForColumn:@"candidatePhone"];
            candidate.candidateEmail = [rs stringForColumn:@"candidateEmail"];
            candidate.arrangeInterviewTime = [rs stringForColumn:@"arrangeInterviewTime"];
            [data addObject:candidate];
            candidate.candidateGender = [NSNumber numberWithInt:[rs intForColumn:@"candidateGender"]];
            candidate.candidateSmallAvatar = [rs stringForColumn:@"candidateSmallAvatar"];
            candidate.retransmitMess = [rs stringForColumn:@"retransmitMess"];
        }
        [rs close];
        [db close];
    }
    return data;
 
}

//增加数据到CandiateTable
- (void)insertDataToCandiateTableFromArray:(NSArray *)array WithStatusId:(int)statusId
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    [self deleteCandiateTableDataWithStatusId:statusId]; //先删除之前的数据
    
    if (array.count > 0) {
        
        if ([db open]) {
            
            for (int i = 0; i < array.count; i++) {
                
                HRCandidate *candidate = [array objectAtIndex:i];
                
                NSString *sql = @"INSERT INTO CandiateTable (statusId, candidateId, candidateStatus, candidateAvatar, candidateName, standardized, startWorkYear, candidateDegreeId, candidateRecommendTime, positionId, positionName, dynamicTime, companyId, companyName, isNewRecommandResume, isUrgentPosition, hrFeedbackHours, priorityHours, resumeUrl, hrReadTime, guaranteeMonths, hhId, hhDisplayName, hhPhone, hhEmail, hhIsMobileUser, candidatePhone, candidateEmail, arrangeInterviewTime,lastUpdateTime,userId,candidateGender,candidateSmallAvatar,retransmitMess) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
                
                NSTimeInterval lastTime = [[NSDate date] timeIntervalSince1970];
                int64_t userId = [UserManeger shareInstance].currentUser.uid;

                [db executeUpdate:sql,@(statusId),candidate.candidateId,candidate.candidateStatus,candidate.candidateAvatar,candidate.candidateName, candidate.standardized,candidate.startWorkYear,candidate.candidateDegreeId,candidate.candidateRecommendTime,candidate.positionId,candidate.positionName,candidate.dynamicTime,candidate.companyId,candidate.companyName,candidate.isNewRecommandResume,candidate.isUrgentPosition,candidate.hrFeedbackHours,candidate.priorityHours,candidate.resumeUrl,candidate.hrReadTime,candidate.guaranteeMonths,candidate.hhId,candidate.hhDisplayName,candidate.hhPhone,candidate.hhEmail,candidate.hhIsMobileUser,candidate.candidatePhone,candidate.candidateEmail,candidate.arrangeInterviewTime,@(lastTime),@(userId),candidate.candidateGender,candidate.candidateSmallAvatar,candidate.retransmitMess];
            }
            [db close];
        }
    }
}


//增加数据到PositionTable
- (void)insertDataToPositionTableFromArray:(NSArray *)array
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    [self deletePositionTableData]; //先删除之前的数据
    
    if (array.count > 0) {
        
        if ([db open]) {
            
            for (int i = 0; i < array.count; i++) {
                
                Position *position = [array objectAtIndex:i];
                
                NSString *sql = @"INSERT INTO PositionTable (positionType,positionId,positionTitle,urgency,minShowAnnualSalary,maxShowAnnualSalary,recommendCandidateCount,candidateNoHandleNum,positionNewRecommendCount,questionCount,unAnswer,nApply,allApply,userId,modifyTime,avgFeedBackTime,lastUpdateTime,priorityFeedbackHours,positionCandidateAllQuestions,positionAllRecommendCount) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
                
                NSTimeInterval lastTime = [[NSDate date] timeIntervalSince1970];
                int64_t userId = [UserManeger shareInstance].currentUser.uid;

                [db executeUpdate:sql,@(position.positionType),@(position.positionId),position.positionTitle,@(position.urgency),@(position.commission.minShowAnnualSalary),@(position.commission.maxShowAnnualSalary),@(position.positionNewRecommendCount),@(position.positionCandidateNoHandleNum),@(position.positionNewRecommendCount),@(position.totalQuestions),@(position.positionUnAnswer),@(position.positionNewApply),@(position.positionCandidateAllApply),@(userId),@(position.modifyTime),@(position.positionAvgFeedBackTime),@(lastTime),@(position.priorityFeedbackHours),@(position.positionCandidateAllQuestions),@(position.positionAllRecommendCount)];
            }
            [db close];
        }
    }
}




//增加数据到CommonHunterTable
- (void)insertDataToCommonHunterTableFromArray:(NSArray *)array
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    [self deleteCommonHunterTableData]; //先删除之前的数据
    
    if (array.count > 0) {
        
        if ([db open]) {
            
            for (int i = 0; i < array.count; i++) {
                
                Hunter *hunter = [array objectAtIndex:i];
                
                NSString *sql = @"INSERT INTO CommonHunterTable (hhId,displayName,trueName,mobilePhone,avatar,recommendCount,interviewRate,offerCount,revocationRate,serverQuality,recommendQuality,titleId,verifiedTitle,lastUpdateTime,userId) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
                
                NSTimeInterval lastTime = [[NSDate date] timeIntervalSince1970];
                int64_t userId = [UserManeger shareInstance].currentUser.uid;
                
                [db executeUpdate:sql,@(hunter.hunterId),hunter.displayName,hunter.trueName,hunter.mobilePhone,hunter.avatarUrl,@(hunter.recommendCount),@(hunter.interviewRate),@(hunter.offerCount),@(hunter.revocationRate),@(hunter.serverQuality),@(hunter.recommendQuality),@(hunter.hunterLavel),@(hunter.verifiedTitle),@(lastTime),@(userId)];
            }
            [db close];
        }
    }
}





//通过userId从数据库获取Position模型的数组
- (NSArray *)getPositionModelsFromPositionTableWithUserId
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    int64_t uid = [UserManeger shareInstance].currentUser.uid;
    NSMutableArray *mutableArr = [NSMutableArray array];
    if ([db open]) {
        
        FMResultSet *resultSet = [db executeQueryWithFormat:@"select *from PositionTable where userId = %lld",uid];
        while ([resultSet next]) {
            
            Position *p = [[Position alloc] init];
            Commission *com = [[Commission alloc] init];
            p.commission = com;
            
            
            p.positionId = [resultSet longForColumn:@"positionId"];
            p.positionTitle = [resultSet stringForColumn:@"positionTitle"];
            p.positionType = [resultSet intForColumn:@"positionType"];
            p.modifyTime = [resultSet longLongIntForColumn:@"modifyTime"];
            p.urgency = [resultSet intForColumn:@"urgency"];
            p.commission.minShowAnnualSalary = [resultSet doubleForColumn:@"minShowAnnualSalary"];
            p.commission.maxShowAnnualSalary = [resultSet doubleForColumn:@"maxShowAnnualSalary"];
            p.positionCandidateNoHandleNum = [resultSet intForColumn:@"candidateNoHandleNum"];
            p.positionNewRecommendCount = [resultSet intForColumn:@"positionNewRecommendCount"];
            p.positionUnAnswer = [resultSet intForColumn:@"unAnswer"];
            p.positionNewApply = [resultSet intForColumn:@"nApply"];
            p.positionCandidateAllApply = [resultSet intForColumn:@"allApply"];
            p.positionAvgFeedBackTime = [resultSet longLongIntForColumn:@"avgFeedBackTime"];
            p.priorityFeedbackHours = [resultSet intForColumn:@"priorityFeedbackHours"];
            
            p.positionAllRecommendCount = [resultSet intForColumn:@"recommendCandidateCount"];
            p.totalQuestions = [resultSet longLongIntForColumn:@"questionCount"];
            p.positionCandidateAllQuestions = [resultSet intForColumn:@"positionCandidateAllQuestions"];
            p.positionAllRecommendCount = [resultSet intForColumn:@"positionAllRecommendCount"];
            
            [mutableArr addObject:p];
        }
        [db close];
    }
    return [mutableArr copy];
}






//通过userId从数据库获取CommonHunter模型的数组
- (NSArray *)getCommonHunterModelsFromCommonHunterTableWithUserId:(long)userId
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    NSMutableArray *mutableArr = [NSMutableArray array];
    if ([db open]) {
        
        FMResultSet *resultSet = [db executeQueryWithFormat:@"select *from CommonHunterTable where userId = %ld",userId];
        while ([resultSet next]) {
            
            Hunter *hunter = [[Hunter alloc] init];
            
            hunter.hunterId = [resultSet longLongIntForColumn:@"hhId"];
            hunter.displayName = [resultSet stringForColumn:@"displayName"];
            hunter.trueName = [resultSet stringForColumn:@"trueName"];
            hunter.mobilePhone = [resultSet stringForColumn:@"mobilePhone"];
            hunter.avatarUrl = [resultSet stringForColumn:@"avatar"];
            hunter.recommendCount = [resultSet longLongIntForColumn:@"recommendCount"];
            hunter.interviewRate = [resultSet doubleForColumn:@"interviewRate"];
            hunter.offerCount = [resultSet longLongIntForColumn:@"offerCount"];
            hunter.revocationRate = [resultSet doubleForColumn:@"revocationRate"];
            hunter.serverQuality = [resultSet doubleForColumn:@"serverQuality"];
            hunter.recommendQuality = [resultSet doubleForColumn:@"recommendQuality"];
            hunter.hunterLavel = [resultSet longLongIntForColumn:@"titleId"];
            hunter.verifiedTitle = [resultSet boolForColumn:@"verifiedTitle"];
            
            [mutableArr addObject:hunter];
        }
        [db close];
    }
    return [mutableArr copy];
}






//删除CommonHunterTable中指定的hunterId行
- (BOOL)deleteCommonHunterTableWithHunterId:(long)hunterId
{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    BOOL isDeleteRecordOK = NO;
    if ([db open]) {
        long uid = (long)[UserManeger shareInstance].currentUser.uid;
        NSString *string = [NSString stringWithFormat:@"delete from CommonHunterTable where userId = %ld and hhId = %ld",uid,hunterId];
        BOOL res = [db executeUpdate:string];
        if (!res) {
            NSLog(@"error to delete db data");
            isDeleteRecordOK = NO;
        } else {
            NSLog(@"succ to deleta db data");
            isDeleteRecordOK = YES;
        }
        [db close];
    }
    return isDeleteRecordOK;
}

- (void)updatePositionTablePositionPublishTime:(int64_t)PublishTime{
    FMDatabase * db = [FMDatabase databaseWithPath:kCacheDBPath];
    if ([db open]) {
        NSString *string = [NSString stringWithFormat:@"UPDATE PositionTable SET modifyTime = %lld",PublishTime];
        BOOL res = [db executeUpdate:string];
        if (!res) {
            NSLog(@"error to UPDATE db data");
        } else {
            NSLog(@"succ to UPDATE db data");
        }
        [db close];
    }

}


@end
