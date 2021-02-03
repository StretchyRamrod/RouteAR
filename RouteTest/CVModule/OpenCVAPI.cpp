//
//  OpenCVTest.cpp
//  RouteTest
//
//  Created by Omer Katzir on 21/11/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

#include "OpenCVAPI.hpp"

#include <opencv2/ximgproc.hpp>
#include <opencv2/opencv.hpp>
#include <vector>

using namespace cv;
using namespace cv::ximgproc;
using namespace std;


COpenCVAPI* COpenCVAPI::m_shared = NULL;


COpenCVAPI::COpenCVAPI() {
    m_frame = NULL;
    
    for (int i=0; i<4 ;i++){
        m_RAvg[i] = 0;
        m_LAvg[i] = 0;
    }
  
}

COpenCVAPI::~COpenCVAPI() {

}


COpenCVAPI* COpenCVAPI::Instance() {
    if (m_shared == NULL)
        m_shared = new COpenCVAPI();
    
    return m_shared;
}


void COpenCVAPI::InitCV() {
    Ptr<FastLineDetector> detector = createFastLineDetector();
    
}

void COpenCVAPI::UpdateFrameHough(void *buffer, int width, int height, int bytesPerPixel) {


    if(m_frame != NULL)
        delete m_frame;
        
    Mat m  = cv::Mat(height, width, CV_8UC1, buffer);

    float scale = 0.25;
    int newWidth = width * scale;
    int newHeight = height * scale;
    m_frame = new cv::Mat(newHeight, newWidth, CV_8UC1);
    cv::resize(m, *m_frame, Size(newWidth, newHeight), INTER_LINEAR);


    auto cropped = Mat(*m_frame, Rect(0, newHeight * 0.5, newWidth, newHeight * 0.5));
        

    Sobel(cropped, cropped, CV_8UC1, 1, 0, 3);
    Canny(cropped, cropped, 100, 200);
      
    vector<Vec4f> lines;
    HoughLinesP(cropped, lines, 6, 3.14/180, 160, 40, 25 );
    
    for( size_t i = 0; i < lines.size(); i++ )
    {
        line( *m_frame, Point(lines[i][0], lines[i][1]),
            Point(lines[i][2], lines[i][3]), Scalar(255), 3, 8 );
    }
    

}

void COpenCVAPI::UpdateFrameDetector(void *buffer, int width, int height, int bytesPerPixel) {
    

    if(m_frame != NULL)
        delete m_frame;
        
    Mat m  = cv::Mat(height, width, CV_8UC1, buffer);
    
    float scale = 0.25;
    int newWidth = width * scale;
    int newHeight = height * scale;
    m_frame = new cv::Mat(newHeight, newWidth, CV_8UC1);
    cv::resize(m, *m_frame, Size(newWidth, newHeight), INTER_LINEAR);
    
    
    auto cropped = Mat(*m_frame, Rect(0, newHeight * 0.5, newWidth, newHeight * 0.5));
    
    
    GaussianBlur(cropped, cropped, Size(3,3), 0);
    Sobel(cropped, cropped, CV_8UC1, 1, 0, 3);
    auto kernel = getStructuringElement(MORPH_DILATE, Size(7,7));
    dilate(cropped, cropped, kernel);
    
    float avg = mean(cropped)[0];
    float sigma = 0.33;
    auto lower = int(fmax(0, (1.0 - sigma) * avg));
    auto upper = int(fmin(255, (1.0 + sigma) * avg));
    Ptr<FastLineDetector> detector = createFastLineDetector(newHeight * 0.15, newHeight * 0.4, 50, 100, 3);
      
    vector<Vec4f> lines;
    detector->detect(cropped, lines);
    
    vector<Vec4f> rLines;
    vector<Vec4f> lLines;
    int midX = newWidth * 0.5;
    
  
    for (auto v : lines) {
        auto pt1 =  Point(v[0], v[1] + newHeight * 0.5);
        auto pt2 = Point(v[2], v[3] + newHeight * 0.5);
        auto upperPt = pt1.y < pt2.y ? pt1 : pt2;
        auto lowerPt = pt1.y < pt2.y ? pt2 : pt1;
        
        circle(*m_frame, upperPt, 3, Scalar(255));
        auto angle = atan2(upperPt.x - lowerPt.x, -upperPt.y + lowerPt.y) * 180.0 / M_PI;
        
        if(lowerPt.x > midX) {
            if (angle < -10.0 && angle > -60.0 )
                rLines.push_back(Vec4f(upperPt.x ,upperPt.y, lowerPt.x, lowerPt.y));
        } else {
            if (angle > 10.0 && angle < 80.0)
                lLines.push_back(Vec4f(upperPt.x ,upperPt.y, lowerPt.x, lowerPt.y));
        }
            
        //line(*m_frame, pt1, pt2, Scalar(255));
    }
    
    if  (rLines.size() < 1 || lLines.size() < 1) {
        return;
    }
    
    Vec4f lAvg(0, 0, 0, 0);
    Vec4f rAvg(0, 0, 0, 0);
    
    for (auto v : rLines) {
        auto pt1 =  Point(v[0], v[1] + newHeight * 0.5);
        auto pt2 = Point(v[2], v[3] + newHeight * 0.5);
        
        rAvg = rAvg + v;
        line(*m_frame, pt1, pt2, Scalar(255), 3);
    }
    
    rAvg /= (float)rLines.size();

    for (auto v : lLines) {
        auto pt1 =  Point(v[0], v[1] + newHeight * 0.5);
        auto pt2 = Point(v[2], v[3] + newHeight * 0.5);
        lAvg = lAvg + v;
        line(*m_frame, pt1, pt2, Scalar(255), 3);
    }
    lAvg /= (float)lLines.size();

    for (int i=0;i<4;i++) {
        m_RAvg[i] = m_RAvg[i] + (rAvg[i] - m_RAvg[i]) * 1;
        m_LAvg[i] = m_LAvg[i] + (lAvg[i] - m_LAvg[i]) * 1;
    }
    
    
    Point2f trPt(m_RAvg[0], m_RAvg[1]);
    Point2f brPt(m_RAvg[2], m_RAvg[3]);
    Point2f tlPt(m_LAvg[0], m_LAvg[1]);
    Point2f blPt(m_LAvg[2], m_LAvg[3]);
    
   
    Point2f x = blPt - brPt;
    Point2f d1 = trPt - brPt;
    Point2f d2 = tlPt - blPt;

    float cross = d1.x*d2.y - d1.y*d2.x;
    if (abs(cross) > /*EPS*/1e-8) {

        double t1 = (x.x * d2.y - x.y * d2.x)/cross;
        Point2f r = brPt + d1 * t1;
        circle(*m_frame, r, 10, Scalar(255), 5);
    }


    circle(*m_frame, Point(m_RAvg[0], m_RAvg[1]), 5, Scalar(255), 3);
    circle(*m_frame, Point(m_RAvg[2], m_RAvg[3]), 5, Scalar(255), 3);
    circle(*m_frame, Point(m_LAvg[0], m_LAvg[1]), 5, Scalar(255), 3);
    circle(*m_frame, Point(m_LAvg[2], m_LAvg[3]), 5, Scalar(255), 3);


    
   // detector->drawSegments(*m_frame, lines);
}


void COpenCVAPI::UpdateFrame(void *buffer, int width, int height, int bytesPerPixel) {
    
    //UpdateFrameHough(buffer, width, height, bytesPerPixel);
    UpdateFrameDetector(buffer, width, height, bytesPerPixel);
}

const Mat* COpenCVAPI::GetFrame() {
      
    return m_frame;
    
}

