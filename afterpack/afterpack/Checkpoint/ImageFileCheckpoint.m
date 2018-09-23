//
//  ImageFileCheckpoint.m
//  afterpack
//
//  Created by zhangxiaogang on 2018/9/19.
//  Copyright © 2018 lifebetter. All rights reserved.
//

#import "ImageFileCheckpoint.h"
@import AppKit;

@implementation ImageFileCheckpoint

+ (NSString *)name {
    return @"Image Check";
}

+ (NSDictionary *)author {
    return @{
             kBundleCheckpointAuthorName : @"",
             kBundleCheckpointAuthorLink : @"",
             };
}

+ (NSString *)identifier {
    return @"image";
}

+ (NSArray<BundleCheckOptionDefinition *> *)optionList {
    //disk size
    BundleCheckOptionDefinition *sizeOption = [[BundleCheckOptionDefinition alloc] init];
    sizeOption.name = @"disk size";
    sizeOption.tip = @"upper limitation (default 600kb)";
    sizeOption.defaultValue = @"600";
    sizeOption.valueType = BundleCheckValueString;
    sizeOption.key = @"diskSize";
    //dimension size
    BundleCheckOptionDefinition *dimensionOption = [[BundleCheckOptionDefinition alloc] init];
    dimensionOption.name = @"dimension size";
    dimensionOption.tip = @"dimension size limitation (default 1024,1024)";
    dimensionOption.defaultValue = @"1024,1024";
    dimensionOption.valueType = BundleCheckValueString;
    dimensionOption.key = @"dimension";
    return @[sizeOption,dimensionOption];
}

+ (BOOL)validateOptionValue:(NSString *)optionKey value:(NSString *)value {
    BOOL pass = NO;
    if([optionKey isEqualToString:@"diskSize"]) {
        float floatValue = [value floatValue];
        if(floatValue > 0) {
            pass = YES;
        }
    }else if([optionKey isEqualToString:@"dimension"]) {
        NSArray *components = [value componentsSeparatedByString:@","];
        if(components.count == 2) {
            float width = [components[0] floatValue];
            float height = [components[1] floatValue];
            if(width > 0 && height > 0) {
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
    NSMutableArray *failedSizeList = [NSMutableArray array];
    NSMutableArray *failedDimensionList = [NSMutableArray array];
    BundleCheckpointOption *diskSizeOption = optionValues[@"diskSize"];
    NSUInteger maxDiskSize = (NSUInteger)([diskSizeOption.value floatValue] * 1024);
    BundleCheckpointOption *dimensionOption = optionValues[@"dimension"];
    NSString *dimensionValue = dimensionOption.value;
    NSArray *components = [dimensionValue componentsSeparatedByString:@","];
    float maxWidth = [components[0] floatValue];
    float maxHeight = [components[1] floatValue];
    //file list
    if(bundleInfo.resourceList.count > 0) {
        //find image file
        NSMutableArray<BundleResourceItem *> *imageResources = [NSMutableArray array];
        for (BundleResourceItem *item in bundleInfo.resourceList) {
            NSString *utiType = [item utiType];
            BOOL isImage = [self isImageFileByUTI:utiType];
            if(isImage) {
                [imageResources addObject:item];
            }
        }
        
        for (BundleResourceItem *item in imageResources) {
            //disk size check
            if(item.fileSize > maxDiskSize) {
                [failedSizeList addObject:item];
            }
            //dimension size check
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:[item path]];
            float imageWidth = image.size.width;
            float imageHeight = image.size.height;
            if(imageWidth > maxWidth || imageHeight > maxHeight) {
                [failedDimensionList addObject:item];
            }
        }
    }
    //car resource
    if(bundleInfo.carResourceList.count > 0) {
        for (CarResourceItem *item in bundleInfo.carResourceList) {
            //filter image
            if(item.assetType == CoreThemeTypeOnePart) {
                //check disk size
                if(item.fileSize > maxDiskSize) {
                    [failedSizeList addObject:item];
                }
                //check dimension size
                if(item.imageWidth > maxWidth || item.imageHeight > maxHeight) {
                    [failedDimensionList addObject:item];
                }
            }
        }
    }
    BOOL pass = (failedSizeList.count ==0 && failedDimensionList.count == 0);
    NSString *message = nil;
    NSString *html = nil;
    if(!pass) {
        NSMutableString *content = [NSMutableString string];
        NSMutableString *htmlContent = [NSMutableString string];
        if(failedSizeList.count > 0) {
            [content appendFormat:@"➡️ %@ failed items:\n",diskSizeOption.defination.name];
            [htmlContent appendFormat:@"➡️ %@ failed items:<br/>",diskSizeOption.defination.name];
            for (id item in failedSizeList) {
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
        }
        if(failedDimensionList.count > 0) {
            [content appendFormat:@"➡️ %@ failed items:\n",dimensionOption.defination.name];
            [htmlContent appendFormat:@"➡️ %@ failed items:<br/>",dimensionOption.defination.name];
            for (id item in failedDimensionList) {
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
        }
        message = content;
        html = htmlContent;
    }
    completionBlock(pass,message,html);
}


//UTI  /System/Library/CoreServices/CoreTypes.bundle/Contents/Info.plist
- (BOOL)isImageFileByUTI: (NSString *)utiType {
    BOOL ret = NO;
    CFStringRef testUTI = (__bridge CFStringRef)(@"public.image");
    if(UTTypeConformsTo((__bridge CFStringRef)utiType, testUTI)){
        ret = YES;
    }
    return ret;
}

@end
