//
//  BundleCheckpoint.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/10.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "BundleCheckpoint.h"

NSString * const kBundleCheckpointAuthorName    = @"name";
NSString * const kBundleCheckpointAuthorLink    = @"link";

@implementation BundleCheckpoint

+ (NSString *)name {
    return @"Your checkpoint name";
}

+ (NSString *)identifier {
    return @"Your checkpoint identifier";
}

+ (NSDictionary *)author {
    return @{
             kBundleCheckpointAuthorName : @"",
             kBundleCheckpointAuthorLink : @"",
             };
}

+ (NSArray<BundleCheckOptionDefinition *> *)optionList {
    return nil;
}

+ (BOOL)validateOptionValue: (NSString *)optionKey value: (NSString *)value {
    return YES;
}

- (void)runWithBundleInfo: (BundleInfo *)bundleInfo
                  options: (NSDictionary<NSString *, BundleCheckpointOption*> *)optionValues
             onCompletion: (void (^)(BOOL pass,NSString *console, NSString *html))completionBlock
{
    if(completionBlock) {
        completionBlock(NO,nil,nil);
    }
}

@end

@implementation BundleCheckOptionDefinition

@end


@implementation BundleCheckpointOption

@end


@implementation BundleCheckpointRecord

@end
