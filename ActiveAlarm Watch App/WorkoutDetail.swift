//
//  WorkoutDetail.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 07/06/2024.
//

import SwiftUI
import CoreMotion
import HealthKitUI

struct WorkoutDetail: View {
    var workout: String
    var phoneConnector: PhoneConnector
    @StateObject var motion = Motion()
    @StateObject var health = Health()
    @State private var trigger = false
    @State private var authenticated = false
    @State var healthQuery: HKAnchoredObjectQuery?
    @State var times: [Date] = []
    @State var heartRates: [Int] = []
    @State var motionDatas: [MotionData] = []
    
    var body: some View {
        VStack{
            Text(workout)
            if let motionData = motion.currentMotionData {
                Text("P: \(String(format: "%.2f", motionData.pitch)), R: \(String(format: "%.2f", motionData.roll)), Y: \(String(format: "%.2f", motionData.yaw))")
                Text("A: (\(String(format: "%.2f", motionData.acceleration.x)), \(String(format: "%.2f", motionData.acceleration.y)), \(String(format: "%.2f", motionData.acceleration.z)))")
                if self.authenticated {
                    Text("HR: \(health.lastHeartRate)")
                }
            }
            
            
        }
        .onDisappear{
            self.motion.stopDeviceMotion()
            if let query = self.healthQuery {
                self.health.stopHeartRateQuery(query: query)
            }
            var workoutDatas: [WorkoutData] = []
            for (i, time) in times.enumerated() {
                workoutDatas.append(WorkoutData(time: time, heartRate: self.heartRates[i], motion: self.motionDatas[i], workoutType: self.workout))
            }
            let finalDatas = WorkoutDatas(workoutDatas: workoutDatas)
            self.sendAsJSON(workoutDatas: finalDatas)
//            phoneConnector.sendDataToPhone(finalDatas)
            self.phoneConnector.sendPhoneRecordingState(enabled: false)
        }
        .healthDataAccessRequest(store: health.healthStore, readTypes: health.allTypes, trigger: trigger, completion: { result in
            switch result {
                
            case .success(_):
                self.authenticated = true
            case .failure(_):
                fatalError("Error whilst getting healthkit authentication")
            }
                
        })
        .onAppear(perform: {
            trigger.toggle()
            self.healthQuery = health.startHeartRateQuery(quantityTypeIdentifier: .heartRate)
            self.phoneConnector.sendPhoneRecordingState(enabled: true)
        })
        .onChange(of: motion.currentMotionData, { oldValue, newValue in
            if let motionData = motion.currentMotionData{
                if self.authenticated {
                    self.times.append(Date.now)
                    self.heartRates.append(health.lastHeartRate)
                    self.motionDatas.append(motionData)
                }
            }
        })
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func sendAsJSON(workoutDatas: WorkoutDatas) {
        do {
            let jsonData = try JSONEncoder().encode(workoutDatas)
//            let jsonString = String(data: jsonData, encoding: .utf8)
            
            let fileURL = getDocumentsDirectory().appendingPathComponent("WorkoutDatas.json")
            
            try jsonData.write(to: fileURL)
            
            print("JSON data was saved to \(fileURL.path)")
            self.phoneConnector.sendDataToPhone(fileURL)
        } catch {
            print("Error \(error)")
        }
    }

}

//#Preview {
//    WorkoutDetail(workout: "Run")
//}
