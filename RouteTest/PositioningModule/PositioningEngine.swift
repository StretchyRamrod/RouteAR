//
//  PositioningEngine.swift
//  RouteTest
//
//  Created by Omer Katzir on 01/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation
import SceneKit
import QuartzCore

class PositioningEngine: NSObject {
    
    private var lastGyroData: CMGyroData! = nil
    
    private var updateTimestamp: TimeInterval = -1.0
    private var arTransform: float4x4! = float4x4(diagonal: [1, 1, 1, 1])
    var arOffset: float4x4! = float4x4(diagonal: [1, 1, 1, 1])
    private var prevArTimestamp: TimeInterval! = nil
    private var prevArTranslation: vector_float3! = vector_float3([0,0,0])
    private var prevTranslationOnAr: vector_float3! = vector_float3([0,0,0])
    private var prevArRotation: Euler! = Euler(Float(0.0), 0.0, 0.0)
    private var sensors: SensorsEngine! = SensorsEngine()
    private var gps: LocationEngine! = LocationEngine()
    private var prevGps: CLLocation! = nil
    private var routeMatcher: RouteMatcher!
    
    var transform: float4x4! = float4x4(diagonal: [1, 1, 1, 1,])
    
    var displayTransform: float4x4! = float4x4(diagonal: [1, 1, 1, 1])
    private var speed: Float! = 0.0
    private var speedOffset: Float = 0.0
    
    private var R_transform: Float = 0.0
    private var R_translation: Float = 0.0
    private var R_heading: Float = 0.0
    private var R_pitch: Float = 0.0
    private var R_roll: Float = 0.0
    private var R_speed: Float = 0.0
    
    private var R_gps: Float = 1.0
    private var R_gpsHeading: Float = 0.0
    private var R_compass: Float = 0.05
    private var R_ArEngine: Float = 1.0
    private var R_acclPitch: Float = 1.0
    private var R_acclRoll: Float = 1.0
    
    private var displayLink: CADisplayLink!
    
    init(route: [CLocation]) {
        super.init()
        
        
        routeMatcher = RouteMatcher(route: GISToLocalConverter.shared.convert(route))
        
      //  displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLink))
      //  displayLink.preferredFramesPerSecond = 60
      //  displayLink.add(to: .current, forMode: .common)
        
       // sensors.delegate = self
       // sensors.run()
        
        gps.delegate = self
        gps.run()
    }
    
    @objc private func onDisplayLink() {
        
        let gyroQueue = sensors.dumpGyroQueue()
        if gyroQueue.isEmpty {
            return
        }
        
        let timestamp = gyroQueue.last!.timestamp
    
        gyroQueue.forEach { (data) in
            //self.update(gyroData: data)
        }
                
        if let data = sensors.lastAccData {
            //self.update(accData: data)
        }
        
        if let data = sensors.lastMagData {
           // self.update(magData: data.field)
        }
    
        let dt = updateTimestamp - timestamp
        
        updateTimestamp = timestamp
        
      //  transform.translation = transform.translation + speed * Float(dt)
        
       
    }
    
    
    
    private func calcR(r1: Float, r2: Float)  -> (fusedR: Float, rAdjusted: Float) {
        if (r1 + r2) == 0 {
            return (0.0, 0.0)
        }
        
        return (r1 / (r1 + r2), (r1 * r1 + r2 * r2) / (r1 + r2))// sqrt(r1 * r1 + r2 * r2) / (r1 + r2))
        
    }

}


extension PositioningEngine: AREngineDelegate {
    func onFrameUpdate(frame: ARFrame) {
        arTransform = frame.camera.transform
        transform = arTransform // arOffset * frame.camera.transform
    }
}


