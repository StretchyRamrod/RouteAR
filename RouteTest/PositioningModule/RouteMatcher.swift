//
//  RouteMatcher.swift
//  RouteTest
//
//  Created by Omer Katzir on 08/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit



class RouteMatcher: NSObject {

    private var route: [vector_float3]!
    private var azimToSegments: [Int: [Segment]]!
    private var segments: [Segment]!
    private var azimBulkSize: Angle! = Angle(degrees: 25.0)
    private var distanceTH: Float! = 20.0
    
    init(route: [vector_float3]) {
        super.init()
        self.route = route
        
        self.processRoute()
    }
    
    func match(_ trx: float4x4) -> vector_float3 {
        let pos = vector_float3(trx.columns.3)
        let rotMat = trx.rotationMatrix
        let azim = rotMat.azimut
        
        let candidates = getSegments(azim)
        var closeSegs: [Segment] = []
        var dists: [Float] = []
        var dazims: [Float] = []
        var closests: [vector_float3] = []
        
        for cand in candidates {
            let (closest, dist) = pos.closestPointTo(v0: cand.from, v1: cand.to)
            if dist <= distanceTH {
                closeSegs.append(cand)
                dists.append(dist)
                dazims.append(fabsf((azim - cand.azimut).radians))
                closests.append(closest)
            }
        }
        
        if closeSegs.isEmpty {
            return trx.columns.3.xyz
        }
        
        var minScore: Float = dists[0] + dazims[0]
        var bestSegIdx = 0
        
        for i in Array(0...closeSegs.count-1) {
            let dazim = dazims[i]
            let dist = dists[i]
            
            let score = dist + dazim
            if score < minScore {
                minScore = score
                bestSegIdx = i
            }
            
        }
        
        print("Closest: ", closests[bestSegIdx])
        return closests[bestSegIdx]
        
    }
    
}


private extension RouteMatcher {
    
    func processRoute() {
        
        segments = processSegments(route)
        azimToSegments = processAzims(segments, bulkSize: azimBulkSize)
    }
    
    func processSegments(_ route: [vector_float3]) -> [Segment] {
        var segs: [Segment] = []
        
        for i in Array(0...route.count-2) {
            segs.append(Segment(route[i], route[i+1]))
        }
        
        return segs
    }
    
    func processAzims(_ segments: [Segment], bulkSize: Angle) -> [Int: [Segment]] {
        var azimToSeg: [Int: [Segment]] = [:]
        
        
        for seg in segments {
            
            let bulk = azimToBulk(seg.azimut)
            
            if azimToSeg[bulk] == nil {
                azimToSeg[bulk] = []
            }
            
            azimToSeg[bulk]!.append(seg)
            
        }
        
        return azimToSeg
    }
    
    
    func azimToBulk(_ azim: Angle) -> Int {
            
        var deg  = azim.degrees
        if deg < 0 {
            deg += 360
        }
        return Int(deg / azimBulkSize.degrees)
    }
    
    func getSegments(_ azim: Angle) -> [Segment] {
        
        let bulk0 = azimToBulk(azim)
        let bulk1 = azimToBulk(azim + azimBulkSize * 0.5)
        let bulk2 = azimToBulk(azim - azimBulkSize * 0.5)
        
        let bulks = Set([bulk0, bulk1, bulk2])
        
        var segments: [Segment] = []
        
        for bulk in bulks {
            if let segs = azimToSegments[bulk] {
                segments.append(contentsOf: segs)
            }
        }
        
        return segments
    }
    
    
}


