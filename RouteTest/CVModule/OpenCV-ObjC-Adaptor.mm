//
//  OpenCV-ObjC-Adaptor.m
//  RouteTest
//
//  Created by Omer Katzir on 21/11/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

#include <opencv2/opencv.hpp>
#import "OpenCV-ObjC-Adaptor.h"
#include "OpenCVAPI.hpp"

@interface OpenCVAdaptor()
+(UIImage *)UIImageFromCVMat:(const cv::Mat&)cvMat;
@end

@implementation OpenCVAdaptor


+(void)initCV {
    
    OpenCVAPI.InitCV();
    
}


+(void)updateFrame:(void*)buffer width:(NSInteger)width height:(NSInteger)height bytesPerPixel:(NSInteger)bytesPerPixel {
    OpenCVAPI.UpdateFrame(buffer, int(width), int(height), int(bytesPerPixel));
}

+(void)updateARFrame:(CVPixelBufferRef)buffer {
    CVPixelBufferLockBaseAddress(buffer,  0);

       
    void* address = CVPixelBufferGetBaseAddress(buffer);
    size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    auto format = CVPixelBufferGetPixelFormatType(buffer);
    size_t bytesPerPixel_ = CVPixelBufferGetBytesPerRow(buffer) / width;

    OpenCVAPI.UpdateFrame(address, (int)width, (int)height, (int)bytesPerPixel_);

    CVPixelBufferUnlockBaseAddress(buffer,  0);
}



+(UIImage*)getFrame {
    
    
    const cv::Mat* pFrame = OpenCVAPI.GetFrame();
    if (!pFrame)
        return nil;
    
    return [OpenCVAdaptor UIImageFromCVMat:*pFrame];
    
//    int width = pFrame->cols;
//    int height = pFrame->rows;
//
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                                // [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
//                                // [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
//                                [NSNumber numberWithInt:width], kCVPixelBufferWidthKey,
//                                [NSNumber numberWithInt:height], kCVPixelBufferHeightKey,
//                                nil];
//
//       CVPixelBufferRef imageBuffer;
//       CVReturn status = CVPixelBufferCreate(kCFAllocatorMalloc, width, height, kCVPixelFormatType_, (CFDictionaryRef) CFBridgingRetain(options), &imageBuffer) ;
//
//
//       NSParameterAssert(status == kCVReturnSuccess && imageBuffer != NULL);
//
//       CVPixelBufferLockBaseAddress(imageBuffer, 0);
//       void *base = CVPixelBufferGetBaseAddress(imageBuffer) ;
//       memcpy(base, pFrame->data, pFrame->total());
//       CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//
//       return imageBuffer;
    
}


+(UIImage *)UIImageFromCVMat:(const cv::Mat&)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];

    CGColorSpaceRef colorSpace;
    CGBitmapInfo bitmapInfo;

    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
        bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGBitmapByteOrder32Little | (
                                                   cvMat.elemSize() == 3? kCGImageAlphaNone : kCGImageAlphaNoneSkipFirst
                                                   );
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(
                                        cvMat.cols,                 //width
                                        cvMat.rows,                 //height
                                        8,                          //bits per component
                                        8 * cvMat.elemSize(),       //bits per pixel
                                        cvMat.step[0],              //bytesPerRow
                                        colorSpace,                 //colorspace
                                        bitmapInfo,                 // bitmap info
                                        provider,                   //CGDataProviderRef
                                        NULL,                       //decode
                                        false,                      //should interpolate
                                        kCGRenderingIntentDefault   //intent
                                        );

    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1 orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return finalImage;
}



@end



