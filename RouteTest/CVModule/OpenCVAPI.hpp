//
//  OpenCVTest.hpp
//  RouteTest
//
//  Created by Omer Katzir on 21/11/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

#ifndef OpenCVTest_hpp
#define OpenCVTest_hpp

#include <stdio.h>

namespace cv {
class Mat;
}

class COpenCVAPI {

private:
    
    static COpenCVAPI* m_shared;
    
protected:
    
    const cv::Mat* m_frame;
    
    float m_RAvg[4];
    float m_LAvg[4];
    
private:
    COpenCVAPI();
    
public:
    virtual ~COpenCVAPI();
    
    static COpenCVAPI* Instance();
    
public:
    void InitCV();

    void UpdateFrame(void* buffer, int width, int height, int bytesPerPixel = 1);

    const cv::Mat* GetFrame();
    
protected:
    
    void UpdateFrameDetector(void* buffer, int width, int height, int bytesPerPixel = 1);
    void UpdateFrameHough(void* buffer, int width, int height, int bytesPerPixel = 1);
    
};

#define OpenCVAPI (*COpenCVAPI::Instance())

#endif /* OpenCVTest_hpp */
