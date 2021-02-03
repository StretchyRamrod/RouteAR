//
//  ViewController.swift
//  RouteTest
//
//  Created by Omer Katzir on 19/11/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SwiftUI


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private var routeNode: SCNNode! = nil
    var cameraNode: SCNNode! = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sandbox()
        
    
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        let camera = SCNCamera()
        camera.focalLength = 50
        camera.usesOrthographicProjection = false
        camera.automaticallyAdjustsZRange = true
        cameraNode.camera = camera
        
        scene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        
        
        let imageMaterial = SCNMaterial()
        imageMaterial.isDoubleSided = false
        imageMaterial.diffuse.contents = UIImage(named: "texture.png")
        imageMaterial.isDoubleSided = true
          
        
        let light = SCNLight()
        light.type = .directional
        light.doubleSided = true
       // light.intensity = 0.8
        
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, 10, 0)
        lightNode.eulerAngles = SCNVector3(Float.pi / -3.0,  Float.pi / 8.0 , 0)
        scene.rootNode.addChildNode(lightNode)
        
        let routeGeo = RouteGeometry(points: [vector_float3([0, 0, 0]), vector_float3([0, 0, -1]), vector_float3([0.5, 0, -2]), vector_float3([0, 0, -4])], width: 0.35, height: 0.05)
        routeNode = SCNNode(geometry: routeGeo.geometry)
        routeNode.localTranslate(by: SCNVector3(x: 0, y: 0, z: -0.5))
        routeNode.geometry?.materials = [imageMaterial]
        scene.rootNode.addChildNode(routeNode)
        
        let box = SCNNode(geometry: SCNBox(width: 0.25, height: 0.25, length: 0.25, chamferRadius: 0.025))
        box.localTranslate(by: SCNVector3(x: 0, y:  -0, z: -0.5))
        box.geometry?.materials = [imageMaterial]
        //scene.rootNode.addChildNode(box)
    
       // scene.rootNode.addChildNode(SCNNode(geometry: geometry))
        // Set the scene to the view
        sceneView.scene = scene
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = .vertical

        sceneView.delegate = self
        sceneView.session.delegate = self

        print(sceneView.preferredFramesPerSecond)
        sceneView.preferredFramesPerSecond = 60
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor.isKind(of: ARPlaneAnchor.self) {
            let planeAnchor = anchor as! ARPlaneAnchor
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let inner = SCNNode(geometry: plane)
            inner.eulerAngles = SCNVector3(-Float.pi / 2.0 , 0, 0)
            let node = SCNNode()
            node.addChildNode(inner)
            return node
        }
        
        return nil
    }

    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        glLineWidth(10)
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
}



extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("Frame")
        
        let trx = frame.camera.transform
        print(trx)
          
        CVPixelBufferLockBaseAddress(frame.capturedImage, CVPixelBufferLockFlags(rawValue: 0));

        let address = CVPixelBufferGetBaseAddress(frame.capturedImage);
        let width: Int = CVPixelBufferGetWidth(frame.capturedImage);
        let height: Int = CVPixelBufferGetHeight(frame.capturedImage);
        let bytesPerPixel: Int = CVPixelBufferGetBytesPerRow(frame.capturedImage) / width
        
        OpenCVAdaptor.updateFrame(address, width: width, height: height, bytesPerPixel: bytesPerPixel)
      
        CVPixelBufferUnlockBaseAddress(frame.capturedImage, CVPixelBufferLockFlags(rawValue: 0));
        
        cameraNode.position = SCNVector3()
    }

}


extension ViewController {
    func sandbox() {
        
        let a1 = Angle(degrees: 365.0)
        let a2 = Angle(degrees: 5.0)
        let a3 = a2 - a1
        print(a3.degrees)
        
    }
}
