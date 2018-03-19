//
//  House.h
//  数据库自动更新
//
//  Created by 张鹏 on 2018/2/28.
//  Copyright © 2018年 张鹏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface House : NSObject

@property (nonatomic, strong) NSString * size;//大小
@property (nonatomic, assign) NSNumber * money;//多少钱
@property (nonatomic, strong) NSString * city; //城市
@property (nonatomic, strong) NSString * color; //颜色
@property (nonatomic, strong) NSNumber * number; //能住人数

@property (assign, nonatomic) long lastUpdateTime;//最后更新时间
@property (assign, nonatomic) long userID;//用户id

/**
 数据源拼接匹配数组
 
 @param model 数据源
 @return 数据源拼接匹配数组
 */
- (NSArray *)modleWithModle:(House *)model;

@end
