//
//  PositionData.swift
//  RouteTest
//
//  Created by Omer Katzir on 01/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation



struct PositionData {

    var gyroRate: CMGyroData!
    var accelerometer: CMAccelerometerData!
    var location: CLLocation!
    var timestamp: TimeInterval!
    
    
   
    
    static func transformRotation(rotationRates: vector_double3, referenceFrame: matrix_double3x3) -> vector_double3 {
        return simd_mul(referenceFrame, rotationRates);
    }
    
   
    
    
}






