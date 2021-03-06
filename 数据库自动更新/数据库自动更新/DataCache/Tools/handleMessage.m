//
//  handleSqliteTable.m
//  RuntimeDemo
//
//  Created by peter on 16/3/18.
//  Copyright © 2016年 hunteron All rights reserved.
//

#import "handleMessage.h"
#import <objc/runtime.h>

static NSString *intType     = @"i"; // int_32t,int
static NSString *longlongType = @"q"; // long,或者longlong
static NSString *floatType   = @"f"; // float
static NSString *doubleType  = @"d"; // double
static NSString *boolType    = @"B"; // bool
static NSString *imageType   = @"UIImage"; // UIImage 类型
static NSString *stringType  = @"NSString"; // NSString 类型
static NSString *numberType  = @"NSNumber"; // NSNumber 类型

@interface handleMessage ()

//类属性
@property (nonatomic,strong)NSMutableArray *ivarsArray;
//类的类型
@property (nonatomic,strong)NSMutableArray *typeArray;

@end

@implementation handleMessage

- (instancetype)init{
    self = [super init];
    if (self) {
        _ivarsArray = [NSMutableArray array];
        _typeArray = [NSMutableArray array];
    }
    return self;
    
}
- (NSArray *)ivarsArrayWithModel:(NSObject *)model{
    [_ivarsArray removeAllObjects];
    unsigned int count;
    
    //获取成员变量的结构体
    Ivar *ivars = class_copyIvarList([model class], &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        //根据ivar获得其成员变量的名称
        const char *name = ivar_getName(ivar);
        //C的字符串转OC的字符串
        NSString *key = [NSString stringWithUTF8String:name];
        //放入数组
        NSString *keyString = [key stringByReplacingOccurrencesOfString:@"_" withString:@""];
        [_ivarsArray addObject:keyString];
    }
    //记得释放
    free(ivars);
    return _ivarsArray;
}

/* 获取对象的所有属性对象*/
- (NSArray *)propertyValueWithModel:(id)obj
{
    NSMutableArray *props = [NSMutableArray array];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([obj class], &outCount);
    for (i = 0; i<outCount; i++)
    {
        objc_property_t property = properties[i];
        const char* char_f =property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        id propertyValue = [obj valueForKey:(NSString *)propertyName];
        if (propertyValue) [props addObject:propertyValue];
    }
    free(properties);
    return props;
}

//
- (NSString *)sqliteStingWithTableName:(NSString *)tableName model:(NSObject *)model{
    
    [self test1:model];
    
    return  [self complatSqiteAttribiteA:_ivarsArray typeA:_typeArray tableName:tableName];
}

- (NSArray *)attribleArray:(NSArray *)attribleArray model:(NSObject *)model{
    
    [self test1:model];
    
    return [self comFinallyAttribleArray:attribleArray];
    
}


- (NSString *)insertStringWithTableName:(NSString *)tableName  model:(NSObject *)model{
    
    [self test1:model];
    
    return [self complatInsertSqiteAttribiteA:_ivarsArray tableName:tableName];
}


- (NSString *)updateStringWithTableName:(NSString *)tableName  model:(NSObject *)model updateKey:(NSString *)updateKey{
    
    [self test1:model];
    if ([_ivarsArray containsObject:updateKey]) {
        [_ivarsArray removeObject:updateKey];
    }
    return [self complatUpdateSqiteAttribiteA:_ivarsArray tableName:tableName updateKey:updateKey];
}


- (NSArray *)comFinallyAttribleArray:(NSArray *)attribleArray{
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *str in attribleArray) {
        int index = (int)[_ivarsArray indexOfObject:str];
        NSString *type = [NSString stringWithFormat:@"%@ %@",str,_typeArray[index]];
        [array addObject:type];
    }
    return [array copy];
}


/**
 *  获取一个类的全部成员变量名
 */
- (void)test1:(NSObject *)model{
    [_ivarsArray removeAllObjects];
    [_typeArray removeAllObjects];
    unsigned int count;
    
    //获取成员变量的结构体
    Ivar *ivars = class_copyIvarList([model class], &count);

    for (int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        //根据ivar获得其成员变量的名称
        const char *name = ivar_getName(ivar);
        //C的字符串转OC的字符串
        NSString *key = [NSString stringWithUTF8String:name];
        //放入数组
        NSString *keyString = [key stringByReplacingOccurrencesOfString:@"_" withString:@""];
        [_ivarsArray addObject:keyString];
        // 获取变量类型，c字符串
        const char *cType = ivar_getTypeEncoding(ivar);
        //C的字符串转OC的字符串
        NSString *Type = [NSString stringWithUTF8String:cType];
        //基本类型数组库类型转化
//        NSLog(@"======%@",Type);
        NSString *repleaceString = [self repleaceStringWithCSting:Type];
        //放入数组
        [_typeArray addObject:repleaceString];
    }
    //记得释放
    free(ivars);
}

