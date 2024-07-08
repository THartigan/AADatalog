//
//  ContentView.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 07/06/2024.
//

import SwiftUI

enum Exercise: String, CaseIterable, Identifiable {
    case Pressup, Situp, Run, Jump_Jacks
    var id: String {return self.rawValue}
}

struct ContentView: View {
//    @State private var Exercises = Exercise
//    var workoutData
    var phoneConnector = PhoneConnector()
    
    
    var body: some View {
        NavigationStack{
            VStack {
                Text("Select Workout")
                List {
                    ForEach(Exercise.allCases) { item in
                        NavigationLink {
                            WorkoutDetail(workout: item.rawValue, phoneConnector: self.phoneConnector)
                        } label: {
                            Text(item.rawValue)
                        }
                        
                        
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
