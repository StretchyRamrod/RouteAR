//
//  Angle.swift
//  RouteTest
//
//  Created by Omer Katzir on 08/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit


struct Angle {
    
    private var radians_: Float!
    private var degrees_: Float!
    
    var degrees: Float { get {return degrees_}}
    var radians: Float { get {return radians_}}
    
    init (_ radians: Float) {
        radians_ = setRad(radians)
        degrees_ = radians_ * 180.0 / .pi
    }
    
    init(_ radians: Double) {
        self.init(Float(radians))
    }
    
    init (degrees: Float) {
        radians_ = setRad(degrees * .pi / 180.0)
        degrees_ = radians_ * 180.0 / .pi
    }
    
    
    private func setRad(_ rad: Float) -> Float {
        if rad > .pi {
            return setRad(rad - .pi * 2.0)
        } else if rad <= -180 {
            return setRad(rad + .pi * 2.0)
        } else {
            return rad
        }
    }
        
    var cos: Float {
        
        get { return cosf(radians)}
    }
    
    var sin: Float {
        get { return sinf(radians)}
    }
    
    var description: String {
        return "degrees: \(degrees_)"
    }
    
}

extension Angle {
    static func - (a1: Angle, a2: Angle) -> Angle {
        var dDeg = a1.radians - a2.radians
        if dDeg > .pi {
            dDeg -= .pi * 2.0
        } else if dDeg <= -.pi {
            dDeg += .pi * 2.0
        }
        
        return Angle(dDeg)
    }
    
    static func + (a1: Angle, a2: Angle) -> Angle {
        return Angle(a1.radians_ + a2.radians_)
    }
    
    static func * (a: Angle, f: Float) -> Angle {
        return Angle(a.radians * f)
    }

}


struct Euler {
    var pitch: Angle
    var roll: Angle
    var yaw: Angle
    
    init(_ pitch: Float, _ yaw: Float, _ roll: Float) {
        self.pitch = Angle(pitch)
        self.roll = Angle(roll)
        self.yaw = Angle(yaw)
    }
    
    init(_ pitch: Double, _ yaw: Double, _ roll: Double) {
        self.pitch = Angle(pitch)
        self.roll = Angle(roll)
        self.yaw = Angle(yaw)
    }
    
    init(_ pitch: Angle, _ yaw: Angle, _ roll: Angle) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }
    
    var rotationMatrix: float3x3 {
        get {
            return float3x3(euler: self)
        }
    }
    
    var vector3: vector_float3 {
        return vector_float3(pitch.radians, yaw.radians, roll.radians)
    }
    
    static func * (euler: Euler, f: Float) -> Euler {
        return Euler(euler.pitch * f, euler.yaw * f, euler.roll * f)
    }
    
    static func + (e1: Euler, e2: Euler) -> Euler {
        return Euler(e1.pitch + e2.pitch, e1.yaw + e2.yaw, e1.roll + e2.roll)
    }
    
    
    static func - (e1: Euler, e2: Euler) -> Euler {
        return Euler(e1.pitch - e2.pitch, e1.yaw - e2.yaw, e1.roll - e2.roll)
    }
    
    var description: String {
        return "pitch: \(pitch.degrees),\n yaw: \(yaw.degrees),\n roll: \(roll.degrees)"
    }
    
}
