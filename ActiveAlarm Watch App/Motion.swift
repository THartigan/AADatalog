//
//  Motion.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 08/06/2024.
//

import Foundation
import CoreMotion
import Combine
import WatchKit

class Motion: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: (any Error)?) {
        print("Extended runtime session invalidated")
//        startDeviceMotion()
    }
    

    
    private var runtimeSession: WKExtendedRuntimeSession?
    
    private var motionManager: CMMotionManager
    private var sampleFrequency: Double
    private var samplePeriod: Double
    private var queue: OperationQueue
    @Published var currentMotionData: MotionData?
    private var cancellables = Set<AnyCancellable>()
    
    init(sampleFrequency: Double = 100) {
        
        self.motionManager = CMMotionManager()
        
        self.queue = OperationQueue()
        self.sampleFrequency = sampleFrequency
        self.samplePeriod = 1.0 / sampleFrequency
        super.init()
        self.startDeviceMotion()
    }
    
    func startDeviceMotion() {
        startExtendedRuntimeSession()
        if motionManager.isDeviceMotionAvailable {
            self.motionManager.deviceMotionUpdateInterval = self.samplePeriod
            self.motionManager.showsDeviceMovementDisplay = true
            self.motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main, withHandler: { (data, error) in
                if let validData = data {
                    let roll = validData.attitude.roll
                    let pitch = validData.attitude.pitch
                    let yaw = validData.attitude.yaw
                    let acceleration = validData.userAcceleration
                    let gravity = validData.gravity
                    let magneticField = validData.magneticField
                    let rotationMatrix = validData.attitude.rotationMatrix
                    DispatchQueue.global(qos: .background).async {
                        DispatchQueue.main.async {
                            self.currentMotionData = MotionData(pitch: pitch, roll: roll, yaw: yaw, acceleration: Vector(x: acceleration.x, y: acceleration.y, z: acceleration.z), gravity: Vector(x: gravity.x, y: gravity.y, z: gravity.z), magneticField: Vector(x: magneticField.field.x, y: magneticField.field.y, z: magneticField.field.z), rotationMatrix: RotationMatrix(m11: rotationMatrix.m11, m12: rotationMatrix.m12, m13: rotationMatrix.m13, m21: rotationMatrix.m21, m22: rotationMatrix.m22, m23: rotationMatrix.m23, m31: rotationMatrix.m31, m32: rotationMatrix.m32, m33: rotationMatrix.m33))
                        }
                    }
                    // Pitch is 3D polar angle from z to x-y plane (rotation clockwise around x-axis) -2pi -> 2pi
                    // Roll is the rotation around the y-axis (clockwise) -2pi -> 2pi
                    // Yaw is the rotation around the z-axis -pi -> pi
                    
//                    print(acceleration.x)
                    // Use motion data
                    
                }
            })
        }
        
    }
    
    func stopDeviceMotion() {
        if motionManager.isDeviceMotionActive{
            self.motionManager.stopDeviceMotionUpdates()
            print("Stopped motion updates. MAKE SURE THIS RUNS")
        }
        runtimeSession?.invalidate()
    }
    
    private func startExtendedRuntimeSession() {
        runtimeSession = WKExtendedRuntimeSession()
        runtimeSession?.delegate = self
        runtimeSession?.start(at: Date())
    }
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session started")
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session will expire soon")
    }
    
    func extendedRuntimeSessionDidInvalidate(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session invalidated")
//        startDeviceMotion()
    }
}
