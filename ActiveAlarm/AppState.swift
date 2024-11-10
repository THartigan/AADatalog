//
//  AppState.swift
//  ActiveAlarm
//
//  Created by Thomas Hartigan on 01/07/2024.
//

import Foundation

class AppState: ObservableObject {
    @Published var recordingState: Bool = false
    @Published var showRecordingView: Bool = false
    var currentRecordingUUIDString: String = ""
    var movieIsSaved = false
    var movieURL: URL?
    
    func startNewRecording() {
        movieIsSaved = false
        movieURL = nil
    }
}
