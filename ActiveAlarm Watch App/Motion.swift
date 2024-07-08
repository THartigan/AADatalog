//
//  Motion.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 08/06/2024.
//

import Foundation
import CoreMotion
import Combine

class Motion: ObservableObject {
    private var motionManager: CMMotionManager
    private var sampleFrequency: Double
    private var samplePeriod: Double
    private var queue: OperationQueue
    @Published var currentMotionData: MotionData?
    private var cancellables = Set<AnyCancellable>()
    
    init(sampleFrequency: Double = 60) {
            
        self.motionManager = CMMotionManager()
        self.queue = OperationQueue()
        self.sampleFrequency = sampleFrequency
        self.samplePeriod = 1.0 / sampleFrequency
        self.startDeviceMotion()
    }
    
    func startDeviceMotion() {
        if motionManager.isDeviceMotionAvailable {
            self.motionManager.deviceMotionUpdateInterval = self.samplePeriod
            self.motionManager.showsDeviceMovementDisplay = true
            self.motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main, withHandler: { (data, error) in
                if let validData = data {
                    let roll = validData.attitude.roll
                    let pitch = validData.attitude.pitch
                    let yaw = validData.attitude.yaw
                    let acceleration = validData.userAcceleration
                    DispatchQueue.global(qos: .background).async {
                        DispatchQueue.main.async {
                            self.currentMotionData = MotionData(pitch: pitch, roll: roll, yaw: yaw, acceleration: Acceleration(x: acceleration.x, y: acceleration.y, z: acceleration.z))
                        }
                    }
                    
//                    print(acceleration.x)
                    // Use motion data
                    
                }
            })
        }
    }
    
    func stopDeviceMotion() {
        if motionManager.isDeviceMotionActive{
            self.motionManager.stopDeviceMotionUpdates()
        }
    }
}
