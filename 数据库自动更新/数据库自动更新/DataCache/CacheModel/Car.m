//
//  Car.m
//  数据库自动更新
//
//  Created by 张鹏 on 2018/2/28.
//  Copyright © 2018年 张鹏. All rights reserved.
//

#import "Car.h"

@implementation Car

- (NSArray *)modleWithModle:(Car *)model{
    NSMutableArray *mutArray = [NSMutableArray array];
    [mutArray addObject:model.size];
    [mutArray addObject:model.money];
    [mutArray addObject:model.brand];
    [mutArray addObject:model.color];
    
    NSTimeInterval lastUpdateTime = [[NSDate date] timeIntervalSince1970];
    [mutArray addObject:@(lastUpdateTime)];
    int value = arc4random() % 1000;
    [mutArray addObject:@(value)];
    return [mutArray copy];
}

@end
