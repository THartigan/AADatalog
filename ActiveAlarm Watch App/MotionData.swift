//
//  MotionData.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 08/06/2024.
//

import Foundation

struct MotionData: Equatable, Codable {
    var pitch: Double
    var roll: Double
    var yaw: Double
    var acceleration: Acceleration
}

struct Acceleration: Equatable, Codable {
    var x: Double
    var y: Double
    var z: Double
}
