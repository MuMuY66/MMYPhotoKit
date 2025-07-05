//
//  MMYCVPhoto.cpp
//  MMYPhotoKit
//
//  Created by alimysoyang on 12/18/24.
//

#include <string>
#include <vector>

#include "MMYCVPhoto.hpp"

//static ncnn::UnlockedPoolAllocator g_blob_pool_allocator;
//static ncnn::PoolAllocator g_workspace_pool_allocator;

static ncnn::Net bgnet;

MMYCVPhoto::MMYCVPhoto() {
    
}

MMYCVPhoto::~MMYCVPhoto() {
    bgnet.clear();
}

bool MMYCVPhoto::modelInit(const char* param, const char* bin) {
    ncnn::Option opt;
    opt.lightmode = true;
    opt.num_threads = 4;
//    opt.blob_allocator = &g_blob_pool_allocator;
//    opt.workspace_allocator = &g_workspace_pool_allocator;
    
    bgnet.opt = opt;
    int ret0 = bgnet.load_param(param);
    int ret1 = bgnet.load_model(bin);
    if (ret0 != 0) {
        return false;
    }
    if (ret1 != 0) {
        return false;
    }
    return true;
}

cv::Mat MMYCVPhoto::photoProcess(const uint8_t* pixel,
                                 uint32_t width,
                                 uint32_t height,
                                 int* background) {
    int img_w = width;
    int img_h = height;
    
    ncnn::Mat in = ncnn::Mat::from_pixels(pixel, ncnn::Mat::PIXEL_RGBA2RGB, img_w, img_h);
    cv::Mat rgb = cv::Mat::zeros(in.h, in.w, CV_8UC3);
    in.to_pixels(rgb.data, ncnn::Mat::PIXEL_RGB);
    
    int rwidth = rgb.cols;
    int rheight = rgb.rows;
    ncnn::Mat in_resize = ncnn::Mat::from_pixels_resize(rgb.data, ncnn::Mat::PIXEL_RGB, rgb.cols, rgb.rows, 512, 512);
    const float meanVals[3] = { 127.5f, 127.5f,  127.5f };
    const float normVals[3] = { 0.0078431f, 0.0078431f, 0.0078431f };
    in_resize.substract_mean_normalize(meanVals, normVals);
    ncnn::Mat out;
    ncnn::Extractor ex = bgnet.create_extractor();
    ex.input("input", in_resize);
    ex.extract("output", out);
    
    ncnn::Mat alpha;
    ncnn::resize_bilinear(out, alpha, rwidth, rheight);
    cv::Mat blendImg = cv::Mat::zeros(cv::Size(rwidth, rheight), CV_8UC3);
    
    float* alpha_data = (float *)alpha.data;
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            float alpha_ = alpha_data[i*width+j];
            blendImg.at < cv::Vec3b>(i, j)[0] = rgb.at < cv::Vec3b>(i, j)[0] * alpha_ + (1 - alpha_) * background[0];
            blendImg.at < cv::Vec3b>(i, j)[1] = rgb.at < cv::Vec3b>(i, j)[1] * alpha_ + (1 - alpha_) * background[1];
            blendImg.at < cv::Vec3b>(i, j)[2] = rgb.at < cv::Vec3b>(i, j)[2] * alpha_ + (1 - alpha_) * background[2];
        }
    }
    
    in.release();
    in_resize.release();
    out.release();
    rgb.release();
    alpha.release();
    ex.clear();
    
    return blendImg;
}
