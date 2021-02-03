//
//  OpenCVAdaptor.h
//  RouteTest
//
//  Created by Omer Katzir on 21/11/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

#ifndef OpenCVAdaptor_h
#define OpenCVAdaptor_h

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>


@interface OpenCVAdaptor: NSObject



+(void)initCV;
+(void)updateFrame:(void*)buffer width:(NSInteger)width height:(NSInteger)height bytesPerPixel:(NSInteger)bytesPerPixel;

+(void)updateARFrame:(CVPixelBufferRef)frame;
+(UIImage*)getFrame;

@end

#endif /* OpenCVAdaptor_h */
