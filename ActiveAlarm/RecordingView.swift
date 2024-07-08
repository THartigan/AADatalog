//
//  RecordingView.swift
//  ActiveAlarm
//
//  Created by Thomas Hartigan on 01/07/2024.
//

import SwiftUI
import AVFoundation



struct RecordingView: View {
    @StateObject var cameraModel = CameraModel()
    
    var body: some View {
        ZStack {
            CameraPreview(camera: cameraModel)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        cameraModel.takePhoto()
                    }) {
                        Image(systemName: "circle")
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            cameraModel.checkPermissions()
            cameraModel.setupCamera()
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCamera()
                }
            }
        default:
            // Handle cases where permission is denied
            break
        }
    }
    
    func setupCamera() {
        DispatchQueue.global(qos: .background).async {
            self.session.beginConfiguration()
            
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
                
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }
                
                self.session.commitConfiguration()
                
                self.session.startRunning()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = UIImage(data: imageData)
        // Save or use the captured photo as needed
    }
}

struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    var camera: CameraModel
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = camera.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}
