//
//  MMYPhotoKitManager.h
//  MMYPhotoKit
//
//  Created by alimysoyang on 12/18/24.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Vision/Vision.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MMYFaceStatus) {
    /// 未检测到人脸
    MMY_FS_NONE = 0,
    /// 一张人脸
    MMY_FS_ONE = 1,
    /// 多张人脸
    MMY_FS_EXCESSIVE = 2,
    /// 不是正脸
    MMY_FS_NOFRONTAL = 3
};

@interface MMYPhotoKitManager : NSObject
/// 侦测图片中是否有人脸(只有一张正面人脸符合要求)
/// - Parameter image: 原始图片
- (MMYFaceStatus)detectFace:(UIImage *)image;

- (BOOL)isFaceOccupyingMajorSpace:(VNFaceObservation *)faceObservation;
/// 抠图处理(返回叠加了背景颜色的图片)
/// - Parameters:
///   - image: 原始图片
///   - backgroundColor: 叠加背景颜色
- (nullable UIImage *)photoProcess:(UIImage *)image backgroundColor:(UIColor *)backgroundColor;

@end

NS_ASSUME_NONNULL_END
