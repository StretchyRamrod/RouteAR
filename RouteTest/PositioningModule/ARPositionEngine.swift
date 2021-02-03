//
//  ARPositionEngine.swift
//  RouteTest
//
//  Created by Omer Katzir on 12/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import CoreLocation
import ARKit


struct GPSSnapshot {
    var gpsPos: vector_float3
    var azim: Angle
}

class ARPositionEngine: NSObject {

    private var running: Bool = false
    private var arTransform: float4x4 = float4x4(diagonal: [1, 1, 1, 1])
    private var updateTimestamp: TimeInterval = 0.0
    private var prevTranslation: vector_float3 = vector_float3([0, 0, 0])
    
    private var prevGps: CLLocation! = nil
    private var prevGpsAzim: Angle! = Angle(0.0)
    private var gpsSnapshots: [GPSSnapshot] = []
    private var gpsErr: vector_float2 = vector_float2([0, 0])
    private var R_translation: Float = 0.0
    private var R_heading: Float = 0.0
    private var R_compass: Float = 0.01
    private var gpsSamples: [vector_float3] = []
    
    private var route: [vector_float3] = []
    
    
    private var gps: LocationEngine = LocationEngine()
    private var gpsSimulator: GPSSimulator!
    private var routeMatcher: RouteMatcher!
      
    private var posOffset: vector_float3 = vector_float3([0, 0, 0])
    private var accTranslationOffset: vector_float2 = vector_float2([0, 0]);
    private var prevArTranslation: vector_float2! = vector_float2([0, 0])
      
    private var azimOffset: Angle = Angle(0.0)
    
    var azimByMinLine: Bool = false
    var strictRouteMatch: Bool = true
    var speed: Float = 0.0
    
    init(gisRoute: [CLocation]) {
        super.init()
        route = GISToLocalConverter.shared.convert(gisRoute) //, elevations: elevations)
        gps.delegate = self
        
        gpsSimulator = GPSSimulator(gisRoute: gisRoute)
        gpsSimulator.delegate = self
        
        routeMatcher = RouteMatcher(route: route)
    }
    
    func run() {
        gps.run()
        //gpsSimulator.run()
        running = true
    }
    
    func stop() {
        running = false
        gps.stop()
        //gpsSimulator.stop()
    }
    
    
    func updateFrame(_ frame: ARFrame) -> float4x4 {
        if !running { return float4x4.identity }
        
        let dt = frame.timestamp - updateTimestamp
        updateTimestamp = frame.timestamp
        let ct = Float(dt / (0.5 + dt))
        
        self.arTransform = frame.camera.transform
        R_translation *= 1.0 - Float(dt / (1.0 + dt))
        R_heading *= 1.0 - Float(dt / (1.0 + dt))
    
        
        matchRoute(dt: dt)
        
       // print(posOffset, azimOffset.degrees, ct)
              
        let translationOffset = posOffset * ct
        let yRotOffset = azimOffset * ct
        posOffset -= translationOffset
        azimOffset = azimOffset - yRotOffset

        
        var offset = float4x4.identity
        offset.translation = arTransform.translation
        offset = offset * float3x3.yRotation(yRotOffset).homogenous
        var posMat = float4x4.identity
        posMat.translation = -arTransform.translation + translationOffset
        offset = offset * posMat
        //offset.columns.3.y = arTransform.translation.y - 1.5
        
        let newArTraslation = arTransform.translation.xz + accTranslationOffset
        accTranslationOffset += offset.translation.xz
        
        let dArTranslation = newArTraslation - prevArTranslation
        
        let newArSpeed = dArTranslation.length / Float(dt)
        let newSpeed = speed * (1 - ct) + newArSpeed * ct
        let speedCtR = ct * (1.0 - (speed - newSpeed).absRatio(min_: 1.0, max_: 3.0))
        speed = speed * (1 - speedCtR) + newArSpeed * speedCtR
        
        prevArTranslation = newArTraslation
        
        
        
        print(speed)

        return offset
    }
    
    private func calcR(rRef: Float, rTotal: Float)  -> (R_ref: Float, R_fused: Float) {
        let (r1, r2) = (rRef, rTotal)
        
        if (r1 + r2) == 0 {
            return (0.0, 0.0)
        }
        
        return (r1 / (r1 + r2), sqrt(r1 * r1 + r2 * r2) / (r1 + r2))
    }
    
    private func matchRoute(dt: Double) {
        var trx = arTransform
        trx.translation = trx.translation - posOffset
        trx.translation.y -= 1.5
        
        let posMatch = routeMatcher.match(trx)
        
        var dPos = trx.translation - posMatch
        
        let maxDist: Float = strictRouteMatch ? 0.0 : 10.0
        
        let R_match =  dPos.length.ratio(min_: 0.0, max_: maxDist)// * Float(dt / (0.1 + dt))
        
        posOffset += dPos * R_match
            
    }
    
}


