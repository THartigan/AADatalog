//
//  WorkoutDetail.swift
//  ActiveAlarm
//
//  Created by Thomas Hartigan on 10/06/2024.
//

import SwiftUI
import SwiftData

struct WorkoutDetail: View {
    @State private var showDocumentPicker = false
    
    var workoutDatas: WorkoutDatas
    var body: some View {
        VStack{
            Button("Export Data") {
                showDocumentPicker = true
            }
            List{
                VStack{
                    ForEach(workoutDatas.workoutDatas) { workoutData in
                        HStack {
                            Text(workoutData.time.formatted())
                            Text(String(workoutData.heartRate))
                            Text(String(workoutData.motion.acceleration.abs))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker, onDismiss: {
            showDocumentPicker = false
        }) {
            DocumentPicker(fileURLs: [workoutDatas.createJSON()])
        }
        
    }
}

//#Preview {
//    WorkoutDetail()
//}
