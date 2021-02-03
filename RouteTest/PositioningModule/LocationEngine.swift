//
//  LocationManager.swift
//  RouteTest
//
//  Created by Omer Katzir on 19/11/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import CoreLocation

@objc protocol LocationDelegate {
    func onLocationUpdate(location: CLLocation)
    @objc optional func onHeadingUpdate(heading: CLHeading)
}

class LocationEngine: NSObject {
    
    static var shared: LocationEngine = LocationEngine()
    private var locationManager: CLLocationManager!
    private var running: Bool = false
    private var authorised: Bool = false

    var delegate: LocationDelegate? = nil
    var route: [CLLocationCoordinate2D]! = []
    
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = 50.0

        
    }
    
    func run() {
        running = true
        locationManager.headingOrientation = .landscapeLeft
        
        if !authorised {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.startUpdatingLocation()
        }
        locationManager.startUpdatingHeading()
    }
    
    func stop() {
        running = false
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
    }

}


extension LocationEngine: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if delegate != nil {
            delegate!.onHeadingUpdate?(heading: newHeading)
            locationManager.requestLocation()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if delegate != nil && locations.last != nil {
            delegate!.onLocationUpdate(location: locations.last!)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let allow: Bool = status == .authorizedAlways || status == .authorizedWhenInUse
        if allow {
            authorised = true
            if running {
                locationManager.startUpdatingLocation()
            }
        } else {
            authorised = false
        }
    }
}

