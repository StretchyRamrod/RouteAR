//
//  ARKitEngine.swift
//  RouteTest
//
//  Created by Omer Katzir on 21/11/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import ARKit

protocol AREngineDelegate {
    func onFrameUpdate(frame: ARFrame)
}

class ARKitEngine: NSObject {
    
    private var session: ARSession!
    var delegate: AREngineDelegate? = nil
    
    override init() {
        super.init()
        
        
        session = ARSession()
        session.delegate = self
    //    session.setWorldOrigin(relativeTransform: simd_float4x4(SCNMatrix4(m11: 0, m12: 0, m13: 0, m14: 0, m21: 0, m22: 0, m23: 0, m24: 0, m31: 0, m32: 0, m33: 0, m34: 0, m41: 0, m42: 0, m43: 0, m44: 1)))

    }
    
    func run() {
        let config = ARWorldTrackingConfiguration()
        session.run(config, options: ARSession.RunOptions())
    }

}


extension ARKitEngine: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        OpenCVAdaptor.updateARFrame(frame.capturedImage)
        
        
        if delegate != nil {
            delegate?.onFrameUpdate(frame: frame)
        }
    }
}
