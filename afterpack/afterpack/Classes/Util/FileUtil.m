//
//  FileUtil.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/16.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "FileUtil.h"

@implementation FileUtil

+ (BOOL)dirExistsAtPath: (NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExists = NO;
    isExists = [fm fileExistsAtPath:path isDirectory:&isDir];
    return (isExists && isDir);
}

+ (void)createDirAtPath: (NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
}

+ (BOOL)fileExistsAtPath: (NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExists = NO;
    isExists = [fm fileExistsAtPath:path isDirectory:&isDir];
    return (isExists && !isDir);
}

+ (void)saveData: (NSData *)data atPath: (NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createFileAtPath:path contents:data attributes:nil];
}

+ (void)deleteFileAtPath: (NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    [fm removeItemAtPath:path error:&error];
}


@end
