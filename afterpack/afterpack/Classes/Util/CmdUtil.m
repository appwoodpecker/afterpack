//
//  CmdUtil.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/17.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "CmdUtil.h"

@implementation CmdUtil


+ (void)runCmd: (NSString *)cmd {
    [CmdUtil runCmd:cmd workPath:nil envParams:nil];
}

+ (void)runCmd: (NSString *)cmd workPath: (NSString *)workPath {
    [CmdUtil runCmd:cmd workPath:workPath envParams:nil];
}

+ (void)runCmd: (NSString *)cmd workPath: (NSString *)workPath envParams: (NSDictionary *)envParams {
    NSTask * task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    if(workPath){
        task.currentDirectoryPath = workPath;
    }
    [task setArguments:@[@"-c",cmd]];
    if(envParams){
        [task setEnvironment:envParams];
    }
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task launch];
    [task waitUntilExit];
}

@end
