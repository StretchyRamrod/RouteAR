//
//  SensorsEngine.swift
//  RouteTest
//
//  Created by Omer Katzir on 01/12/2020.
//  Copyright © 2020 Omer Katzir. All rights reserved.
//

import UIKit
import CoreMotion

class SensorsEngine: NSObject{

    private var motionManager: CMMotionManager! = nil
    private var gyroBuffer: [CMGyroData] = []
    private var gyroQueueLock: NSLock! = NSLock()
   
    var lastTimestamp: TimeInterval? { get { return motionManager.deviceMotion?.timestamp }}
    var lastAccData: CMAcceleration? { get { return motionManager.deviceMotion?.gravity } }
    var lastMagData: CMCalibratedMagneticField? { get { return motionManager.deviceMotion?.magneticField}}
    
    func dumpGyroQueue() -> [CMGyroData] {
        
        gyroQueueLock.lock()
        let ret = gyroBuffer
        gyroBuffer = []
        
        gyroQueueLock.unlock()
        
        return ret
    }
    
    override init() {
        super.init()
        motionManager = CMMotionManager()
        motionManager.gyroUpdateInterval = 0.01
        motionManager.showsDeviceMovementDisplay = true
    }
    
    func run() {
        
        let queue = OperationQueue()
        
        motionManager.startGyroUpdates(to: queue, withHandler: onGyroUpdate)
        
        motionManager.startDeviceMotionUpdates()
        motionManager.startMagnetometerUpdates()
        motionManager.startAccelerometerUpdates()
        
    }
    
    
    private func onGyroUpdate(data: CMGyroData?, err: Error?) {
        if err != nil {
            print(err.debugDescription)
            return
        }
        
        gyroQueueLock.lock()
        
        gyroBuffer.append(data!)
        
        gyroQueueLock.unlock()
    }
    
}



