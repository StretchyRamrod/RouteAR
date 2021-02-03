//
//  GeometryExtensions.swift
//  RouteTest
//
//  Created by Omer Katzir on 08/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import Foundation


extension vector_float2 {
    var length: Float {
        return simd_length(self)
    }
    
    static func * (v1: vector_float2, v2: vector_float2) -> Float {
        return simd_dot(v1, v2)
    }
}


extension vector_float3 {
    
    func closestPointTo(v0: vector_float3, v1: vector_float3) -> (pt: vector_float3, distance: Float) {
        let v = v1 - v0
        let L = v.length
        let vN = normalize(v)
        let p = self - v0
        
        let cosv = simd_dot(p, vN)
        
    
        let closest = cosv > L ? v1 : (cosv < 0 ? v0 : v0 + vN * cosv)
        return (closest, (self - closest).length)
            
    }
   
    var length: Float {
        get {
            return simd_length(self)
        }
    }
    
    var norm: vector_float3 {
        get {
            return simd_normalize(self)
        }
    }
    
    func cross(_ other: vector_float3) -> vector_float3{
        return simd_cross(self, other)
    }
    
    
    static func ^ (v1: vector_float3, v2: vector_float3) -> vector_float3 {
        return simd_cross(v1, v2)
    }
    
    static func * (v1: vector_float3, v2: vector_float3) -> Float{
        return simd_dot(v1, v2)
    }
    
}


extension vector_float3 {
    init(_ v: vector_float4) {
        self = vector_float3(v.x, v.y, v.z)
    }
    
    var xy: vector_float2 {
        return vector_float2(x, y)
    }
    
    var xz: vector_float2 {
        return vector_float2(x,z)
    }
}


extension vector_float4 {
    var xyz: vector_float3 {
        return vector_float3(x, y, z)
    }
}


extension Float {
    
    func ratio(min_: Float, max_: Float, _ method: ((Float) -> Float)? = nil) -> Float {
        let r =  max(0.0, min(1.0, (self - min_) / (max_ - min_)))
        return method?(r) ?? r
    }
    
    func absRatio(min_: Float, max_: Float, _ method: ((Float) -> Float)? = nil) -> Float {
        return fabsf(self).ratio(min_: min_, max_: max_, method)
    }
    
}

