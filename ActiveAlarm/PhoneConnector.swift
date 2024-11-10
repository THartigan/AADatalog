//
//  PhoneConnector.swift
//  ActiveAlarm
//
//  Created by Thomas Hartigan on 10/06/2024.
//

import Foundation
import WatchConnectivity

class PhoneConnector: NSObject {
    static let shared = PhoneConnector()
    
    public let session = WCSession.default
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
}

extension PhoneConnector: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
    }
    
//    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
//        dataReceivedFromPhone(userInfo)
//    }
    
}

// MARK: - send data to phone
extension PhoneConnector {
    
    public func sendDataToPhone(_ workoutDataURL: URL) {
//        let dict:[String:Any] = ["data":workoutData.encodeIt()]
        
//        session.transferUserInfo(dict)
        session.transferFile(workoutDataURL, metadata: nil)
        print("data sent")
        // for testing in simulator we use
//        session.sendMessage(dict, replyHandler: nil)
    }
    
    public func sendPhoneRecordingState(enabled state: Bool, currentRecordingUUID: UUID, workoutType: String, startTime: Date) {
        print("Attempting to send message")
        session.sendMessage(["recordingState": state, 
                             "currentRecordingUUIDString": currentRecordingUUID.uuidString,
                             "workoutType": workoutType,
                             "startTime": startTime], replyHandler: nil, errorHandler: { error in
            print("Error sending message: \(error.localizedDescription)")
        })
    }
}

//// MARK: - receive data
//extension PhoneConnector {
//    
//    public func dataReceivedFromPhone(_ info:[String:Any]) {
//        let data:Data = info["data"] as! Data
//        let user = User.decodeIt(data)
//        DispatchQueue.main.async {
//            self.users.append(user)
//        }
//    }
//}
