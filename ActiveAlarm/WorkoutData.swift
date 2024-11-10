//
//  WorkoutData.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 10/06/2024.
//

import Foundation
import SwiftData

struct WorkoutData: Codable, Identifiable {
    public var id = UUID()
    var time: Double
    var heartRate: Int
    var motion: MotionData
    var workoutType: String
}

struct WorkoutDatas: Codable, Identifiable {
//    enum CodingKeys: CodingKey {
//        case id, workoutDatas, workoutType, creationTime
//    }
    public var id: UUID = UUID()
    var workoutDatas: [WorkoutData]
    var workoutType: String
    var creationTime: Date
    
//    init(workoutDatas: [WorkoutData]) {
//        self.workoutDatas = workoutDatas
//        if !workoutDatas.isEmpty {
//            self.workoutType = workoutDatas[0].workoutType
//            self.creationTime = workoutDatas[0].time
//        } else {
//            self.workoutType = "No Workout Type"
//            self.creationTime = Date(timeIntervalSince1970: 0)
//        }
//    }
    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        id = try container.decode(UUID.self, forKey: .id)
//        workoutDatas = try container.decode([WorkoutData].self, forKey: .workoutDatas)
//        workoutType = try container.decode(String.self, forKey: .workoutType)
//        creationTime = try container.decode(Date.self, forKey: .creationTime)
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(workoutDatas, forKey: .workoutDatas)
//        try container.encode(workoutType, forKey: .workoutType)
//        try container.encode(creationTime, forKey: .creationTime)
//    }
//    
//    func encodeIt() -> Data {
//        let data = try! PropertyListEncoder.init().encode(self)
//        return data
//    }
//    
//    static func decodeIt(_ data: Data) -> WorkoutDatas {
//        let workoutDatas = try! PropertyListDecoder.init().decode(WorkoutDatas.self, from: data)
//        return workoutDatas
//    }
//    
//    
//    func createJSON() -> URL {
//        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let currentTimeInSeconds = Int(Date().timeIntervalSince1970)
//        let fileName = "_\(currentTimeInSeconds).json"
//        do {
//            let jsonData = try JSONEncoder().encode(self)
////            let jsonString = String(data: jsonData, encoding: .utf8)
//            
//            let fileURL = documentsDirectory.appendingPathComponent(fileName)
//            
//            try jsonData.write(to: fileURL)
//            
//            print("JSON data was saved to \(fileURL.path)")
//            return fileURL
//        } catch {
//            print("Error \(error)")
//            fatalError()
//        }
//    }
}

@Model
class WorkoutDataOverseer {
    public var id: UUID
    var workoutType: String
    var startTime: Date
    var recordingStartTime: Date?
    var isUsable: Bool {
        let jsonExists = FileManager.default.fileExists(atPath: jsonURL.path)
        let movieExists = FileManager.default.fileExists(atPath: movieURL.path)
        if jsonExists && movieExists {
            return true
        } else {
            return false
        }
    }
    var isExportable: Bool {
        let jsonExists = FileManager.default.fileExists(atPath: jsonURL.path)
        let movieExists = FileManager.default.fileExists(atPath: movieURL.path)
        let timestampsExist = FileManager.default.fileExists(atPath: timestampURL.path)
        if jsonExists && movieExists && timestampsExist {
            return true
        } else {
            return false
        }
    }
    var uUIDString: String {
        return id.uuidString
    }
    var metadataURL: URL {
        let metadataDict = ["recordingStartTime": recordingStartTime]
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(metadataDict)
            let fileName = "\("Metadata_" + uUIDString).json"
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsURL.appendingPathComponent(fileName)

            do {
                // Copy the file to the local directory
                try jsonData.write(to: destinationURL)
                print("File saved locally at \(destinationURL)")
                return destinationURL
            } catch {
                print("Error saving file locally: \(error)")
                fatalError("Failed to save metadata JSON file")
            }
        } catch {
            print("Error encoding json for metadata \(error.localizedDescription)")
            fatalError("Failed to encode metadata JSON file")
        }
        
        
        
        
    }
    
    var jsonURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(uUIDString).json"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return fileURL
    }
    var movieURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(uUIDString).mov"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return fileURL
    }
    var timestampURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "Timestamps_\(uUIDString).json"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return fileURL
    }
    var startTimeString: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss dd/MM/yy "
        let timeString = timeFormatter.string(from: startTime)
        return timeString
    }
    
    init(id: UUID, workoutType: String, startTime: Date) {
        self.id = id
        self.workoutType = workoutType
        self.startTime = startTime
    }
}

