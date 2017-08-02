//
//  CashFMDB.h
//  iOS-HR
//
//  Created by peter on 16/5/10.
//  Copyright © 2016年 headhunter-HR. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CacheFMDB : NSObject


@property (nonatomic,strong)NSMutableArray *modelArray;//数据model



/**
 *  创建CacheFMDB类的对象
 */
+ (instancetype)sharedCacheFMDB;




/**
 *  创建首页候选人表格，包含 新推荐和待处理
 */
- (void)createCacheTable;



/**
 *  删除CandiateTable
 *
 *  @param statusId  状态:待处理传值:1  新推荐传值:2  其他:3
 */
- (void)deleteCandiateTableDataWithStatusId:(int)statusId;



/**
 *  删除PositionTable所有数据
 */
- (void)deletePositionTableData;


/**
 *  删除CommonHunterTable所有数据
 */
- (void)deleteCommonHunterTableData;


/**
 * 判断候选人的表是否存在
 *
 */
- (BOOL)jugeTableIsExistWithStatusId:(int)statusId;


/**
 * 判断表是否存在
 *
 */
- (BOOL)jugeTableIsExistWithName:(NSString *)tableName;



/**
 *  增加数据到CandiateTable
 *
 *  @param array    待增加的数据array
 *  @param statusId  状态:待处理传值:1  新推荐传值:2  其他:3
 */
- (void)insertDataToCandiateTableFromArray:(NSArray *)array WithStatusId:(int)statusId;



/**
 *  增加数据到PositionTable
 *
 *  @param array    待增加的数据array
 */
- (void)insertDataToPositionTableFromArray:(NSArray *)array;




/**
 *  增加数据到CommonHunterTable
 *
 *  @param array    待增加的数据array
 */
- (void)insertDataToCommonHunterTableFromArray:(NSArray *)array;



/**
 * 加载candidate表的数据
 *
 */
- (NSArray *)loadTableDataWithStatusId:(int)statusId;


/**
 *  通过userId从数据库获取Position模型的数组
 *
 *  @param userId 传入的userId
 *
 *  @return postion的数组
 */
- (NSArray *)getPositionModelsFromPositionTableWithUserId;






/**
 *  通过userId从数据库获取CommonHunter模型的数组
 *
 *  @param userId 传入的userId
 *
 *  @return commonHunter的数组
 */
- (NSArray *)getCommonHunterModelsFromCommonHunterTableWithUserId:(long)userId;


/**
 *  是否需要update相应的表格
 *
 *  @param tableName
 *
 *  @return 是否需要更新
 */
- (BOOL)isNeedUpdateTableName:(NSString *)tableName;


/**
 *  是否需要更新candidatetable
 *
 *  @param statusId
 *
 *  @return 是否需要更新
 */
- (BOOL)isNeedUpdateCandidateTableWithStatusId:(int)statusId;




/**
 *  删除CommonHunterTable中指定的hunterId行
 *
 *  @param hunterId
 *
 *  @return 是否删除成功
 */
- (BOOL)deleteCommonHunterTableWithHunterId:(long)hunterId;


/**
 * 更新position表的发布时间
 *
 */
- (void)updatePositionTablePositionPublishTime:(int64_t)PublishTime;

@end
