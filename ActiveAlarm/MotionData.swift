//
//  MotionData.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 08/06/2024.
//

import Foundation
import CoreMotion

struct MotionData: Equatable, Codable {
    var pitch: Double
    var roll: Double
    var yaw: Double
    var acceleration: Vector
    var gravity: Vector
    var magneticField: Vector
    var rotationMatrix: RotationMatrix
}

struct Vector: Equatable, Codable {
    var x: Double
    var y: Double
    var z: Double
    var abs: Double {
        return sqrt(pow(x,2) + pow(y,2) + pow(z,2))
    }
}

struct RotationMatrix: Equatable, Codable {
    // typical i increasing down the rows and j along the columns
    var m11: Double
    var m12: Double
    var m13: Double
    var m21: Double
    var m22: Double
    var m23: Double
    var m31: Double
    var m32: Double
    var m33: Double
}
