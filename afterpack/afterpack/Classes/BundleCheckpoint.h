//
//  BundleCheckpoint.h
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/10.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BundleInfo.h"

extern NSString * const kBundleCheckpointAuthorName;
extern NSString * const kBundleCheckpointAuthorLink;

/**
 * string -> NSString
 * boolean -> BOOL
 */
typedef NS_ENUM(NSInteger, BundleCheckValueType) {
    BundleCheckValueString,
    BundleCheckValueBoolean,
};

@interface BundleCheckOptionDefinition : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *tip;
@property (nonatomic, assign) BundleCheckValueType valueType;
@property (nonatomic, strong) NSString *defaultValue;
@property (nonatomic, strong) NSString *key;

@end

@interface BundleCheckpointOption : NSObject

@property (nonatomic, strong) BundleCheckOptionDefinition* defination;
@property (nonatomic, strong) NSString *value;

@end

@protocol BundleCheckPointProtocol <NSObject>

+ (NSString *)name;
+ (NSDictionary *)author;
+ (NSString *)identifier;
+ (NSArray<BundleCheckOptionDefinition *> *)optionList;
+ (BOOL)validateOptionValue: (NSString *)optionKey value: (NSString *)value;
- (void)runWithBundleInfo: (BundleInfo *)bundleInfo
                  options: (NSDictionary<NSString *, BundleCheckpointOption*> *)optionValues
             onCompletion: (void (^)(BOOL pass,NSString *console,NSString *html))completionBlock;



@end

@interface BundleCheckpoint : NSObject<BundleCheckPointProtocol>

@end


@interface BundleCheckpointRecord : NSObject

@property (nonatomic, strong) BundleCheckpoint *checkpoint;
@property (nonatomic, strong) NSArray<BundleCheckpointOption *> *options;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *html;

@end

