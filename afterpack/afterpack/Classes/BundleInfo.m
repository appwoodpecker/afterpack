//
//  BundleInfo.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/10.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "BundleInfo.h"

@implementation BundleResourceItem

- (NSString *)consoleFormat {
    return [NSString stringWithFormat:@"%@",self.path?:@""];
}

- (NSString *)htmlFormat {
    return [NSString stringWithFormat:@"<a href='%@' target='_blank'>%@</a>",self.path?:@"",self.name];
}

@end

@implementation CarResourceItem

- (NSString *)consoleFormat {
    return [NSString stringWithFormat:@"%@",self.path?:@""];
}

- (NSString *)htmlFormat {
    return [NSString stringWithFormat:@"<a href='%@' target='_blank'>%@</a>",self.path?:@"",self.name];
}

@end

@implementation BundleInfo

@end
