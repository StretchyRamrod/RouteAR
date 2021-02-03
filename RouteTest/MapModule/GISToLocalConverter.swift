//
//  GISToLocalConverter.swift
//  RouteTest
//
//  Created by Omer Katzir on 05/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import CoreLocation


class GISToLocalConverter: NSObject {
    
    static var shared: GISToLocalConverter = GISToLocalConverter()
    
    private var _origin: CLocation!
    
    func convert(_ locations: [CLocation]) -> [vector_float3] {
        return locations.map({loc -> vector_float3 in return loc - _origin})
        
    }
    
    func convert(_ vecs: [vector_float3]) -> [CLocation] {
        return vecs.map({ v -> CLocation in return _origin + v })
    }
    
    func convert(_ coord: CLLocationCoordinate2D, elevation: Float? = nil) -> vector_float3 {
        return CLocation(coord, alt: elevation ?? 0.0) - _origin
    }
    
    func convert(_ loc: CLocation) -> vector_float3 {
        return loc - _origin
        
    }
    
    func convert(_ location: CLLocation) -> vector_float3 {
        return convert(CLocation(location))
    }
    
    var origin: CLocation {
        get {
            return _origin
        }
        
        set(value) {
            _origin = value
        }
    }
    
}
