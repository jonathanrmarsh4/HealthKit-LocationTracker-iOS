import Foundation
import HealthKit

class HealthKitManager: NSObject, ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var healthData: HealthDataPoint = HealthDataPoint(timestamp: Date())
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    private let queue = DispatchQueue(label: "com.healthkit.manager")
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestHealthKitAuthorization() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var typesToRead = Set<HKSampleType>()

            // Add quantity types
            let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
                .stepCount, .heartRate, .restingHeartRate, .heartRateVariabilitySDNN,
                .bloodPressureSystolic, .bloodPressureDiastolic, .oxygenSaturation,
                .activeEnergyBurned, .distanceWalkingRunning, .flightsClimbed
            ]

            for identifier in quantityIdentifiers {
                if let type = HKQuantityType.quantityType(forIdentifier: identifier) {
                    typesToRead.insert(type)
                }
            }

            // Add workout type
            typesToRead.insert(HKWorkoutType.workoutType())

            // Add sleep analysis
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                typesToRead.insert(sleepType)
            }

            // Note: Activity summaries don't need explicit authorization

            healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead) { success, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
                        print("❌ HealthKit auth failed: \(error)")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.checkAuthorization()
                        print("✅ HealthKit authorization requested")
                    }
                }
                continuation.resume()
            }
        }
    }
    
    private func checkAuthorization() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let status = healthStore.authorizationStatus(for: stepCountType)
        DispatchQueue.main.async {
            self.isAuthorized = status == .sharingAuthorized
        }
    }
    
    // MARK: - Fetch Health Data

    func fetchHealthData() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                var dataPoint = HealthDataPoint(timestamp: Date())

                // Use DispatchGroup to wait for all fetches to complete
                let group = DispatchGroup()

                // Fetch each metric
                group.enter()
                self.fetchSteps { steps in
                    dataPoint.steps = steps
                    group.leave()
                }

                group.enter()
                self.fetchHeartRate { hr in
                    dataPoint.heartRate = hr
                    group.leave()
                }

                group.enter()
                self.fetchRestingHeartRate { rhr in
                    dataPoint.restingHeartRate = rhr
                    group.leave()
                }

                group.enter()
                self.fetchHeartRateVariability { hrv in
                    dataPoint.heartRateVariability = hrv
                    group.leave()
                }

                group.enter()
                self.fetchBloodPressure { systolic, diastolic in
                    dataPoint.bloodPressureSystolic = systolic
                    dataPoint.bloodPressureDiastolic = diastolic
                    group.leave()
                }

                group.enter()
                self.fetchBloodOxygen { bo2 in
                    dataPoint.bloodOxygen = bo2
                    group.leave()
                }

                group.enter()
                self.fetchActiveEnergy { energy in
                    dataPoint.activeEnergy = energy
                    group.leave()
                }

                group.enter()
                self.fetchDistance { distance in
                    dataPoint.distance = distance
                    group.leave()
                }

                group.enter()
                self.fetchFlightsClimbed { flights in
                    dataPoint.flightsClimbed = flights
                    group.leave()
                }

                group.enter()
                self.fetchSleepData { duration in
                    dataPoint.sleepDuration = duration
                    group.leave()
                }

                // Wait for all fetches to complete before updating
                group.notify(queue: DispatchQueue.main) {
                    self.healthData = dataPoint
                    print("✅ Health data fetched: steps=\(dataPoint.steps ?? 0), HR=\(dataPoint.heartRate ?? 0)")
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Individual Metric Fetchers
    
    private func fetchSteps(completion: @escaping (Int?) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil)
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard error == nil, let result = result, let sum = result.sumQuantity() else {
                completion(nil)
                return
            }
            completion(Int(sum.doubleValue(for: HKUnit.count())))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRate(completion: @escaping (Int?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .minute, value: -10, to: Date()), end: Date())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            completion(Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min"))))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRestingHeartRate(completion: @escaping (Int?) -> Void) {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            completion(nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()), end: Date())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: restingHRType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            completion(Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min"))))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRateVariability(completion: @escaping (Double?) -> Void) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()), end: Date())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            completion(sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBloodPressure(completion: @escaping (Int?, Int?) -> Void) {
        guard let bpSystolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic) else {
            completion(nil, nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()), end: Date())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: bpSystolic, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                completion(nil, nil)
                return
            }
            let systolic = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
            completion(systolic, nil)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBloodOxygen(completion: @escaping (Double?) -> Void) {
        guard let o2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion(nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()), end: Date())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: o2Type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            completion(sample.quantity.doubleValue(for: HKUnit.percent()) * 100)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveEnergy(completion: @escaping (Double?) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil)
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard error == nil, let result = result, let sum = result.sumQuantity() else {
                completion(nil)
                return
            }
            completion(sum.doubleValue(for: HKUnit.kilocalorie()))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchDistance(completion: @escaping (Double?) -> Void) {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(nil)
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard error == nil, let result = result, let sum = result.sumQuantity() else {
                completion(nil)
                return
            }
            completion(sum.doubleValue(for: HKUnit.meter()) / 1000) // Convert to km
        }
        
        healthStore.execute(query)
    }
    
    private func fetchFlightsClimbed(completion: @escaping (Int?) -> Void) {
        guard let flightType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else {
            completion(nil)
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        
        let query = HKStatisticsQuery(quantityType: flightType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard error == nil, let result = result, let sum = result.sumQuantity() else {
                completion(nil)
                return
            }
            completion(Int(sum.doubleValue(for: HKUnit.count())))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchSleepData(completion: @escaping (TimeInterval?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: Date())!)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard error == nil, let samples = samples else {
                completion(nil)
                return
            }
            
            let totalDuration = samples.reduce(0) { total, sample in
                total + (sample.endDate.timeIntervalSince(sample.startDate))
            }
            completion(totalDuration)
        }
        
        healthStore.execute(query)
    }
}
