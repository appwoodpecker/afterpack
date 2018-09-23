//
//  CmdUtil.h
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/17.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CmdUtil : NSObject

+ (void)runCmd: (NSString *)cmd;
+ (void)runCmd: (NSString *)cmd workPath: (NSString *)workPath;
+ (void)runCmd: (NSString *)cmd workPath: (NSString *)workPath envParams: (NSDictionary *)envParams;

@end
