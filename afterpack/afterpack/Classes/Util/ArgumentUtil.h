//
//  ArgumentUtil.h
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/22.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Action : NSObject

+ (instancetype)action;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *options;

- (BOOL)hasOption;

@end

@interface ArgumentUtil : NSObject

+ (NSArray<Action *> *)parse: (NSArray *)values;

+ (BOOL)validateActions: (NSArray<Action *> *)actions message: (NSString **)message;

@end
