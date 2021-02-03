//
//  RouteNode.swift
//  RouteTest
//
//  Created by Omer Katzir on 04/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import SceneKit


class RouteGeometry: NSObject {
    private var points: [vector_float3]! = []
    private var width: Float! = 1.0
    private var geo: SCNGeometry! = nil
    var geometry: SCNGeometry! { get { return geo } }
    
    init(points: [vector_float3], width: Float, height: Float = 0) {
        super.init()
        
        self.points = points
        self.width = width
        
        var lVerts: [SCNVector3] = []
        var rVerts: [SCNVector3] = []
        var verts: [SCNVector3] = []
        var lNorms: [SCNVector3] = []
        var rNorms: [SCNVector3] = []
        var norms: [SCNVector3] = []
        var lTexs: [CGPoint] = []
        var rTexs: [CGPoint] = []
        var texs: [CGPoint] = []
        
        
        var smoothed: [vector_float3] = []
        (0...(points.count-3)).forEach { (i) in
            let v1 = points[i+1] - points[i]
            let v2 = points[i+2] - points[i+1]
            
            let ang = Angle(acos(v1.norm * v2.norm))
            
            let l = width * 0.5 * ang.sin
            let v1_ = points[i+1] - v1.norm * l
            let v2_ = points[i+1] + v2.norm * l
            
        }
    
        
        var len: Float = 0;
        (0...(points.count-2)).forEach { (i) in
            let v = points[i]
            let vUp = vector_float3(0, height, 0)
            let upN = vector_float3(0, 1.0, 0)
            let nextV = points[i+1]
            let dv = nextV - v
            let dvoN = normalize(vector_float3(x: -dv.z, y: 0, z: dv.x))
            let dvo = dvoN * width * 0.5
            
            (0...(i == points.count-3 ? 1 : 2)).forEach { (_) in
                verts.append(SCNVector3(v + vUp))
                rVerts.append(SCNVector3(v + dvo))
                lVerts.append(SCNVector3(v - dvo))
                
                norms.append(SCNVector3(upN))
                rNorms.append(SCNVector3(normalize(vUp + dvoN * 2.0)))
                lNorms.append(SCNVector3(normalize(vUp - dvoN * 2.0)))
                
                texs.append(CGPoint(x: 0.5, y: CGFloat(len))) // y: CGFloat(i) / CGFloat(points.count)))
                rTexs.append(CGPoint(x: 1, y: CGFloat(len))) //y: CGFloat(i) / CGFloat(points.count)))
                lTexs.append(CGPoint(x: 0, y: CGFloat(len))) //y: CGFloat(i) / CGFloat(points.count)))
                len += dv.length
            }
        }
        
        let N = Int32(verts.count)
        verts.append(contentsOf: rVerts)
        verts.append(contentsOf: lVerts)
        norms.append(contentsOf: rNorms)
        norms.append(contentsOf: lNorms)
        texs.append(contentsOf: rTexs)
        texs.append(contentsOf: lTexs)
        
        
        var elements: [SCNGeometryElement] = []
        
        Array(0...(N-2)).forEach { (i) in
            let ii = Int32(i)
            elements.append(SCNGeometryElement(indices: [ii, ii+N, ii+1, ii+1+N], primitiveType: .triangleStrip))
            elements.append(SCNGeometryElement(indices: [ii + 2*N, ii, ii + 1 + 2*N, ii + 1 ], primitiveType: .triangleStrip))
        }
        
        geo = SCNGeometry(sources: [
            SCNGeometrySource(vertices: verts),
            SCNGeometrySource(normals: norms),
            SCNGeometrySource(textureCoordinates: texs),
            ], elements: elements
        )
        
        guard let shaderURL = Bundle.main.url(forResource: "surface", withExtension: "shader"),
            let surfModifier = try? String(contentsOf: shaderURL)
            else { fatalError("Can't load shader from bundle.") }

        guard let shaderURL2 = Bundle.main.url(forResource: "geo", withExtension: "shader"),
            let geoModifier = try? String(contentsOf: shaderURL2)
            else { fatalError("Can't load shader from bundle.") }

        geo.shaderModifiers = [.surface: surfModifier, .geometry: geoModifier]
    }
    
}
