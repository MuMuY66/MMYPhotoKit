//
//  MMYPhotoKitManager.m
//  MMYPhotoKit
//
//  Created by alimysoyang on 12/18/24.
//

#import "MMYPhotoKitManager.h"
#import "MMYCVPhoto.hpp"
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import <CoreImage/CoreImage.h>
#import <CoreImage/CIFilterBuiltins.h>

@interface MMYPhotoKitManager()

/// 模型文件是否加载成功
@property (assign, nonatomic) BOOL isLoaded;

@end

@implementation MMYPhotoKitManager {
    MMYCVPhoto *photo;
}

#pragma mark - life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource: @"ModelRes" ofType: @"bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *binPath = [bundle pathForResource:@"mobilenetv2" ofType:@"bin"];
        NSString *paramPath = [bundle pathForResource:@"mobilenetv2" ofType:@"param"];
        self->photo = new MMYCVPhoto();
        if (self->photo->modelInit([paramPath UTF8String], [binPath UTF8String])) {
            self.isLoaded = YES;
        } else {
            self.isLoaded = NO;
            NSLog(@"Load model file failed!");
        }
    }
    return self;
}

- (void)dealloc {
    self->photo->~MMYCVPhoto();
}

#pragma mark - private methods
/// 判断人脸是否是正脸
/// - Parameter faceObservation:
- (BOOL)isFaceFrontal:(VNFaceObservation *)faceObservation {
   CGFloat radiansToDegrees = 180.0 / M_PI;
   
   NSNumber *rollValue = faceObservation.roll;
   NSNumber *yawValue = faceObservation.yaw;
   NSNumber *pitchValue = faceObservation.pitch;
   
   if (!rollValue || !yawValue || !pitchValue) {
       return NO;
   }
   
   CGFloat rollDegrees = [rollValue floatValue] * radiansToDegrees;
   CGFloat yawDegrees = [yawValue floatValue] * radiansToDegrees;
   CGFloat pitchDegrees = [pitchValue floatValue] * radiansToDegrees;
   
   CGFloat acceptableRange = 10.0;
   
   BOOL isFrontal = (fabs(rollDegrees) <= acceptableRange &&
                     fabs(yawDegrees) <= acceptableRange &&
                     fabs(pitchDegrees) <= acceptableRange);
   
   return isFrontal;
}

- (BOOL)isFaceOccupyingMajorSpace:(VNFaceObservation *)faceObservation {
    // 检查参数是否有效
    if (!faceObservation) {
        return NO;
    }
    
    // 获取人脸的边界框
    CGRect faceBounds = faceObservation.boundingBox;
    
    // 计算人脸区域占整个图像的比例
    CGFloat faceArea = faceBounds.size.width * faceBounds.size.height;
    
    // 由于boundingBox是标准化的坐标(0-1)，所以faceArea直接表示占比
    CGFloat occupancyRatio = faceArea * 100; // 转换为百分比
    
    // 检查角度是否在合理范围内
    if (faceObservation.roll && faceObservation.yaw && faceObservation.pitch) {
        // 检查是否在合理角度范围内
        BOOL isValidAngle = [self isFaceFrontal:faceObservation];
        
        // 返回结果：面积占比不能超过50%且角度合理
        return (occupancyRatio < 50.0 && isValidAngle);
    }
    // 如果角度数据缺失，只判断面积占比
    return occupancyRatio < 50.0;
}

#pragma mark - public methods
- (MMYFaceStatus)detectFace:(UIImage *)image {
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    if (!ciImage) {
        return MMY_FS_NONE;
    }
    
    __block MMYFaceStatus hasFace = MMY_FS_NONE;
    VNDetectFaceRectanglesRequest *request = [[VNDetectFaceRectanglesRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        NSArray<VNFaceObservation *> *observations = request.results;
        if (observations) {
            if (observations.count == 0) {
                hasFace = MMY_FS_NONE;
            } else if (observations.count == 1) {
                if ([self isFaceFrontal:observations[0]]) {
                    hasFace = MMY_FS_ONE;
                } else {
                    hasFace = MMY_FS_NOFRONTAL;
                }
            } else {
                hasFace = MMY_FS_EXCESSIVE;
            }
        }
    }];
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:ciImage options:@{}];
    NSError *error;
    BOOL success = [handler performRequests:@[request] error:&error];
    if (!success) {
        NSLog(@"Face detection failed: %@", error);
        return MMY_FS_NONE;
    }
    
    return hasFace;
}

- (UIImage *)photoProcess:(UIImage *)image backgroundColor:(UIColor *)backgroundColor {
    if (!self.isLoaded) {
        return nil;
    }
    
    int w = image.size.width;
    int h = image.size.height;
    unsigned char* rgba = new unsigned char[w * h * 4];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef contextRef = CGBitmapContextCreate(rgba,
                                                    w,
                                                    h,
                                                    8,
                                                    w * 4,
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, w, h), image.CGImage);
    CGContextRelease(contextRef);
    
    CGFloat r = 0;
    CGFloat g = 0;
    CGFloat b = 0;
    CGFloat a = 0;
    [backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    int colors[3] = {(int)(r * 255), (int)(g * 255), (int)(b * 255)};
    
    cv::Mat mat = self->photo->photoProcess(rgba,
                              (uint32_t)w,
                              (uint32_t)h,
                              colors);

    cv::Mat cvtMat;
    if (mat.channels() == 4) {
        cv::cvtColor(mat, cvtMat, cv::COLOR_BGRA2BGR);
    } else if (mat.channels() == 1) {
        cv::cvtColor(mat, cvtMat, cv::COLOR_GRAY2BGR);
    } else {
        cvtMat = mat;
    }
    
    // Create a CGImageRef from the cv::Mat
    NSData *tmpData = [NSData dataWithBytes:cvtMat.data length:cvtMat.elemSize() * cvtMat.total()];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)tmpData);
    
    int cols = cvtMat.cols;
    int rows = cvtMat.rows;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGImageRef imageRef = CGImageCreate(cols,                                   // Width
                                        rows,                                   // Height
                                        8,                                      // Bits per component
                                        8 * cvtMat.elemSize(),                  // Bits per pixel
                                        cvtMat.step[0],                         // Bytes per row
                                        colorSpaceRef,                          // Colorspace
                                        bitmapInfo,                             // Bitmap info
                                        provider,                               // CGDataProvider
                                        NULL,                                   // Decode
                                        false,                                  // Should interpolate
                                        kCGRenderingIntentDefault);             // Intent
    
    // Create a UIImage from the CGImageRef
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    
    // Clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGColorSpaceRelease(colorSpace);
    cvtMat.release();
    delete[] rgba;
    return result;
}

@end
