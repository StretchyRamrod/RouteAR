//
//  GraphicsViewController.swift
//  RouteTest
//
//  Created by Omer Katzir on 05/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import SceneKit
import CoreLocation
import CoreMotion

class GraphicsViewController: UIViewController {
    
    private weak var sceneView: ARSCNView!
    @IBOutlet weak var imageView: UIImageView!
    
    private var scene: SCNScene = SCNScene()
    private var cameraNode: SCNNode! = SCNNode()
    private var worldNode: SCNNode! = SCNNode()
    private var widgetsNode: SCNNode! = SCNNode()
    private var widget: SCNNode!
    private var material: SCNMaterial!
    
    private var offsetTrx: matrix_float4x4 = matrix_float4x4(diagonal: [1, 1, 1, 1])
    private var transform: matrix_float4x4 = matrix_float4x4(diagonal: [1, 1, 1, 1])

    var gisRoute: [CLocation]! = []
   
    private var arEngine: ARKitEngine! = ARKitEngine()
    private var positionEngine: ARPositionEngine!
    
    @IBOutlet var segmentationView: DrawingSegmentationView?
    var mlModule: MLModule?
    
    var opencvOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GISToLocalConverter.shared.origin = gisRoute.first!
            
        sceneView = (self.view as! ARSCNView)
          
        material = createMaterial()
        offsetTrx.columns.3[1] = 0.5
        
        scene.rootNode.addChildNode(createLightNode())
        
        cameraNode = createCameraNode()
        scene.rootNode.addChildNode(cameraNode)
        
        cameraNode.position = SCNVector3(0, 0.5, 0)
        
        scene.rootNode.addChildNode(worldNode)
        scene.rootNode.addChildNode(widgetsNode)
        widgetsNode.localTranslate(by: SCNVector3(0, -0.1, 1))

        let routeNode = setGISRouteNode(route: gisRoute, centerCoord: gisRoute.first!)
        routeNode.geometry?.materials = [material]
        routeNode.localTranslate(by: SCNVector3(0, -0.5, 0))
        worldNode.addChildNode(routeNode)
        
        let finishGeo = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1)
        let finishMat = SCNMaterial()
        finishMat.isDoubleSided = false
        finishMat.diffuse.contents = UIImage(named: "checkered.png")
        finishGeo.materials = [finishMat]
        let finishNode = SCNNode(geometry: finishGeo)
        
        finishNode.transform = SCNMatrix4(float4x4.init(rotMat: float3x3.identity, translation: GISToLocalConverter.shared.convert(gisRoute.last!)))
        
        worldNode.addChildNode(finishNode)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        positionEngine = ARPositionEngine(gisRoute: gisRoute)
        
        sceneView.scene = scene
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = UIColor(white: 0, alpha: 0)
        
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
        
  
       // sceneView.pointOfView = cameraNode
    }
    
    func setGISRouteNode(route: [CLocation], centerCoord: CLocation) -> SCNNode {
        
        let geo = RouteGeometry(points: GISToLocalConverter.shared.convert(route), width: 1.5, height: 0.5).geometry
        let node = SCNNode(geometry: geo)
        node.name = "Route"
        
        let prevNode = scene.rootNode.childNode(withName: "Route", recursively: true)
        if prevNode != nil {
            scene.rootNode.replaceChildNode(prevNode!, with: node)
        } else {
            scene.rootNode.addChildNode(node)
        }
        
        return node
    }
        

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


private extension GraphicsViewController {
    
    func createCameraNode() -> SCNNode {
        let camera = SCNCamera()
        
        //camera.focalLength = 50
        camera.fieldOfView = 37
        camera.usesOrthographicProjection = false
        camera.automaticallyAdjustsZRange = true
        
        let node = SCNNode()
        node.camera = camera
        return node
    
    }
    
    func createMaterial() -> SCNMaterial {
        let imageMaterial = SCNMaterial()
        imageMaterial.isDoubleSided = false
        imageMaterial.diffuse.contents = UIImage(named: "Arrow.png")
        //imageMaterial.diffuse.contents = UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0)
        imageMaterial.isDoubleSided = true
        imageMaterial.shininess = 0.8
        imageMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(1.0, 0.3, 0)
        imageMaterial.diffuse.wrapS = .repeat
        imageMaterial.diffuse.wrapT = .repeat
        
        return imageMaterial
    }
    
    func createLightNode() -> SCNNode {
        let light = SCNLight()
        light.type = .directional
        light.doubleSided = true
        //light.intensity = 0.8

        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, -10, 0)
        lightNode.eulerAngles = SCNVector3(Float.pi / -2.0,  0 * Float.pi / 8.0 , 0)
        scene.rootNode.addChildNode(lightNode)
        
        return lightNode
    }
}


extension GraphicsViewController: ARSCNViewDelegate {
    
}


extension GraphicsViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if opencvOn {
            OpenCVAdaptor.updateARFrame(frame.capturedImage)
            let image = OpenCVAdaptor.getFrame()
            imageView.image = image //UIImage(cgImage: cgImage!)
        }
        //mlModule?.predict(with: frame.capturedImage)

        let offset = positionEngine.updateFrame(frame)
        material.setValue(positionEngine.speed, forKey: "speed")
        session.setWorldOrigin(relativeTransform: offset)
                
       // widget.transform = SCNMatrix4(positionEngine.transform)
       // sceneView.pointOfView!.transform = SCNMatrix4(positionEngine.transform)
          
    }

}
//    let ciImage = CIImage(cvImageBuffer: frame.capturedImage)
//   let context = CIContext(options: nil)
//  let cgImage = context.createCGImage(ciImage, from: ciImage.extent)


extension GraphicsViewController {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch(camera.trackingState) {
            case(.normal):
                positionEngine.run()
                break
            case(.notAvailable):
                positionEngine.stop()
                break
            default:
                break
            }
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



extension GraphicsViewController {
    
    @IBAction func onOpenCVOn(sender: UIButton) {
        opencvOn = !opencvOn
        imageView.isHidden = !opencvOn
        sender.setTitle(opencvOn ? "X" : "OpenCV", for: .normal)
    }
    
    @IBAction func onStrictRouteMatch(sender: UIButton) {
        positionEngine!.strictRouteMatch = !positionEngine.strictRouteMatch
        sender.setTitle(positionEngine.strictRouteMatch ? "Strict" : "Loose", for: .normal)
    }
    
    @IBAction func onAzimByMinLine(sender: UIButton) {
        positionEngine!.azimByMinLine = !positionEngine.azimByMinLine
        sender.setTitle(positionEngine.azimByMinLine ? "MinLine" : "Normal", for: .normal)
    }
}
