//
//  ViewController.m
//  数据库自动更新
//
//  Created by 张鹏 on 2018/2/28.
//  Copyright © 2018年 张鹏. All rights reserved.
//

#import "ViewController.h"
#import "MessageToolData.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /* 创建数据库表
      1、测试创建新表，你可以在creatTable中注释掉
     House *house = [[House alloc]init];
     [mutArray addObject:house];
     先创建people 和 car 表
      2、测试新增字段，你可以在people.h中增加一个属性
     @property (nonatomic, strong) NSString * ceshi; //新增字段测试
     并且在.m对应位置增加数据；
     [mutArray addObject:model.ceshi];
     */
    
    //第一步创建所有要用到的表
    [MessageToolData creatTable];
    //1.插入数据
    for (int i = 0 ; i < 100 ; i ++) {
        People *pe = [[People alloc]init];
        pe.name = [NSString stringWithFormat:@"小明%d",i];
        pe.age = @(10+i);
        pe.gender = @(i%2);
        pe.color = @[@"红",@"橙",@"黄",@"绿"][i%4];
        pe.userID = i;
//        pe.ceshi = @"测试";
        [MessageToolData insertDataToPeopleTable:pe];
    }
    //2.更新数据 第99个
    People *pe = [[People alloc]init];
    pe.name = [NSString stringWithFormat:@"小蓝"];
    pe.age = @(99);
    pe.gender = @(0);
    pe.color = @"啦啦啦啦啦";
    pe.userID = 99;
//    pe.ceshi = @"测试";
    [MessageToolData insertDataToPeopleTable:pe];
    
    //3.获取数据
    People *peopl = [[People alloc]init];
    peopl.userID = 1;
    NSArray *array = [MessageToolData peopleDataLoadFromeDBWithArray:@[peopl]];
    for (People *people in array) {
        NSLog(@"姓名%@,性别%@,肤色%@,年龄%@",people.name,people.gender,people.color,people.age);
    }
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
