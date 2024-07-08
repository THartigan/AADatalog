//
//  Heart.swift
//  ActiveAlarm Watch App
//
//  Created by Thomas Hartigan on 08/06/2024.
//

import Foundation
import HealthKit

class Health: ObservableObject {
    var healthStore: HKHealthStore
    let allTypes: Set = [
        HKQuantityType(.heartRate)
    ]
    @Published var lastHeartRate: Int = 0
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            print("healthstore created successfully")
        } else{
            fatalError("Health kit data must be available and is not")
        }
    }
    
    func authenticateHealth() async {
        do {
            if HKHealthStore.isHealthDataAvailable() {
                try await self.healthStore.requestAuthorization(toShare: [], read: self.allTypes)
            }
        } catch {
            fatalError("Error getting healthkit permissions")
        }
    }
    
    func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) -> HKAnchoredObjectQuery {
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            self.process(samples, type: quantityTypeIdentifier)
            
        }
        
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        
        
        healthStore.execute(query)
        return query
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
            // variable initialization
            var lastHeartRate = 0.0
            
            // cycle and value assignment
            for sample in samples {
                if type == .heartRate {
                    lastHeartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                }
                
                DispatchQueue.global(qos: .background).async {
                    DispatchQueue.main.async {
                        self.lastHeartRate = Int(lastHeartRate)
                    }
                }
            }
        }
    
    func stopHeartRateQuery(query: HKAnchoredObjectQuery) {
        healthStore.stop(query)
    }
}
