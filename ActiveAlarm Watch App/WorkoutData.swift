//
//  WorkoutData.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 10/06/2024.
//

import Foundation

struct WorkoutData: Codable, Identifiable {
    public var id = UUID()
    var time: Date
    var heartRate: Int
    var motion: MotionData
    var workoutType: String
    
//    func encodeIt() -> Data {
//        let data = try! PropertyListEncoder.init().encode(self)
//        return data
//    }
//    
//    static func decodeit(_ data: Data) -> WorkoutData {
//        let workoutData = try! PropertyListDecoder.init().decode(WorkoutData.self, from: data)
//        return workoutData
//    }
}

//struct WorkoutDatas: Codable, Identifiable {
//    public var id = UUID()
//    var workoutDatas:[WorkoutData]
//    var workoutType: String {
//        if !workoutDatas.isEmpty {
//            return workoutDatas[0].workoutType
//        } else {
//            return "No Workout Type"
//        }
//    }
//    
//    func encodeIt() -> Data {
//        let data = try! PropertyListEncoder.init().encode(self)
//        return data
//    }
//    
//    static func decodeit(_ data: Data) -> WorkoutDatas {
//        let workoutDatas = try! PropertyListDecoder.init().decode(WorkoutDatas.self, from: data)
//        return workoutDatas
//    }
//}

class WorkoutDatas: Codable, Identifiable {
    enum CodingKeys: CodingKey {
        case id, workoutDatas, workoutType, creationTime
    }
    public var id: UUID = UUID()
    var workoutDatas: [WorkoutData]
    var workoutType: String
    var creationTime: Date
    
    init(workoutDatas: [WorkoutData]) {
        self.workoutDatas = workoutDatas
        if !workoutDatas.isEmpty {
            self.workoutType = workoutDatas[0].workoutType
            self.creationTime = workoutDatas[0].time
        } else {
            self.workoutType = "No Workout Type"
            self.creationTime = Date(timeIntervalSince1970: 0)
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        workoutDatas = try container.decode([WorkoutData].self, forKey: .workoutDatas)
        workoutType = try container.decode(String.self, forKey: .workoutType)
        creationTime = try container.decode(Date.self, forKey: .creationTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(workoutDatas, forKey: .workoutDatas)
        try container.encode(workoutType, forKey: .workoutType)
        try container.encode(creationTime, forKey: .creationTime)
    }
    
    func encodeIt() -> Data {
        let data = try! PropertyListEncoder.init().encode(self)
        return data
    }
    
    static func decodeIt(_ data: Data) -> WorkoutDatas {
        let workoutDatas = try! PropertyListDecoder.init().decode(WorkoutDatas.self, from: data)
        return workoutDatas
    }
}
