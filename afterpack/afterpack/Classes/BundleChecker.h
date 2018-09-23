//
//  afterpack.h
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/10.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BundleCheckpoint.h"


@interface BundleChecker : NSObject

+ (BundleChecker *)sharedChecker;

- (NSArray<id<BundleCheckPointProtocol>> *)availableCheckpoints;

- (void)runWithCheckpoints: (NSArray<NSString *> *)checkpointIds
                   options: (NSDictionary<NSString *,NSArray<BundleCheckpointOption *> *> *)options
                bundlePath: (NSString *)bundlePath;



- (NSString *)appName;
- (NSString *)homePage;

@end



