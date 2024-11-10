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
    @Query(sort: \WorkoutDataOverseer.startTime, order: .reverse) var workoutDataOverseers: [WorkoutDataOverseer]
    @State private var selectedUUIDs = Set<UUID>()
    @State private var editMode: EditMode = .inactive
//    @Environment(\.editMode) var editMode
    @State private var showDocumentPicker = false
    @State private var showDeleteAlert = false
    @State private var continueDelete = false
    @StateObject private var appState = AppState()
    @State private var showDocumentsExplorer = false
    @State private var showRecordingView = false
    @State private var triggerUpdate = false
    var watchConnector : WatchConnector
    var cameraViewModel = CameraViewModel()
    
    var body: some View {
//        let workoutDatass = watchConnector.workoutDatass
        NavigationStack{
            VStack{
                Text(String(appState.recordingState))
                Button(action: {showDocumentsExplorer = true}, label: {
                    Text("Show Documents")
                })
                Text("Select The Log to Access")
                List(workoutDataOverseers, selection: $selectedUUIDs) { workoutDataOverseer in
                    if workoutDataOverseer.isUsable {
                        NavigationLink {
                            WorkoutDetail(workoutDataOverseer: workoutDataOverseer)
    //                        WorkoutDetail(workoutDatas: workoutDatas)
                        } label: {
                            HStack {
                                Text(workoutDataOverseer.workoutType)
                                Text(workoutDataOverseer.startTimeString)
                            }
    //                        HStack{
    //                            if !workoutDatass.isEmpty {
    //                                HStack{
    //                                    Text(workoutDatas.workoutType)
    //                                    //fix
    //                                    if workoutDatas.workoutDatas.count != 0 {
    //                                        let timeString = timeFormatter.string(from: workoutDatas.workoutDatas[0].time)
    //                                        Text(timeString)
    //                                    }
    //                                }
    //                            }
    //                        }
                        }
                    }
                    
                    
                }
                
                
                
                .sheet(isPresented: $showDocumentPicker, onDismiss: {
                    showDocumentPicker = false
                    editMode = .inactive
                }) {
                    let selectedOverseers = getObjectsFromID(objects: workoutDataOverseers, ids: selectedUUIDs)
                    let allowedOverssers = getAllowedOverseers(selectedOverseers)
                    let allowedOverseerMetadataURLs = allowedOverssers.map{ $0.metadataURL }
                    let allowedJSONURLs = allowedOverssers.map{ $0.jsonURL }
                    let allowedMovieURLs = allowedOverssers.map{ $0.movieURL }
                    let allowedTimestampURLs = allowedOverssers.map { $0.timestampURL }
                    let allowedURLs = allowedOverseerMetadataURLs + allowedJSONURLs + allowedMovieURLs + allowedTimestampURLs
                    DocumentPicker(fileURLs: allowedURLs)
                }
//                .sheet(isPresented: $appState.recordingState, onDismiss: {
//                    cameraViewModel.stopRecording()
////                    appState.recordingState = false
//                }) {
//                    RecordingView(cameraViewModel: cameraViewModel)
//                }
                .sheet(isPresented: $showDocumentsExplorer, onDismiss: {
                    showDocumentsExplorer = false
                }) {
                    FileBrowserView()
                }
                .onChange(of: appState.recordingState) {
                    if appState.recordingState == true {
                        cameraViewModel.startRecording { success in
                            if success {
                                print("Recoring started successfully")
                            }
                        }
                        showRecordingView = true
                    } else {
                        print("Stopping recording due to appState.recordingState change")
                        cameraViewModel.stopRecording()
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            showRecordingView = false
                            triggerUpdate.toggle()
                        }
                        
                    }
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
                        for workoutDataOverseer in workoutDataOverseers {
                            context.delete(workoutDataOverseer)
                        }
                    })
                )
            }
            .environment(\.editMode, $editMode)
            .navigationDestination(isPresented: $showRecordingView) {
                RecordingView(cameraViewModel: cameraViewModel)
            }
//            .navigationBarTitle("Items")
//            RecordingView(cameraViewModel: cameraViewModel), isActive: $showRecordingView) {EmptyView()}
        }
        
        
        .onAppear(perform: {
            watchConnector.context = context
            watchConnector.appState = appState
            cameraViewModel.appState = appState
        })
    }
    func getAllowedOverseers(_ overseers: [WorkoutDataOverseer]) -> [WorkoutDataOverseer] {
        var exportableOverseers: [WorkoutDataOverseer] = []
        for overseer in overseers {
            if overseer.isExportable {
                exportableOverseers.append(overseer)
            }
        }
        return exportableOverseers
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

