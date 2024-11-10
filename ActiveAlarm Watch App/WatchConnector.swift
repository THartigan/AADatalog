//
//  WatchConnector.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 10/06/2024.
//

import Foundation
import WatchConnectivity
import SwiftData

class WatchConnector: NSObject, ObservableObject {
    static let shared = WatchConnector()
    public let session = WCSession.default
    var context: ModelContext?
    var appState: AppState?
//    @Published var workoutDatass: [WorkoutDatas] = []
//    let configuration = ModelConfiguration(isStoredInMemoryOnly: false, allowsSave: true)
//    var container: ModelContainer?
    
    
    override init() {
//        do {
//            self.container = try ModelContainer(
//                for: WorkoutDatas.self,
//                configurations: configuration
//            )
//        } catch {
//            print("Error generating swiftData container \(error.localizedDescription)")
//        }
        
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        

        
        
    }
}

extension WatchConnector: WCSessionDelegate {
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        session.activate()
    }
    
    func sessionDidDeactivate(_ session: WCSession){
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
    }
    
//    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
//        dataReceivedFromWatch(userInfo)
//    }
    
    func session(_ session: WCSession, didReceive workoutDataJSON: WCSessionFile) {
        self.fileReceivedFromWatch(workoutDataJSON)
    }
    
    func session(_ session: WCSession, didFinish: WCSessionFileTransfer, error: Error?) {
        if let error = error {
            print("File transfer error \(error.localizedDescription)")
        } else {
            print("File transfer completed")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Message received")
        print(message)
        if message.keys.contains("recordingState") {
            if let _appState = appState,
               let recordingState = message["recordingState"] as? Bool,
               let uuidString = message["currentRecordingUUIDString"] as? String,
               let workoutType = message["workoutType"] as? String,
               let startTime = message["startTime"] as? Date {
                if let uuid = UUID(uuidString: uuidString) {
                    DispatchQueue.global(qos: .background).async {
                        DispatchQueue.main.async {
                            _appState.recordingState = recordingState
                            _appState.currentRecordingUUIDString = uuidString
                            
                        }
                    }
                    if recordingState == true {
                        DispatchQueue.main.async {
                            print("Attempting to insert new WorkoutDataOverseer into context")
                            let newWorkoutDataOverseer = WorkoutDataOverseer(id: uuid, workoutType: workoutType, startTime: startTime)
                            if self.context != nil {
                                self.context!.insert(newWorkoutDataOverseer)
                                print("WorkoutDataOverseer inserted into swiftData")
                            }
                        }
                    }
                }
                
            }
        } else {
            print("message did not contain expected recording state key")
        }
    }
    
}

//// MARK: - send data to watch
//extension WatchConnector {
//    
//    public func sendDataToWatch(_ user:User) {
//        let dict:[String:Any] = ["data":user.encodeIt()]
//        
//        //session.transferUserInfo(dict)
//        // for testing in simulator we use
//        session.sendMessage(dict, replyHandler: nil)
//    }
//}

// MARK: - receive data for files
extension WatchConnector {
    
//    public func dataReceivedFromWatch(_ info:[String:Any]) {
//        print("Data received")
//        let data:Data = info["data"] as! Data
//        let workoutDatas = WorkoutDatas.decodeIt(data)
//        DispatchQueue.main.async {
////            self.workoutDatass.append(workoutDatas)
////            self.users.append(user)
//        }
//    } 
    
    func fileReceivedFromWatch(_ workoutDataJSON: WCSessionFile) {
        do {
            let file = workoutDataJSON
            let jsonData = try Data(contentsOf: file.fileURL)
            saveJSONFile(jsonData: jsonData)
//            let workoutDatas = try JSONDecoder().decode(WorkoutDatas.self, from: jsonData)
//            print("Decoded received JSON")
//            DispatchQueue.main.async {
////                self.workoutDatass.append(workoutDatas)
//                print("Data received from \(file.fileURL)")
//                if self.context != nil {
//                    self.context!.insert(workoutDatas)
//                    print("Data inserted into swiftData")
//                    self.saveJSONFile(jsonData: jsonData)
//                }
////                if let context = self.context {
////
////                }
//
//    //            self.users.append(user)
//            }
        } catch {
            print("Failed to read or decode JSON file: \(error)")
        }
//        let data: Data = workoutDataJSON
//        let workoutDatas = WorkoutDatas.decodeIt(data)
        
    }
    
    func saveJSONFile(jsonData: Data) {
        // Define the file URL for the local directory
        let fileName = "\(appState?.currentRecordingUUIDString ?? "NO_UUIDString").json"
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsURL.appendingPathComponent(fileName)

        do {
            // Copy the file to the local directory
            try jsonData.write(to: destinationURL)
            print("File saved locally at \(destinationURL)")
        } catch {
            print("Error saving file locally: \(error)")
        }
    }
}

