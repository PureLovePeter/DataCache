//
//  People.h
//  数据库自动更新
//
//  Created by 张鹏 on 2018/2/28.
//  Copyright © 2018年 张鹏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface People : NSObject

@property (nonatomic, strong) NSString * name;//姓名
@property (nonatomic, assign) NSNumber * age;//年龄
@property (nonatomic, strong) NSNumber * gender; //性别 0:女 1:男
@property (nonatomic, strong) NSString * color; //肤色
//@property (nonatomic, strong) NSString * ceshi; //新增字段测试

@property (assign, nonatomic) long lastUpdateTime;//最后更新时间
@property (assign, nonatomic) long userID;//用户id

/**
数据源拼接匹配数组

@param model 数据源
@return 数据源拼接匹配数组
*/
- (NSArray *)modleWithModle:(People *)model;

@end

