//
//  BundleInfo.h
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/10.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BundleResourceItem : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) BOOL bRegularFile;
@property (nonatomic, assign) BOOL bDirectory;
@property (nonatomic, assign) BOOL bPackage;
@property (nonatomic, assign) BOOL bHidden;
@property (nonatomic, assign) BOOL bExecutable;
@property (nonatomic, strong) NSString *utiType;
@property (nonatomic, assign) NSUInteger fileSize;
@property (nonatomic, strong, nullable) NSDate *creationDate;
@property (nonatomic, strong, nullable) NSDate *modificationDate;
@property (nonatomic, assign) NSUInteger level;
//mime type

- (NSString *)consoleFormat;
- (NSString *)htmlFormat;

@end

//(from ThemeEngine)
typedef NS_ENUM(long long, CoreThemeType) {
    CoreThemeTypeOnePart             = 0,
    CoreThemeTypeThreePartHorizontal = 1,
    CoreThemeTypeThreePartVertical   = 2,
    CoreThemeTypeNinePart            = 3,
    CoreThemeTypeSixPart             = 5,
    CoreThemeTypeGradient            = 6,
    CoreThemeTypeEffect              = 7,
    CoreThemeTypeAnimation           = 8,
    CoreThemeTypePDF                 = 9,
    
    CoreThemeTypeRawData             = 1000, // raw Data
    CoreThemeTypeAssetPack           = 1004, // ZZZPackedAssets-1.0.0/2.0.0 I've seen subtype 10
    CoreThemeTypeColor               = 1009, // color
};

@interface CarResourceItem : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *assetName;
@property (nonatomic, assign) CoreThemeType assetType;
//if save to disk
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) NSUInteger fileSize;
//if image
@property (nonatomic, assign) float imageWidth;
@property (nonatomic, assign) float imageHeight;

- (NSString *)consoleFormat;
- (NSString *)htmlFormat;

@end

@interface BundleInfo : NSObject

@property (nonatomic, strong) NSString *bundlePath;
@property (nonatomic, strong) NSArray<BundleResourceItem *> *resourceList;
@property (nonatomic, strong) NSArray<CarResourceItem *> *carResourceList;

@end


