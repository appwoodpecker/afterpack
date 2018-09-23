//
//  TestFileCheckpoint.h
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/10.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "UselessFileCheckpoint.h"

@implementation UselessFileCheckpoint

+ (NSString *)name {
    return @"Useless File Check";
}

+ (NSDictionary *)author {
    return @{
             kBundleCheckpointAuthorName : @"zhangxiaogang",
             kBundleCheckpointAuthorLink : @"http://www.woodpeck.cn",
             };
}

+ (NSString *)identifier {
    return @"uselessfile";
}

+ (NSArray<BundleCheckOptionDefinition *> *)optionList {
    //name
    BundleCheckOptionDefinition *nameOption = [[BundleCheckOptionDefinition alloc] init];
    nameOption.name = @"useless file names";
    nameOption.tip = @"name1,name2,name3";
    nameOption.defaultValue = @"demo,test,readme";
    nameOption.valueType = BundleCheckValueString;
    nameOption.key = @"testnames";
    return @[nameOption];
}

+ (BOOL)validateOptionValue:(NSString *)optionKey value:(NSString *)value {
    BOOL pass = NO;
    if([optionKey isEqualToString:@"testnames"]) {
        if(value.length > 0) {
            NSArray *testNames = [value componentsSeparatedByString:@","];
            int count = 0;
            for (NSString *testName in testNames) {
                if(testName.length > 0) {
                    count ++;
                }
            }
            if(count == (int)testNames.count) {
                pass = YES;
            }
        }
    }
    return pass;
}

- (void)runWithBundleInfo: (BundleInfo *)bundleInfo
                  options: (NSDictionary<NSString *, BundleCheckpointOption*> *)optionValues
             onCompletion: (void (^)(BOOL pass,NSString *console, NSString *html))completionBlock
{
    NSMutableArray *failedList = [NSMutableArray array];
    BundleCheckpointOption *nameOption = optionValues[@"testnames"];
    NSString *value = nameOption.value;
    NSArray *testNames = [value componentsSeparatedByString:@","];
    if(bundleInfo.resourceList.count > 0) {
        for (BundleResourceItem *item in bundleInfo.resourceList) {
            NSString *name = item.name;
            BOOL pass = YES;
            for (NSString *testName in testNames) {
                if([name rangeOfString:testName options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    pass = NO;
                    break;
                }
            }
            if(!pass) {
                [failedList addObject:item];
            }
        }
    }
    if(bundleInfo.carResourceList.count > 0) {
        for (CarResourceItem *item in bundleInfo.carResourceList) {
            BOOL pass = YES;
            for (NSString *testName in testNames) {
                if((item.assetName.length > 0) && [item.assetName rangeOfString:testName options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    pass = NO;
                    break;
                }
                if((item.name.length > 0) && [item.name rangeOfString:testName options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    pass = NO;
                    break;
                }
            }
            if(!pass) {
                [failedList addObject:item];
            }
        }
    }
    BOOL pass = (failedList.count == 0);
    NSString *message = nil;
    NSString *html = nil;
    if(!pass) {
        NSMutableString *content = [NSMutableString string];
        NSMutableString *htmlContent = [NSMutableString string];
        for (id item in failedList) {
            if([item isKindOfClass:[BundleResourceItem class]]) {
                BundleResourceItem *bundleItem = item;
                [content appendFormat:@"%@\n",[bundleItem consoleFormat]];
                [htmlContent appendFormat:@"%@<br/>",[bundleItem htmlFormat]];
            }else if([item isKindOfClass:[CarResourceItem class]]) {
                CarResourceItem *carItem = item;
                [content appendFormat:@"%@\n",[carItem consoleFormat]];
                [htmlContent appendFormat:@"%@<br/>",[carItem htmlFormat]];
            }
        }
        message = content;
        html = htmlContent;
    }
    if(completionBlock) {
        completionBlock(pass,message,html);
    }
}

@end