/*****属性和数据库数据的类型相互转换*****/
- (NSString *)repleaceStringWithCSting:(NSString *)cSting{
    if (![cSting isEqualToString:@""]) {
        if ([cSting isEqualToString:@"i"]) {
            return @"int";
        }else if([cSting isEqualToString:@"q"]){
            return @"double";
        }else if([cSting isEqualToString:@"f"]){
            return @"float";
        }else if([cSting isEqualToString:@"d"]){
            return @"double";
        }else if([cSting isEqualToString:@"B"]){
            return @"int";
        }else if([cSting containsString:@"NSString"]){
            return @"text";
        }else if([cSting containsString:@"NSNumber"]){
            return @"long";
        }
        NSAssert(1, @"handleSqliteTable类中 model的属性状态不对导致数据库状态不对，请核对后再拨");
        return @"未知";
    }else return nil;
}

- (NSString *)complatSqiteAttribiteA:(NSArray *)attribiteA typeA:(NSArray *)typeA tableName:(NSString *)tableName{
    NSString *string = [NSString stringWithFormat:@"CREATE TABLE %@ (id integer PRIMARY KEY NOT NULL",tableName];
    NSString *beginString = @"";
    for (int i = 0; i < attribiteA.count;i ++) {
        NSString *atAndType = [self sqiteStringAttribite:(NSString *)attribiteA[i] type:(NSString *)typeA[i]];
        beginString = [beginString stringByAppendingString:atAndType];

    }
    return [NSString stringWithFormat:@"%@ %@)",string,beginString];
}

/**
 *  数据库语句拼接
 */
- (NSString *)sqiteStringAttribite:(NSString *)attribite type:(NSString *)type{
    return [NSString stringWithFormat:@", %@ %@ ",attribite,type];
}


- (NSString *)complatInsertSqiteAttribiteA:(NSArray *)attribiteA tableName:(NSString *)tableName {
    NSString *stringF = [NSString stringWithFormat:@"INSERT INTO %@ (",tableName];
    //包含主见的？
    NSString *stringS = @"VALUES (";
    NSString *beginString = @"";
    NSString *rearString = @"";
    for (int i = 0; i < attribiteA.count;i ++) {
        if (i != [attribiteA indexOfObject:attribiteA.lastObject]) {
            NSString *atAndType = [NSString stringWithFormat:@"%@,",attribiteA[i]];
            beginString = [beginString stringByAppendingString:atAndType];
            rearString = [rearString stringByAppendingString:@"?,"];
        }else{
            NSString *atAndType = [NSString stringWithFormat:@"%@",attribiteA[i]];
            beginString = [beginString stringByAppendingString:atAndType];
            rearString = [rearString stringByAppendingString:@"?"];
        }
    }
    NSString *frontString = [NSString stringWithFormat:@"%@%@)",stringF,beginString];
    NSString *finallyString = [NSString stringWithFormat:@"%@%@)",stringS,rearString];
    return [NSString stringWithFormat:@"%@ %@",frontString,finallyString];
}


- (NSString *)complatUpdateSqiteAttribiteA:(NSArray *)attribiteA tableName:(NSString *)tableName updateKey:(NSString *)updateKey{
    NSString *stringF = [NSString stringWithFormat:@"update %@ set ",tableName];
    //包含主见的？
    NSString *beginString = @"";
    for (int i = 0; i < attribiteA.count;i ++) {
        if (i != [attribiteA indexOfObject:attribiteA.lastObject]) {
            NSString *atAndType = [NSString stringWithFormat:@"%@ = ?,",attribiteA[i]];
            beginString = [beginString stringByAppendingString:atAndType];
        }else{
            NSString *atAndType = [NSString stringWithFormat:@"%@ = ?",attribiteA[i]];
            beginString = [beginString stringByAppendingString:atAndType];
        }
    }
    NSString *frontString = [NSString stringWithFormat:@"%@%@ where %@ = ?",stringF,beginString,updateKey];
    return frontString;
}
@end
