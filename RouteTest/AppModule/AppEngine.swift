//
//  AppEngine.swift
//  RouteTest
//
//  Created by Omer Katzir on 05/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

protocol AppEngineDelegate {
    func onRouteChanged(route: [vector_float3])
}

class AppEngine: NSObject {
    
    static var shared: AppEngine = AppEngine()
    
    var route: [vector_float3] = []
    var gisRoute: [CLocation] = []
    var gisConverter: GISToLocalConverter = GISToLocalConverter()
    
    override init() {
        super.init()
        
     
    }
}

extension AppEngine: IMapDelegate {
    
    func onDirectionsChanged(coords: [CLocation], centerCoord: CLocation) {
        gisRoute = coords
        gisConverter.origin = centerCoord
    }
}

