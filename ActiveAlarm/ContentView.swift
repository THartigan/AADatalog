//
//  ContentView.swift
//  ActiveAlarm
//
//  Created by Thomas Hartigan on 07/06/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutDatas.creationTime, order: .reverse) var workoutDatass: [WorkoutDatas]
    @State private var selectedUUIDs = Set<UUID>()
    @State private var editMode: EditMode = .inactive
//    @Environment(\.editMode) var editMode
    @State private var showDocumentPicker = false
    @State private var showDeleteAlert = false
    @State private var continueDelete = false
    @StateObject private var appState = AppState()
    var watchConnector : WatchConnector
    let timeFormatter = DateFormatter()
    
    var body: some View {
//        let workoutDatass = watchConnector.workoutDatass
        NavigationStack{
            VStack{
                Text(String(appState.recordingState))
                Text("Select The Log to Access")
                List(workoutDatass, selection: $selectedUUIDs) { workoutDatas in
                    NavigationLink {
                        WorkoutDetail(workoutDatas: workoutDatas)
                    } label: {
                        HStack{
                            if !workoutDatass.isEmpty {
                                HStack{
                                    Text(workoutDatas.workoutType)
                                    //fix
                                    if workoutDatas.workoutDatas.count != 0 {
                                        let timeString = timeFormatter.string(from: workoutDatas.workoutDatas[0].time)
                                        Text(timeString)
                                    }
                                }
                            }
                        }
                    }
                    
                }
                
                
                
                .sheet(isPresented: $showDocumentPicker, onDismiss: {
                    showDocumentPicker = false
                    editMode = .inactive
                }) {
                    let selectedDatas = getObjectsFromID(objects: workoutDatass, ids: selectedUUIDs)
                    let selectedURLs = selectedDatas.map{ $0.createJSON() }
                    DocumentPicker(fileURLs: selectedURLs)
                }
                .sheet(isPresented: $appState.recordingState, onDismiss: {
                    appState.recordingState = false
                }) {
                    RecordingView()
                }
            }
//            .padding()
            .navigationBarItems(
                leading: Button(action: {
                    withAnimation {
                        if editMode == .inactive {
                            editMode = .active
                        } else {
                            editMode = .inactive
                        }
                    }
                    
                }, label: {
                    if editMode == .inactive {
                        Text("Edit")
                    } else {
                        Text("Done")
                    }
                }),
                trailing: HStack {
                    if editMode == .active{
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete All")
                        }
                        .foregroundColor(.red)

                        Button {
                            showDocumentPicker = true
                        } label: {
                            Text("Export Selected")
                        }

                    }
                }
            )
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Warning"),
                    message: Text("Are you sure you want to continue to delete all entries?"),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text("Delete"), action: {
                        for workoutDatas in workoutDatass {
                            context.delete(workoutDatas)
                        }
                    })
                )
            }
            .environment(\.editMode, $editMode)
//            .navigationBarTitle("Items")
        }
        
        
        .onAppear(perform: {
            watchConnector.context = context
            watchConnector.appState = appState
            timeFormatter.dateFormat = "HH:mm:ss dd/MM/yy "
        })
    }
}

func getObjectsFromID<T: Identifiable>(objects: [T], ids: Set<UUID>) -> [T] where T.ID == UUID {
    // Create a dictionary from objects with UUID as keys
    let selectionDictionary = Dictionary(uniqueKeysWithValues: objects.map { ($0.id, $0) })
    
    // Initialize an array to store selected objects
    var selectedObjects: [T] = []
    
    // Loop through the IDs and select corresponding objects
    for selectedUUID in ids {
        if let selectedObject = selectionDictionary[selectedUUID] {
            selectedObjects.append(selectedObject)
        }
    }
    
    // Return the selected objects
    return selectedObjects
}
//#Preview {
//    ContentView()
//}

