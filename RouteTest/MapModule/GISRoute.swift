//
//  Route.swift
//  RouteTest
//
//  Created by Omer Katzir on 02/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import CoreLocation

class GISRoute: NSObject {
    
    private var points: [vector_float2]! = []
    private var coordinates: [CLLocationCoordinate2D]!
    
    init(coords: [CLLocationCoordinate2D]) {
        super.init()
        coordinates = coords
        coords.forEach { (coord) in
            points.append(coord - coords[0])
        }
    }
}
