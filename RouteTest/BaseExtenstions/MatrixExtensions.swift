//
//  MatrixExtensions.swift
//  RouteTest
//
//  Created by Omer Katzir on 06/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import Foundation
import SwiftUI

enum Axis {
    case X
    case Y
    case Z
}



extension float3x3 {
    private static let ROT_MAP: [Axis: (_ angle: Angle) -> float3x3] = [
              .X: float3x3.xRotation,
              .Y: float3x3.yRotation,
              .Z: float3x3.zRotation
          ]
    
    static var identity: float3x3 {
        return float3x3(diagonal: [1, 1, 1])
    }
    
    var homogenous: float4x4 {
        get {
            return float4x4(columns: (
                simd_float4(self.columns.0,  0),
                simd_float4(self.columns.1,  0),
                simd_float4(self.columns.2,  0),
                [0, 0, 0, 1]
            ))
        }
    }
    
    var heading: vector_float3 {
        return self * vector_float3(0, 0, -1)
    }
    
    var down: vector_float3 {
        return self * vector_float3(0, -1, 0)
    }
    
    var right: vector_float3 {
        return self * vector_float3(-1, 0 ,0)
    }
    
    var azimut: Angle {
        let head = heading
        return Angle(atan2(head.x, -head.z))
    }
        
    var euler: Euler {
        get {
            
            let vHead = heading
            let vRight = right
            
            
            let pitch = Angle(atan2(vHead.y, vHead.xz.length))
            let yaw = Angle(atan2(-vHead.x, -vHead.z))
            
            
            let vX_ = vector_float3(yaw.cos, 0.0, (yaw * -1.0).sin)
            let vY_ = vector_float3(pitch.sin * yaw.sin, pitch.cos, pitch.sin * yaw.cos)
            
            
            let roll =  Angle(atan2(vRight * vY_, vRight * vX_)) - Angle(Float.pi)
            
            return Euler(pitch, yaw, roll)
            
        }
        
    }
    
    var euler2: Euler {
        get {
            let (R11, R21, R31) = (columns.0.x, columns.0.y, columns.0.z)
            let (R12, _, R32) = (columns.1.x, columns.1.y, columns.1.z)
            let (R13, _, R33) = (columns.2.x, columns.2.y, columns.2.z)
            
            if (fabsf(R31) <= .ulpOfOne) {
                if (R31 < 0) {
                    return Euler(atan2(R12, R13), .pi * 0.5,  0.0)
                } else {
                    return Euler(atan2(-R12, -R13), -.pi * 0.5, 0.0)
                }
            }
            
            let yaw = -asin(R31)
            let cosy = cos(yaw)
            return Euler(atan2(R32 / cosy, R33 / cosy), yaw, atan2(R21 / cosy, R11 / cosy))
            
        }
    }
    
    init(angle: Angle, axis: Axis) {
              self = float3x3.ROT_MAP[axis]!(angle)
    }
   
    init(euler: Euler, order: [Axis] = [.Y, .X, .Z]) {
        let degMap: [Axis: Angle] = [
            .X: euler.pitch,
            .Y: euler.yaw,
            .Z: euler.roll
        ]
        
        var res = float3x3(diagonal: [1, 1, 1])
        for a in order {
            res = res * float3x3.ROT_MAP[a]!(degMap[a]!)
        }
        
        self = res
    }
    
    static func xRotation (_ angle: Angle) -> float3x3 {
        let rads = angle.radians
        let cs = cos(rads)
        let ss = sin(rads)
        return float3x3(rows: [
            [1, 0, 0],
            [0, cs, -ss],
            [0, ss, cs],
        ])
    }
    
    static func yRotation (_ angle: Angle) -> float3x3 {
        let rads = angle.radians
        let cs = cos(rads)
        let ss = sin(rads)
        return float3x3(rows: [
            [cs, 0, ss],
            [0, 1, 0],
            [-ss, 0, cs],
        ])
    }
    
    static func zRotation (_ angle: Angle) -> float3x3 {
        let rads = angle.radians
        let cs = cos(rads)
        let ss = sin(rads)
        return float3x3(rows: [
            [cs, -ss, 0],
            [ss, cs, 0],
            [0, 0, 1]
        ])
    }
    
    static func vRotations(_ angle: Angle, v: vector_float3) -> float3x3 {
        let radians = angle.radians
        let cs = cos(radians)
        let ss = sin(radians)
        let cs_1 = (1 - cs)
        let vx2 = v.x * v.x
        let vy2 = v.y * v.y
        let vz2 = v.z * v.z
        let vxy = v.x * v.y
        let vxz = v.x * v.z
        let vyz = v.y * v.z
        
        
        return float3x3(rows: [
            [cs + vx2 * cs_1, vxy * cs_1 - v.z * ss, vxz * cs_1 + v.y * ss],
            [vxy * cs_1 + v.z * ss, cs + vy2 * cs_1, vyz * cs - v.x * ss],
            [vxz * cs_1 - v.y * ss, vyz * cs_1 + v.x * ss, cs + vz2 * cs_1]
        ])
    }
}

extension float4x4 {
    static var identity: float4x4 {
        return float4x4(diagonal: [1, 1, 1, 1])
    }
    
    var translation: vector_float3 {
        get {
            return columns.3.xyz
        }
        
        set (trans) {
            columns.3 = vector_float4([trans.x, trans.y, trans.z, 1])
        }
    }

    var rotationMatrix: float3x3 {
        get {
            return float3x3(rows: [
                [self.columns.0.x, self.columns.1.x, self.columns.2.x],
                [self.columns.0.y, self.columns.1.y, self.columns.2.y],
                [self.columns.0.z, self.columns.1.z, self.columns.2.z],
            ])
        }
        
        set (val) {
            self = float4x4(rotMat: val,  translation: self.translation)
        }
    }
    
    init(rotMat: float3x3, translation: vector_float3) {
        self = float4x4(columns: (
            [rotMat.columns.0.x, rotMat.columns.0.y, rotMat.columns.0.z, 0],
            [rotMat.columns.1.x, rotMat.columns.1.y, rotMat.columns.1.z, 0],
            [rotMat.columns.2.x, rotMat.columns.2.y, rotMat.columns.2.z, 0],
            [translation.x, translation.y, translation.z, 1]
        ))
    }
    
    init(rotMat: float3x3, translation: vector_float4) {
        self.init(rotMat: rotMat, translation: vector_float3(translation))
    }
}
