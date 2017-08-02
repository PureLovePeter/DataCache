//
//  handleSqliteTable.h
//  RuntimeDemo
//
//  Created by peter on 16/3/18.
//  Copyright © 2016年 hunteron All rights reserved.
//

#import <Foundation/Foundation.h>

@interface handleSqliteTable : NSObject

/**
 *  获取 model 中的所有属性数组
 *  model      需要缓存的对象
 */
- (NSArray *)ivarsArrayWithModel:(NSObject *)model;

/**
 *  返回 数据库表的语句
 *  tableName  表名字
 *  model      需要缓存的对象
 */
- (NSString *)sqliteStingWithTableName:(NSString *)tableName model:(NSObject *)model;

/*
 *获取属性的类型,并转化为c的类型,并进行拼接
 */
- (NSArray *)attribleArray:(NSArray *)attribleArray model:(NSObject *)model;

@end

