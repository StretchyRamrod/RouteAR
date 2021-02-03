//
//  GPSSimulator.swift
//  RouteTest
//
//  Created by Omer Katzir on 18/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import CoreLocation


class GPSSimulator: NSObject {
    
    private var gisRoute: [CLocation]!
    private var route: [vector_float3]!
    private var speed: Double = 0.0
    private var acceleration: Double = 1.0
    private var maxSpeed: Double = 18.0
    var currentCoord: CLocation!
    private var currentPos: vector_float3!
    private var nextCoordIdx: Int = 0
    private var timestamp: TimeInterval!
    private var displayLink: CADisplayLink!
    
    var delegate: LocationDelegate? = nil
    
    init(gisRoute: [CLocation]) {
        super.init()
        self.gisRoute = gisRoute
        route = GISToLocalConverter.shared.convert(gisRoute)
    }
    
    func reset() {
        timestamp = Date.timeIntervalSinceReferenceDate
        speed = 0.0
        acceleration = 0.1
        nextCoordIdx = 1
        currentCoord = gisRoute[0]
        currentPos = route[0]
        delegate?.onLocationUpdate(location: CLLocation(coordinate: currentCoord.coord, altitude: Double(currentCoord.altitude), horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: speed, timestamp: Date(timeIntervalSince1970: timestamp)))
              
    }
    
    func run() {
        
        reset()
        displayLink = CADisplayLink(target: self, selector: #selector(onUpdate))
        displayLink.preferredFramesPerSecond = 2
        displayLink.add(to: .current, forMode: .common)
    }
    
    func stop() {
        
        displayLink.remove(from: .current, forMode: .common)
    }
    
    
    @objc private func onUpdate() {
        let dt = Date.timeIntervalSinceReferenceDate - timestamp
        
        speed += acceleration * dt
        if speed >= maxSpeed {
            speed = maxSpeed
            acceleration = 0.0
        }
        
        let dist: Float = Float(dt * speed)
        
       // updatePosition(dist: dist)
        updateCoord(dist: dist)
        timestamp = Date.timeIntervalSinceReferenceDate
        
    }
    
    private func updatePosition(dist: Float) {
        var dist_ = dist
        
        while (dist_ > 0) {
            
            let nextPos = route[nextCoordIdx]
            let curPos: vector_float3
            (newPos: curPos, leftDist: dist_) = advance(pos: currentPos, nextPos: nextPos, distance: dist_)
            
            if simd_length(curPos - currentPos) > dist * 2 {
                print(curPos)
            }
            
            currentPos = curPos
            
            if dist_ <= 0.0 {
                let cloc = GISToLocalConverter.shared.convert([vector_float3(currentPos.x, 0.0, currentPos.y)])[0]
                let location = CLLocation(coordinate: cloc.coord, altitude: Double(cloc.altitude), horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: speed, timestamp: Date(timeIntervalSinceReferenceDate: timestamp))
                
                if simd_length(currentCoord - cloc) > 100.0 {
                    print(curPos)
                }
                currentCoord = cloc
                delegate?.onLocationUpdate(location: location)
            } else {
            
                nextCoordIdx += 1
                if nextCoordIdx >= gisRoute.count {
                    reset()
                    return
                }
            }
        }
    }
    
    private func advance(pos: vector_float3, nextPos: vector_float3, distance: Float) -> (newPos: vector_float3, leftDist: Float) {
        let dv = nextPos - pos
        let left = simd_length(dv)
        
        if left > distance {
            return (newPos: pos + normalize(dv) * distance, leftDist: 0.0)
        }
        
        return (newPos: nextPos, leftDist: distance - left)
    }
    
    private func updateCoord(dist: Float) {
        var dist_ = dist
        
        
        
        print(GISToLocalConverter.shared.convert(currentCoord))
        
        while (dist_ > 0) {
            
            let nextCoord = gisRoute[nextCoordIdx]
            (newCoord: currentCoord, leftDist: dist_) = advance(coord: currentCoord, nextCoord: nextCoord, distance: dist_)
            
            if dist_ <= 0.0 {
                let rx = Float.random(in: -5.0...5.0)
                let ry = Float.random(in: -5.0...5.0)
                let coord = currentCoord!// + vector_float2([rx, ry])

                let location = CLLocation(coordinate: coord.coord, altitude: Double(coord.altitude), horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: speed, timestamp: Date.init(timeIntervalSince1970: timestamp))
                                
                delegate?.onLocationUpdate(location: location)
            } else {
            
                nextCoordIdx += 1
                if nextCoordIdx >= gisRoute.count {
                    reset()
                    return
                }
            }
        }
    }
    
    private func advance(coord: CLocation, nextCoord: CLocation, distance: Float) -> (newCoord: CLocation, leftDist: Float) {
        
        let dCoords = (nextCoord - coord)
        let left = simd_length(dCoords)
        
        if left > distance {
            return (newCoord: coord + normalize(dCoords) * distance, leftDist: 0.0)
        }
        
        return (newCoord: nextCoord, leftDist: distance - left)
    }

}
