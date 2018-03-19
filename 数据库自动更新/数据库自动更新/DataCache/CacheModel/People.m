//
//  People.m
//  数据库自动更新
//
//  Created by 张鹏 on 2018/2/28.
//  Copyright © 2018年 张鹏. All rights reserved.
//

#import "People.h"

@implementation People

- (NSArray *)modleWithModle:(People *)model{
    NSMutableArray *mutArray = [NSMutableArray array];
    [mutArray addObject:model.name];
    [mutArray addObject:model.age];
    [mutArray addObject:model.gender];
    [mutArray addObject:model.color];
//    [mutArray addObject:model.ceshi];

    NSTimeInterval lastUpdateTime = [[NSDate date] timeIntervalSince1970];
    [mutArray addObject:@(lastUpdateTime)];
    [mutArray addObject:@(model.userID)];
    return [mutArray copy];
}

@end
