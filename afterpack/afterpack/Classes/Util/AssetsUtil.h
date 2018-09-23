//
//  AssetsUtil.h
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/16.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BundleInfo.h"

@interface AssetsUtil : NSObject

+ (NSArray<CarResourceItem *> *)unarchiveCarFile: (NSString *)carPath outputPath: (NSString *)ouputPath;

@end
