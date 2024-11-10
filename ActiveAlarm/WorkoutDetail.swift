//
//  WorkoutDetail.swift
//  ActiveAlarm
//
//  Created by Thomas Hartigan on 10/06/2024.
//

import SwiftUI
import SwiftData
import AVKit

struct WorkoutDetail: View {
    @State private var showDocumentPicker = false
    @StateObject private var viewModel: VideoPlayerViewModel
    @State private var groundLeaveTimes: [Double] = []
    @State private var airLeaveTimes: [Double] = []
    @State private var startTime: Double = 0
    @State private var endTime: Double = 0
    private var videoStartTimeSeconds: Double = 0
    @State private var label = ""
    
    var workoutDataOverseer: WorkoutDataOverseer
    
    init(workoutDataOverseer: WorkoutDataOverseer) {
        _viewModel = StateObject(wrappedValue: VideoPlayerViewModel(url: workoutDataOverseer.movieURL))
        self.workoutDataOverseer = workoutDataOverseer
    
        if let videoStartTimeSeconds = getFileCreationTimeInterval(fileURL: workoutDataOverseer.movieURL) {
            self.videoStartTimeSeconds = videoStartTimeSeconds
        }
    }
    
    var body: some View {
        VStack{
            Button("Export Data") {
                showDocumentPicker = true
            }
            
            VideoPlayer(player: viewModel.player)
                .onAppear {
                    viewModel.player.play()
                }
                .onDisappear {
                    viewModel.player.pause()
                }
                .aspectRatio(contentMode: .fit)

            Text("Current Time: \(viewModel.currentTime.seconds, specifier: "%.2f") seconds")
                .padding()
            HStack{
                Button("Start") {
                    startTime = viewModel.currentTime.seconds
                }
                Button("End") {
                    endTime = viewModel.currentTime.seconds
                }
            }
            HStack{
                Button("Leaving Ground") {
                    groundLeaveTimes.append(viewModel.currentTime.seconds)
                }
                Button("Leaving Air") {
                    airLeaveTimes.append(viewModel.currentTime.seconds)
                }
            }
            Button("Write Timestamps"){
                writeTimestamps()
            }
            Text("Start time: \(videoStartTimeSeconds)")
            let changeTimes = ([startTime] + groundLeaveTimes + airLeaveTimes + [endTime]).sorted()
            List{
                ForEach(changeTimes, id: \.self) { changeTime in
                    if groundLeaveTimes.contains(changeTime) {
                        HStack {
                            Text("Ground left")
                            Spacer()
                            Text(String(changeTime))
                        }
                    } else if airLeaveTimes.contains(changeTime){
                        HStack {
                            Text("Air left")
                            Spacer()
                            Text(String(changeTime))
                        }
                    } else if startTime == changeTime{
                        HStack {
                            Text("Start")
                            Spacer()
                            Text(String(changeTime))
                        }
                    } else if endTime == changeTime {
                        HStack {
                            Text("End")
                            Spacer()
                            Text(String(changeTime))
                        }
                    }
                }
                .onDelete(perform: { indexSet in
                    for index in indexSet {
                        let changeTime = changeTimes[index]
                        if let groundLeaveIndex = groundLeaveTimes.firstIndex(of: changeTime) {
                            groundLeaveTimes.remove(at: groundLeaveIndex)
                        }
                        if let airLeaveIndex = airLeaveTimes.firstIndex(of: changeTime) {
                            airLeaveTimes.remove(at: airLeaveIndex)
                        }
                    }
                })
            }
            
//            ForEach(changeTimes) {changeTime in changeTimes {
                
                
//            }
        }
        .sheet(isPresented: $showDocumentPicker, onDismiss: {
            showDocumentPicker = false
        }) {
            let fileURLs = [workoutDataOverseer.jsonURL, workoutDataOverseer.movieURL]
            DocumentPicker(fileURLs: fileURLs)
        }
        
    }
    
    func getFileCreationTimeInterval(fileURL: URL) -> TimeInterval? {
        do {
            let resourcesValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
            if let creationDate = resourcesValues.creationDate {
                return creationDate.timeIntervalSince1970
            }
        } catch {
            print("Error retrieving file attributes: \(error.localizedDescription)")
        }
        return nil
    }
    
    func writeTimestamps() {
        guard startTime != 0 && endTime != 0 else {
            print("Start or end time was zero, so no action taken")
            return
        }
        
        if let recordingStartTime = workoutDataOverseer.recordingStartTime {
            let timestamps = Timestamps(startTime: startTime + recordingStartTime.timeIntervalSince1970,
                                        endTime: endTime + recordingStartTime.timeIntervalSince1970,
                                        groundLeaveTimes: groundLeaveTimes.map{ $0  + recordingStartTime.timeIntervalSince1970},
                                        airLeaveTimes: airLeaveTimes.map{ $0  + recordingStartTime.timeIntervalSince1970})
            let encoder = JSONEncoder()
            let filename = "Timestamps_" + workoutDataOverseer.movieURL.deletingPathExtension().lastPathComponent + ".json"
            
            do {
                let jsonData = try encoder.encode(timestamps)
                let fileManager = FileManager.default
                
                if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileURL = documentDirectory.appendingPathComponent(filename)
                    
                    try jsonData.write(to: fileURL)
                    print("File saved: \(fileURL.absoluteURL)")
                } else {
                    print("Could not find the document directory.")
                }
            } catch {
                print("Error encoding or writing JSON: \(error)")
            }
        } else {
            fatalError("Timestamp writing failed because recordingStartTime was nil")
        }
        
        
    }

}

struct Timestamps: Codable {
    var startTime: Double
    var endTime: Double
    var groundLeaveTimes: [Double]
    var airLeaveTimes: [Double]
}

class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer
    @Published var currentTime: CMTime = .zero
    
    private var timeObserverToken: Any?
    
    init(url: URL) {
        self.player = AVPlayer(url: url)
        addPeriodicTimeObserver()
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main){ [weak self] time in
            self?.currentTime = time
        }
    }
    
    deinit {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
}

//struct VideoPlayerView: View {
//    @StateObject private var viewModel: VideoPlayerViewModel
//
//    init(url: URL) {
//        _viewModel = StateObject(wrappedValue: VideoPlayerViewModel(url: url))
//    }
//
//    var body: some View {
//        VStack {
//            
//        }
//    }
//}

//#Preview {
//    WorkoutDetail()
//}
