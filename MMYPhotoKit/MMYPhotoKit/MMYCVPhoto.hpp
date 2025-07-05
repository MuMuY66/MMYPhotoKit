//
//  MMYCVPhoto.hpp
//  MMYPhotoKit
//
//  Created by alimysoyang on 12/18/24.
//

#ifndef MMYCVPhoto_hpp
#define MMYCVPhoto_hpp

#include <stdio.h>

// ncnn
#include "net.h"
#include "benchmark.h"
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>

class MMYCVPhoto {
public:
    MMYCVPhoto();
    ~MMYCVPhoto(void);
    
    bool modelInit(const char* param, const char* bin);
    
    cv::Mat photoProcess(const uint8_t* pixel,
                         uint32_t width,
                         uint32_t height,
                         int* background);
};
#endif /* MMYCVPhoto_hpp */
