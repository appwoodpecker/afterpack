//
//  RenderUtil.h
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/23.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BundleCheckpoint.h"

@interface RenderUtil : NSObject

+ (NSString *)renderHtmlWithInfo: (NSDictionary *)packageInfo checkResult:(NSArray<BundleCheckpointRecord *> *) recordList;

@end
