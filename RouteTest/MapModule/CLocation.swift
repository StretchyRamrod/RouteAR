//
//  CLocation.swift
//  RouteTest
//
//  Created by Omer Katzir on 22/01/2021.
//  Copyright © 2021 Omer Katzir. All rights reserved.
//

import UIKit
import CoreLocation

class CLocation: NSObject {

    var longitude: Float!
    var latitude: Float!
    var altitude: Float!
    
    var coord: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        }
    }
    
    func distance(_ to: CLocation) -> Float{
        return (to - self).length
    }
    
    init(lat: Float, lon: Float, alt: Float = 0) {
        latitude = lat
        longitude = lon
        altitude = alt
    }
    
    convenience init(_ coord: CLLocationCoordinate2D, alt: Float) {
        self.init(lat: Float(coord.latitude), lon: Float(coord.longitude), alt: alt)
    }
    
    convenience init(_ location: CLLocation) {
        self.init(location.coordinate, alt: Float(location.altitude))
    }
 
    static func - (l1: CLocation, l2: CLocation) -> vector_float3 {
        let dc = l1.coord - l2.coord
        return vector_float3(dc.x, l1.altitude - l2.altitude, dc.y)
    }
    
    static func + (from: CLocation, acc: vector_float3) -> CLocation {
        let coord = from.coord + acc.xz
        return CLocation(coord, alt: from.altitude + acc.y)
    }
}


extension CLLocationCoordinate2D {
    init(_ loc: CLocation) {
        self = CLLocationCoordinate2D(latitude: Double(loc.latitude), longitude: Double(loc.longitude))
    }
}


extension Sequence where Element: CLocation {
    var coords: [CLLocationCoordinate2D] {
        get {
            return self.map({ (loc) -> CLLocationCoordinate2D in
                return loc.coord
            })
        }
    }
}


extension Sequence where Iterator.Element == (coord: CLLocationCoordinate2D, alt: Float) {
    var locations: [CLocation] {
        get {
            return self.map { (p) -> CLocation in
                return CLocation(p.coord, alt: p.alt)
            }
        }
    }
}
