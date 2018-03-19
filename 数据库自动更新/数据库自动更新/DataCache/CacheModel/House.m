//
//  House.m
//  数据库自动更新
//
//  Created by 张鹏 on 2018/2/28.
//  Copyright © 2018年 张鹏. All rights reserved.
//

#import "House.h"

@implementation House
- (NSArray *)modleWithModle:(House *)model{
    NSMutableArray *mutArray = [NSMutableArray array];
    [mutArray addObject:model.size];
    [mutArray addObject:model.money];
    [mutArray addObject:model.city];
    [mutArray addObject:model.color];
    [mutArray addObject:model.number];

    NSTimeInterval lastUpdateTime = [[NSDate date] timeIntervalSince1970];
    [mutArray addObject:@(lastUpdateTime)];
    int value = arc4random() % 1000;
    [mutArray addObject:@(value)];
    return [mutArray copy];
}

@end
