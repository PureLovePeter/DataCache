//
//  handleSqliteTable.h
//  RuntimeDemo
//
//  Created by peter on 16/3/18.
//  Copyright © 2016年 hunteron All rights reserved.
//

#import <Foundation/Foundation.h>

@interface handleMessage : NSObject

/**
 获取 model 中的所有属性数组

 @param model model对象
 @return 返回属性数组
 */
- (NSArray *)ivarsArrayWithModel:(NSObject *)model;


/**
  数据库表的创建语句

 @param tableName 表的名字
 @param model modle对象
 @return 数据库表的创建string
 */
- (NSString *)sqliteStingWithTableName:(NSString *)tableName model:(NSObject *)model;

/**
 获取属性的类型,并转化为c的类型,并进行拼接

 @param attribleArray 属性的数组
 @param model modle对象
 @return 返回c的字符数组
 */
- (NSArray *)attribleArray:(NSArray *)attribleArray model:(NSObject *)model;


/**
 插入数据库的语句

 @param tableName 表名字
 @param model modle对象
 @return 插入数据库语句的string
 */
- (NSString *)insertStringWithTableName:(NSString *)tableName  model:(NSObject *)model;

/**
 更新数据库的语句
 
 @param tableName 表名字
 @param model modle对象
 @return 插入数据库语句的string
 */
- (NSString *)updateStringWithTableName:(NSString *)tableName  model:(NSObject *)model updateKey:(NSString *)updateKey;


/**
 获得modle的所有属性

 @param obj 对象
 @return 属性数组
 */
- (NSArray *)propertyValueWithModel:(id)obj;

@end

