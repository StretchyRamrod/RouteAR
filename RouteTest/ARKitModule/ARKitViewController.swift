//
//  ARKitViewController.swift
//  RouteTest
//
//  Created by Omer Katzir on 21/11/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import ARKit

class ARKitViewController: UIViewController {

    weak var imageView: UIImageView!
    
    private var session: ARSession!
    private var runOptions: ARSession.RunOptions!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView = self.view as? UIImageView

        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        config.isAutoFocusEnabled = false
        
        let runOptions = ARSession.RunOptions()
        
        session = ARSession()
        session.delegate = self
        session.run(config, options: runOptions)
        
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


extension ARKitViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("frame")
        
    }
}
