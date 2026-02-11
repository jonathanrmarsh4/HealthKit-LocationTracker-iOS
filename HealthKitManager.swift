import HealthKit

class HealthKitManager {
    
    let healthStore = HKHealthStore()
    
    // Define data types to request
    var typesToRead: Set<HKObjectType> {
        return [
            // Activity
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            
            // Heart
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodOxygen)!,
            
            // Sleep
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            
            // Workouts
            HKWorkoutType.workoutType()
        ]
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("✅ HealthKit authorization granted")
                completion(true)
            } else {
                print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    
    func fetchTodayData(completion: @escaping ([String: Any]) -> Void) {
        var healthData: [String: Any] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: today, end: Date(), options: .strictStartDate)
        
        let dispatchGroup = DispatchGroup()
        
        // Fetch Steps
        dispatchGroup.enter()
        fetchQuantity(.stepCount, predicate: predicate) { value in
            healthData["steps"] = value
            dispatchGroup.leave()
        }
        
        // Fetch Heart Rate
        dispatchGroup.enter()
        fetchQuantity(.heartRate, predicate: predicate) { value in
            healthData["heart_rate"] = value
            dispatchGroup.leave()
        }
        
        // Fetch Resting Heart Rate
        dispatchGroup.enter()
        fetchQuantity(.restingHeartRate, predicate: predicate) { value in
            healthData["resting_heart_rate"] = value
            dispatchGroup.leave()
        }
        
        // Fetch HRV
        dispatchGroup.enter()
        fetchQuantity(.heartRateVariabilitySDNN, predicate: predicate) { value in
            healthData["hrv"] = value
            dispatchGroup.leave()
        }
        
        // Fetch Blood Pressure
        dispatchGroup.enter()
        fetchQuantity(.bloodPressureSystolic, predicate: predicate) { value in
            healthData["blood_pressure_systolic"] = value
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchQuantity(.bloodPressureDiastolic, predicate: predicate) { value in
            healthData["blood_pressure_diastolic"] = value
            dispatchGroup.leave()
        }
        
        // Fetch Blood Oxygen
        dispatchGroup.enter()
        fetchQuantity(.bloodOxygen, predicate: predicate) { value in
            healthData["blood_oxygen"] = value
            dispatchGroup.leave()
        }
        
        // Fetch Active Energy
        dispatchGroup.enter()
        fetchQuantity(.activeEnergyBurned, predicate: predicate) { value in
            healthData["active_energy"] = value
            dispatchGroup.leave()
        }
        
        // Fetch Distance
        dispatchGroup.enter()
        fetchQuantity(.distanceWalkingRunning, predicate: predicate) { value in
            healthData["distance"] = value
            dispatchGroup.leave()
        }
        
        // Fetch Flights Climbed
        dispatchGroup.enter()
        fetchQuantity(.flightsClimbed, predicate: predicate) { value in
            healthData["flights_climbed"] = value
            dispatchGroup.leave()
        }
        
        // Fetch Sleep
        dispatchGroup.enter()
        fetchSleep(predicate: predicate) { sleepData in
            healthData["sleep"] = sleepData
            dispatchGroup.leave()
        }
        
        // Fetch Workouts
        dispatchGroup.enter()
        fetchWorkouts(predicate: predicate) { workouts in
            healthData["workouts"] = workouts
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            healthData["timestamp"] = ISO8601DateFormatter().string(from: Date())
            completion(healthData)
        }
    }
    
    private func fetchQuantity(_ identifier: HKQuantityTypeIdentifier, predicate: NSPredicate, completion: @escaping (Double?) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.count())
            completion(sum)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchSleep(predicate: NSPredicate, completion: @escaping ([String: Any]) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([:])
            return
        }
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            var sleepData: [String: Any] = [:]
            
            if let samples = samples as? [HKCategorySample] {
                let totalMinutes = samples.reduce(0) { total, sample in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    return total + duration / 60
                }
                sleepData["total_minutes"] = totalMinutes
                sleepData["samples_count"] = samples.count
            }
            
            completion(sleepData)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWorkouts(predicate: NSPredicate, completion: @escaping ([[String: Any]]) -> Void) {
        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            var workoutData: [[String: Any]] = []
            
            if let samples = samples as? [HKWorkout] {
                for workout in samples {
                    let workoutDict: [String: Any] = [
                        "type": workout.workoutActivityType.rawValue,
                        "duration_minutes": workout.duration / 60,
                        "calories": workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0,
                        "distance": workout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0
                    ]
                    workoutData.append(workoutDict)
                }
            }
            
            completion(workoutData)
        }
        
        healthStore.execute(query)
    }
}
