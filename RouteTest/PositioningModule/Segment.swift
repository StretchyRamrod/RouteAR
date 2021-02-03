//
//  Segment.swift
//  RouteTest
//
//  Created by Omer Katzir on 08/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import Foundation


struct Segment {
    var from: vector_float3
    var to: vector_float3
    
    init(_ from: vector_float3, _ to: vector_float3) {
        self.from = from
        self.to = to
    }
    
    var azimut: Angle {
       get {
           let dv = to - from
        return Angle(atan2(dv.x, -dv.z))
       }
   }
    
    var length: Float {
        get {
            return (from - to).length
        }
    }
    
}
