//
//  SitupsModelProcessing.swift
//  ActiveAlarm
//
//  Created by Thomas Hartigan on 23/09/2024.
//

import Foundation
import CoreML
import SwiftUI
import WatchKit

class ModelProcessing: ObservableObject {
    let modelName: String
    let modelExtension: String
    var model: MLModel?
    @Published var outputs: [Double] = [0,0]
    @Published var numOutputs: Int = 0
    @Published var totalSitups: Int = 0
    
    init(modelName: String = "Situps4", modelExtension: String = "mlmodelc", model: MLModel? = nil) {
        self.modelName = modelName
        self.modelExtension = modelExtension
        self.model = model
        self.importModel()
    }
    
    func importModel() {
        guard let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: self.modelExtension) else {
            fatalError("Model file not found.")
        }

        do {
            // Compile the model at runtime
            self.model = try MLModel(contentsOf: modelURL)
        } catch {
            fatalError("Failed to load the model: \(error)")
        }
    }
    
    func process(times: [Date], motionDatas: [MotionData]) {
        
        guard let inputArray = try? MLMultiArray(shape: [1, 9, 200], dataType: .float32) else {
            fatalError("Failed to create MLMultiArray.")
        }
//        print(inputArray[3800])
        
        // Ensure the list is not empty
        guard let firstDate = times.first else {
            fatalError("The dates list is empty.")
        }
        let timeDifferencesInSeconds: [TimeInterval] = times.map { $0.timeIntervalSince(firstDate) }
        
        for (index, value) in timeDifferencesInSeconds.enumerated() {
            inputArray[index] = NSNumber(value:value)
        }
        
        for (motionIndex, motionData) in motionDatas.enumerated() {
//            inputArray[motionIndex + 200] = NSNumber(value: motionData.yaw)
            inputArray[motionIndex + 200] = NSNumber(value: motionData.pitch)
            inputArray[motionIndex + 400] = NSNumber(value: motionData.roll)
            inputArray[motionIndex + 600] = NSNumber(value: motionData.gravity.x)
            inputArray[motionIndex + 800] = NSNumber(value: motionData.gravity.y)
            inputArray[motionIndex + 1000] = NSNumber(value: motionData.gravity.z)
            inputArray[motionIndex + 1200] = NSNumber(value: motionData.acceleration.x)
            inputArray[motionIndex + 1400] = NSNumber(value: motionData.acceleration.y)
            inputArray[motionIndex + 1600] = NSNumber(value: motionData.acceleration.z)
//            inputArray[motionIndex + 2000] = NSNumber(value: motionData.rotationMatrix.m11)
//            inputArray[motionIndex + 2200] = NSNumber(value: motionData.rotationMatrix.m12)
//            inputArray[motionIndex + 2400] = NSNumber(value: motionData.rotationMatrix.m13)
//            inputArray[motionIndex + 2600] = NSNumber(value: motionData.rotationMatrix.m21)
//            inputArray[motionIndex + 2800] = NSNumber(value: motionData.rotationMatrix.m22)
//            inputArray[motionIndex + 3000] = NSNumber(value: motionData.rotationMatrix.m23)
//            inputArray[motionIndex + 3200] = NSNumber(value: motionData.rotationMatrix.m31)
//            inputArray[motionIndex + 3400] = NSNumber(value: motionData.rotationMatrix.m32)
//            inputArray[motionIndex + 3600] = NSNumber(value: motionData.rotationMatrix.m33)
        }
        
        // Create a dictionary with the input feature name and value
        let inputDict: [String: Any] = ["x_1": inputArray]
        
        // Create a feature provider
        guard let inputProvider = try? MLDictionaryFeatureProvider(dictionary: inputDict) else {
            print("Failed to create input provider.")
            return
        }
        
        // Make a prediction
        do {
            let output = try self.model?.prediction(from: inputProvider)
            
            if let outputFeature = output?.featureValue(for: "var_66") {
                if let multiArrayValue = outputFeature.multiArrayValue {
                    print(multiArrayValue)
                    self.outputs = [multiArrayValue[0].doubleValue, multiArrayValue[1].doubleValue]
                    self.numOutputs = self.numOutputs + 1
                    if multiArrayValue[1].doubleValue > multiArrayValue[0].doubleValue {
                        let device = WKInterfaceDevice.current()
                        device.play(.success)
                        self.totalSitups = self.totalSitups + 1
                    }
                }
                
//                if let outputString = outputFeature.stringValue {
//                    print("Prediction Result: \(outputString)")
//                    // Update UI or handle the prediction result
//                } else if let outputArray = outputFeature.multiArrayValue {
//                    print("Output MLMultiArray: \(outputArray)")
//                    // Handle MLMultiArray output
//                }
            } else {
                print("Output feature 'output_label' not found.")
            }
        } catch {
            print("Prediction error: \(error)")
        }
    }
    
    
    
}