extension PositioningEngine: LocationDelegate {
    func onLocationUpdate(location: CLLocation) {
        if prevGps == nil {
            prevGps = location
        }
        
        let gpsPos = GISToLocalConverter.shared.convert(location)
        R_gps = 1.0 - (transform.translation - gpsPos).length.ratio(min_: 0.0, max_: 20.0) * 0.95
        
        let (Rpos, newRpos) = calcR(r1: R_gps, r2: R_translation)
        R_translation = newRpos
                        
        let gpsSpeed = Float(location.speed)
        
        R_speed = gpsSpeed.ratio(min_: 3.0, max_: 8.0) * 0.95
        
        let prevGpsPos = GISToLocalConverter.shared.convert(prevGps)
        let dGps = gpsPos - prevGpsPos
        let gpsAzim = Angle(atan2(dGps.x, dGps.z))
        let RgpsAzim = gpsSpeed.ratio(min_: 6.0, max_: 10.0)
        
        prevGps = location
        
        updateAzim(newAzim: gpsAzim, R_azim: RgpsAzim)
    //    arOffset.translation = arOffset.translation - (gpsPos - transform.translation) * Rpos
        
    }
    
    
    func onHeadingUpdate(heading: CLHeading) {
        
        let compassAzim = Angle(degrees: Float(heading.magneticHeading)) + transform.rotationMatrix.euler.roll
    
        updateAzim(newAzim: compassAzim, R_azim: R_compass)
    }
    
    
    private func updateAzim(newAzim: Angle, R_azim: Float) {
        let azim = transform.rotationMatrix.azimut
              
        let (fusedR, newR) = calcR(r1: R_azim, r2: R_heading)
        let dAzim = (newAzim - azim) * fusedR
        R_heading = newR

        arOffset.rotationMatrix = float3x3.yRotation(dAzim)
    }
}


extension PositioningEngine {
    
    private func update(gyroData: CMGyroData) {
        if lastGyroData == nil {
            lastGyroData = gyroData
              return
        }
        
        let dt = Float(gyroData.timestamp - lastGyroData.timestamp)
        if dt <= 0.0 {
            return
        }
        
        lastGyroData = gyroData
        let gyroRates = Euler(-gyroData.rotationRate.y, gyroData.rotationRate.x, gyroData.rotationRate.z)
        transform.rotationMatrix = transform.rotationMatrix * (gyroRates * dt).rotationMatrix
        
        R_acclRoll = 1.0 - min(fabsf(gyroRates.yaw.degrees) / (90.0 / 4.0), 1.0)
    
    }
    
    private func update(accData: CMAcceleration) {
        
        let vAcc = vector_float3([accData.y, -accData.x, accData.z])
        
        let accPitch = Angle(atan2(vAcc.z, vAcc.y))
        let accRoll = Angle(atan2(vAcc.x, simd_length(vector_float2(vAcc.y,vAcc.z))))
        
        let (rRoll, newRRoll) = calcR(r1: R_acclRoll, r2: R_roll)
        R_roll = newRRoll
        let (rPitch, newRPitch) = calcR(r1: R_acclPitch, r2: R_pitch)
        R_pitch = newRPitch
        
        var euler = transform.rotationMatrix.euler
        euler.roll = euler.roll + (accRoll - euler.roll) * rRoll
        euler.pitch = euler.pitch + (accPitch - euler.pitch) * rPitch
        
        transform.rotationMatrix = euler.rotationMatrix
          
        
    }
    
    private func update(magData: CMMagneticField) {
        
        let euler = transform.rotationMatrix.euler
        let rotMat = float3x3(euler: Euler(euler.pitch, Angle(0.0), euler.roll), order: [.X, .Z])
        
        
        let vMag = vector_float3([magData.y, -magData.x, magData.z])
        
        let magAzim = Angle(atan2(-vMag.x, -vMag.z))
        
        let azim = transform.rotationMatrix.azimut
        
        let dazim = (magAzim - azim) * 0.01
        
        print("mag: ", magAzim.degrees, " azim: ", azim.degrees)
        
        transform = transform * float3x3(angle: dazim, axis: .Y).homogenous
    }
    
}
