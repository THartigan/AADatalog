import AVFoundation
import Photos
import SwiftUI
import SwiftData

struct RecordingView: View {
    @Query(sort: \WorkoutDataOverseer.startTime, order: .reverse) var workoutDataOverseers: [WorkoutDataOverseer]
    @StateObject var cameraViewModel: CameraViewModel
    @State var isRecording = false
    

    var body: some View {
        ZStack {
            CameraPreview(cameraViewModel: cameraViewModel)
                .edgesIgnoringSafeArea(.all)

            VStack {

                Spacer()

                HStack {
                    if isRecording {
                        Button("Stop recording") {
                            cameraViewModel.stopRecording()
                            isRecording = false
                                
                            
                        }
                        Text("Recording")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    } else {
                        Button("Start recording") {
                            cameraViewModel.startRecording { success in
                                if success {
                                    isRecording = true
                                }
                            }
                        }
                        Text("Not recording")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .onAppear(perform: {
                
                let secondsToDelay = 2.0
                print("Before")
                DispatchQueue.main.asyncAfter(deadline: .now() + secondsToDelay) {
                    // remove existing table before adding new one
                    print("Delayed")
                    cameraViewModel.startRecording { success in
                        if success {
                            isRecording = true
                            // This is the point at which to save the time
                            let recordingStartTime = Date.now
                            workoutDataOverseers[0].recordingStartTime = recordingStartTime
                        }
                    }
                }
                
            })
        }
        
    }
}

class CameraViewModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    let captureSession = AVCaptureSession()
    var videoOutput: AVCaptureMovieFileOutput?
    @Published private(set) var isRecording = false
    var videoDataOutput: AVCaptureVideoDataOutput?
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    private var startRecordingTime = Date.now
    var appState: AppState?

    override init() {
        super.init()
        requestCameraPermission()
    }

    
    func setupAssetWriter(url: URL) {
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: .mov)
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1920,
                AVVideoHeightKey: 1080
            ]
            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            assetWriterInput?.expectsMediaDataInRealTime = true

            if assetWriter!.canAdd(assetWriterInput!) {
                assetWriter!.add(assetWriterInput!)
            }
        } catch {
            print("Error setting up video writer: \(error)")
        }
    }


    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.setupCamera()
                }
            } else {
                print("Camera access denied")
            }
        }
    }
    
    func saveVideoToPhotos(url: URL) {
//        guard FileManager.default.fileExists(atPath: url.path) else {
//            print("File does not exist at path: \(url.path), cannot save to Photos.")
//            return
//        }
//
//        PHPhotoLibrary.requestAuthorization { status in
//            if status == .authorized {
//                PHPhotoLibrary.shared().performChanges({
//                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
//                }) { saved, error in
//                    if saved {
//                        print("Video saved to Photos")
//                    } else {
//                        print("Could not save video to Photos: \(String(describing: error))")
//                    }
//                }
//            } else {
//                print("Photos permission not granted")
//            }
//        }
    }
    
    func saveFileToDocumentsDirectory(sourceURL: URL, fileName: String) {
        let fileManager = FileManager.default

        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let destinationURL = documentsURL.appendingPathComponent(fileName).appendingPathExtension("mov")

            // Copy the file to the documents directory
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("File saved to documents directory at \(destinationURL)")
            if let appState = appState {
                appState.movieIsSaved = true
                appState.movieURL = destinationURL
            }
        } catch {
            print("Error saving file: \(error)")
        }
        
    }

    

    func setupCamera() {
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("No video device available")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Cannot add video input")
                return
            }

            let videoOutput = AVCaptureMovieFileOutput()
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                self.videoOutput = videoOutput
            } else {
                print("Cannot add video output")
                return
            }

            // Move the startRunning call to a background thread
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    print("Camera setup and session started")
                }
            }
        } catch {
            print("Failed to set up camera: \(error)")
        }
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoDataOutput!) {
            captureSession.addOutput(videoDataOutput!)
        }

        
    }

    func startRecording(completion: @escaping (Bool) -> Void) {
        guard let videoOutput = videoOutput, !isRecording else {
            print("Recording is already in progress or output is not available. recording: \(isRecording)")
            completion(false)
            return
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")

        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true
        completion(true)
    }



    func stopRecording() {
        print("B")
        guard isRecording, let videoOutput = videoOutput else { return }
        print("C")
        videoOutput.stopRecording()
        isRecording = false
    }
}



extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()

        // Perform your drawing here
        let overlayImage = drawOverlay(on: ciImage)

        // Create a new sample buffer with the modified image
        if let cgImage = context.createCGImage(overlayImage, from: overlayImage.extent) {
            // Here you would typically write this image to a video file
        }
    }

    func drawOverlay(on image: CIImage) -> CIImage {
        let overlay = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        return image.composited(over: overlay)
    }
    
    
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            print("D")
            isRecording = false
            if let error = error {
                print("Recording failed with error: \(error.localizedDescription)")
                return
            }
    
            // Check if the file exists
            if FileManager.default.fileExists(atPath: outputFileURL.path) {
                print("File exists at path: \(outputFileURL.path), ready to be saved or used.")
                // Optionally, save to Photos, change this bit
                if let appState = appState {
                    saveFileToDocumentsDirectory(sourceURL: outputFileURL, fileName: appState.currentRecordingUUIDString)
                }
                
            } else {
                print("File does not exist at path: \(outputFileURL.path)")
            }
        }

}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraViewModel: CameraViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraViewModel.captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update UI View if needed
    }
}
