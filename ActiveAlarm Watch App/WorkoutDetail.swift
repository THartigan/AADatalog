//
//  WorkoutDetail.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 07/06/2024.
//

import SwiftUI
import CoreMotion
import HealthKitUI
import CoreML

struct WorkoutDetail: View {
    var workout: String
    var phoneConnector: PhoneConnector
    @StateObject var modelProcessing = ModelProcessing()
    @State var frame = 0
    @StateObject var motion = Motion()
    @StateObject var health = Health()
    @State private var trigger = false
    @State private var authenticated = false
    @State var healthQuery: HKAnchoredObjectQuery?
    @State var times: [Date] = []
    @State var heartRates: [Int] = []
    @State var motionDatas: [MotionData] = []
    @State var currentUUID: UUID = UUID()
    
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
            Text("\(String(modelProcessing.numOutputs)) 0: \(String(format: "%.2f", modelProcessing.outputs[0])) 1: \(String(format: "%.2f", modelProcessing.outputs[1]))")
            Text("Counted: \(String(modelProcessing.totalSitups))")
            
            
        }
        .onDisappear{
            self.motion.stopDeviceMotion()
            if let query = self.healthQuery {
                self.health.stopHeartRateQuery(query: query)
            }
            var workoutDatas: [WorkoutData] = []
            for (i, time) in times.enumerated() {
                workoutDatas.append(WorkoutData(time: time.timeIntervalSince1970, heartRate: self.heartRates[i], motion: self.motionDatas[i], workoutType: self.workout))
            }
            let finalDatas = WorkoutDatas(workoutDatas: workoutDatas, id: currentUUID)
            self.sendAsJSON(workoutDatas: finalDatas)
//            phoneConnector.sendDataToPhone(finalDatas)
            self.phoneConnector.sendPhoneRecordingState(enabled: false, currentRecordingUUID: currentUUID, workoutType: workout, startTime: Date.now)
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
            currentUUID = UUID()
            trigger.toggle()
            self.healthQuery = health.startHeartRateQuery(quantityTypeIdentifier: .heartRate)
            self.phoneConnector.sendPhoneRecordingState(enabled: true, currentRecordingUUID: currentUUID, workoutType: workout, startTime: Date.now)
            
        })
        .onChange(of: motion.currentMotionData, { oldValue, newValue in
            if let motionData = motion.currentMotionData{
                if self.authenticated {
                    self.times.append(Date.now)
                    self.heartRates.append(health.lastHeartRate)
                    self.motionDatas.append(motionData)
                    if self.frame >= 200 && self.frame % 200 == 0 {
                        self.modelProcessing.process(times: self.times.suffix(200), motionDatas: self.motionDatas.suffix(200))
                    }
                    
                    self.frame += 1
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
