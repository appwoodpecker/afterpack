//
//  FileUtil.h
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/16.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileUtil : NSObject

+ (BOOL)dirExistsAtPath: (NSString *)path;
+ (void)createDirAtPath: (NSString *)path;

+ (BOOL)fileExistsAtPath: (NSString *)path;
+ (void)saveData: (NSData *)data atPath: (NSString *)path;

+ (void)deleteFileAtPath: (NSString *)path;

@end
