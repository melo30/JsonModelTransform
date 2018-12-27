//
//  Person.m
//  字典模型互转实现原理
//
//  Created by melo on 2018/12/28.
//  Copyright © 2018 陈诚. All rights reserved.
//

#import "Person.h"
#import <objc/message.h>//引入runtime的消息发送系统类库

@implementation Person

/**
 
 字典转模型
 
 *注意：这个方法只是简单实现了单层的对象模型的转换,后面可以思考再加上基本数据类型的转换，甚至多层嵌套模型的转换，甚至一些空值边界的处理等.就是YYModel、MJExtension了~~~~
 
 核心思路:
        1.通过遍历字典的Key-Value.
        2.通过runtime的消息发送 objc_msgSend(id, sel, value) 这个C函数.
        3.来调用Model里面属性的set方法，达到给Model赋值的目的.
 
 @param dic 字典
 @return self
 */

- (instancetype)initWithDic:(NSDictionary *)dic {
    if (self = [super init]) {;
        for (NSString *key in dic.allKeys) {
            id value = dic[key];
            // 注意：属性的set方法后面s首字母是大写，所以这里得用key.capitalizedString
            NSString *methodName = [NSString stringWithFormat:@"set%@:",key.capitalizedString];
            SEL sel = NSSelectorFromString(methodName);
            if (sel) {
                //调用set方法
                //C函数指针的格式: 返回值(* 函数名)(param1, param2)，这里objc_msgSenda需要一个强转!
                ((void(*)(id, SEL, id))objc_msgSend)(self, sel, value);
            }
        }
    }
    return self;
}



/**
 模型转字典

 核心思路：
        1.字典里面需要 key和value
        2.key如何获取？ 通过 runtime里面的方法 class_copyPropertyList() 来获取当前Modeld里面的属性
        3.value如何获取？ 通过get方法 也就是(objc_msgSend)来得到
 
 @return Dic
 */
- (NSDictionary *)coverModelToDic {
    //先声明一个count等于0
    unsigned int count = 0;
    //objc_property_t 是一个结构体，用于接收获取到的属性集合
    objc_property_t *properties = class_copyPropertyList(self, &count);
    if (count != 0) {
        //声明一个字典用来保存这些属性
        NSMutableDictionary *temDic = [@{} mutableCopy];
        for (int i = 0; i < count; i ++) {
            const void *propertyName = property_getName(properties[i]);
            //获取到key
            NSString *name = [NSString stringWithUTF8String:propertyName];
            //获取方法编号
            SEL sel = NSSelectorFromString(name);
            if (sel) {
                //获取到value
                //调用get方法，对比上面字典转模型的set方法，就能理解此~~
               id value = ((id(*)(id, SEL))objc_msgSend)(self, sel);
                if (value) {
                    temDic[name] = value;
                }else {
                    temDic[name] = @"";
                }
            }
        }
        free(properties); //注意这个 objc_property_t *properties 用完要注意释放！
        return temDic;
    }else {
        free(properties);
        return nil;
    }
}

@end