extension ARPositionEngine: LocationDelegate {
    func onLocationUpdate(location: CLLocation) {
        if !running {return}
        
        if prevGps == nil {
            prevGps = location
        }
        
        let dt = location.timestamp.timeIntervalSinceReferenceDate - prevGps.timestamp.timeIntervalSinceReferenceDate
        if dt <= 0 {
            return
        }
        let arTranslation = arTransform.translation + posOffset
        let gpsPos = GISToLocalConverter.shared.convert(location)
        let R_gps: Float = (arTranslation - gpsPos).length.ratio(min_: 10.0, max_: 80) * (1.0 - R_translation)
        let prevGpsPos = GISToLocalConverter.shared.convert(prevGps)
        let dGps = gpsPos - prevGpsPos
        let gpsSpeed =  Float(location.speed)
        let dSpeedR = (1.0 - (speed - gpsSpeed).absRatio(min_: 2.0, max_: 5))
        //speed = gpsSpeed
        
        let gpsAzim =  Angle(atan2(dGps.x, -dGps.z))
        let dGpsAzim = gpsAzim - prevGpsAzim

        let (R_refPos, R_fusedPos) = calcR(rRef: R_gps, rTotal: R_translation)
                        
        
        let R_gpsAzim: Float = speed.ratio(min_: 3.0, max_: 10.0) * (1.0 - fabsf(dGpsAzim.degrees).ratio(min_: 0.0, max_: 10.0 / Float(dt))) * dSpeedR
        prevGps = location
        prevGpsAzim = gpsAzim
        
        
        var azimOffset = Angle(0.0)
        var R_fusedAzim = Float(0.0)
        
        if azimByMinLine {
            gpsSnapshots.append(GPSSnapshot(gpsPos: gpsPos, azim: arTransform.rotationMatrix.azimut + azimOffset))
            let (avgAzim, stdDev) = avgAzimFromGpsSnapshots()
            let (azimOffset_, R_fusedAzim_) = updateAzim(newAzim: avgAzim, R_azim: 1.0 - stdDev.ratio(min_: 0.5, max_: 2.0))
            azimOffset = azimOffset_
            R_fusedAzim = R_fusedAzim_
        } else {
            let (azimOffset_, R_fusedAzim_) = updateAzim(newAzim: gpsAzim, R_azim: R_gpsAzim)
            azimOffset = azimOffset_
            R_fusedAzim = R_fusedAzim_
        }
        
        
        let dPos = (arTranslation - gpsPos) * R_refPos
        R_translation = R_fusedPos
        R_heading = R_fusedAzim
        
        posOffset = dPos
        self.azimOffset = azimOffset
        
        
    }
    
    
    func onHeadingUpdate(heading: CLHeading) {
        if !running {return}

        let compassAzim = Angle(degrees: Float(heading.magneticHeading)) + arTransform.rotationMatrix.euler.roll
    
        let (azimOffset, R_fusedAzim) = updateAzim(newAzim: compassAzim, R_azim: R_compass)
        
        R_heading = R_fusedAzim
        
        self.azimOffset = self.azimOffset + azimOffset
    }
    
    
    private func updateAzim(newAzim: Angle, R_azim: Float) -> (azimOffset: Angle, R_fused: Float) {
        let azim = arTransform.rotationMatrix.azimut + azimOffset
        
        let R_azim_ = R_azim  * fabsf((arTransform.rotationMatrix.azimut - newAzim).degrees).ratio(min_: 0.0, max_: 30.0) * (1.0 - R_heading)
                    
        let (fusedR, newR) = calcR(rRef: R_azim_, rTotal: R_heading)
        let dAzim = (newAzim - azim) * fusedR
        
        //print(R_heading)
        return (azimOffset: dAzim, R_fused: newR)

    }
    
    private func avgAzimFromGpsSnapshots() -> (Angle, Float) {
        if gpsSnapshots.count < 5 { return (Angle(0.0), 0.0)}
        if gpsSnapshots.count > 10 {
            gpsSnapshots.remove(at: 0)
        }
        
        let dist = (gpsSnapshots.first!.gpsPos - gpsSnapshots.last!.gpsPos).length
        if dist < 20.0 { return (Angle(0.0), 0.0)}
            
        let vecs = gpsSnapshots.map({ (snap) -> vector_float2 in
            return vector_float2([snap.gpsPos.x, -snap.gpsPos.z])
        })
        
        let (M, b) = minLine(vecs)
        
        let dv = vecs.last! - vecs.first!
        let azim_ = Angle(atan2(dv.x, dv.y))
                      
        var avgAzim = Angle(atan(1 / M)) - Angle(Float.pi)
        if fabsf((azim_ - avgAzim).degrees) > 90.0 {
            avgAzim = avgAzim + Angle(Float.pi)
        }
        
        let avgErr = vecs.reduce(into: Float(0.0)) { (acc, vec) in
            let closest = vector_float2([
                (M * vec.y + vec.x - M * b) / (M * M + 1),
                (M * (vec.x + M * vec.y) + b ) / (M * M + 1)
            ])
            acc = acc + (vec - closest).length / Float(vecs.count)
        }
        
        var stdDev = vecs.reduce(into: Float(0.0)) { (acc, vec) in
            let closest = vector_float2([
                (M * vec.y + vec.x - M * b) / (M * M + 1),
                (M * (vec.x + M * vec.y) + b ) / (M * M + 1)
            ])
            let err = (vec - closest).length
            acc = acc + pow(err - avgErr, 2.0) / Float(vecs.count)
        }
        
        stdDev = sqrt(stdDev)
        
        return (avgAzim, stdDev)
        
    }
    
    
    private func minLine(_ vecs: [vector_float2]) -> (slope: Float, b: Float){
        
        var X: Float = 0.0
        var Y: Float = 0.0
        
        vecs.forEach { (vec) in
            X += vec.x
            Y += vec.y
        }
        
        X /= Float(vecs.count)
        Y /= Float(vecs.count)
        
        var m_: Float = 0.0
        var m: Float = 0.0
        vecs.forEach { (vec) in
            m_ += pow((vec.x - X), 2)
            m += (vec.x - X) * (vec.y - Y)
            
        }
        
        var M = m / m_
        
        let b = Y - M * X
        
        
        return (M, b)
        
    }
}
