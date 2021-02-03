//
//  LocationExtensions.swift
//  RouteTest
//
//  Created by Omer Katzir on 02/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import CoreLocation


extension CLLocationCoordinate2D {
    
    static func + (location: CLLocationCoordinate2D, vec: vector_float2) -> CLLocationCoordinate2D {
           let bearing = atan2(Double(vec.x), Double(-vec.y))
           let dist = simd_length(vec)
           return locationWithBearing(bearing: bearing, distanceMeters: dist, origin: location)
    }
    
    static func locationWithBearing(bearing: Double, distanceMeters:Float, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let d_r: Double = Double(distanceMeters) / (6372797.6)
               
        let lat1 = origin.latitude * .pi / 180.0
        let lon1 = origin.longitude * .pi / 180.0
        
        
        let lat2 = asin(sin(lat1) * cos(d_r) + cos(lat1) * sin(d_r) * cos(bearing) )

        let lon2 = lon1 + atan2(sin(bearing) * sin(d_r) * cos(lat1),
                                cos(d_r) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: CLLocationDegrees(lat2 * 180.0 / .pi), longitude: CLLocationDegrees(lon2 * 180.0 / .pi))
    }
    
    func bearing(to: CLLocationCoordinate2D) -> Double {
        let lat1 = self.latitude * .pi / 180.0
        let lon1 = self.longitude * .pi / 180.0
        let lat2 = to.latitude * .pi / 180.0
        let lon2 = to.longitude * .pi / 180.0
        
        let lonDiff = lon2 - lon1
        let y = sin(lonDiff) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lonDiff)
        let bearing = atan2(y, x)
        return bearing
    }
    
    
    static func - (to: CLLocationCoordinate2D, from: CLLocationCoordinate2D) -> vector_float2 {
       
        let dist = to.distance(from)
        
        let bearing = from.bearing(to: to)
        
        return vector_float2(Float(sin(bearing)), Float(-cos(bearing))) * Float(dist)
        
    }
    
    func distance(_ from: CLLocationCoordinate2D) -> Float {
        let dist = CLLocation(latitude: self.latitude, longitude: self.longitude).distance(from: CLLocation(latitude: from.latitude, longitude: from.longitude))
        
        return Float(dist)
    }
    
    
}
