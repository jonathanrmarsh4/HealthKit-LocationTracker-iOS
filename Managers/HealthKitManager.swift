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
        // Check authorization status first
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("❌ Cannot create HealthKit types")
            return
        }

        let authStatus = healthStore.authorizationStatus(for: stepCountType)
        print("🔐 HealthKit authorization status: \(authStatus.rawValue) (1=unknown, 2=denied, 3=authorized)")

        if authStatus == .sharingDenied {
            print("❌ HealthKit access denied - please grant permissions in Settings")
            return
        }

        // Check if running on simulator and provide mock data
        let isSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil

        if isSimulator {
            print("📱 Simulator detected - using mock health data")
            let mockData = HealthDataPoint(
                timestamp: Date(),
                steps: Int.random(in: 5000...15000),
                heartRate: Int.random(in: 60...100),
                restingHeartRate: Int.random(in: 50...70),
                heartRateVariability: Double.random(in: 20...80),
                bloodPressureSystolic: Int.random(in: 110...130),
                bloodPressureDiastolic: Int.random(in: 70...85),
                bloodOxygen: Double.random(in: 95...100),
                activeEnergy: Double.random(in: 200...600),
                distance: Double.random(in: 3...12),
                flightsClimbed: Int.random(in: 5...20),
                sleepDuration: Double.random(in: 6*3600...9*3600),
                workoutDuration: nil,
                workoutType: nil,
                workoutCalories: nil
            )

            await MainActor.run {
                self.healthData = mockData
            }
            print("✅ Mock health data: steps=\(mockData.steps ?? 0), HR=\(mockData.heartRate ?? 0), distance=\(mockData.distance ?? 0)km")
            return
        }

        print("📊 Starting HealthKit data fetch...")

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            // Create a mutable reference wrapper to avoid struct copy issues in closures
            class DataPointWrapper {
                var dataPoint: HealthDataPoint
                init(timestamp: Date) {
                    self.dataPoint = HealthDataPoint(timestamp: timestamp)
                }
            }

            let wrapper = DataPointWrapper(timestamp: Date())
            let group = DispatchGroup()

            // Fetch each metric
            group.enter()
            self.fetchSteps { steps in
                wrapper.dataPoint.steps = steps
                group.leave()
            }

            group.enter()
            self.fetchHeartRate { hr in
                wrapper.dataPoint.heartRate = hr
                group.leave()
            }

            group.enter()
            self.fetchRestingHeartRate { rhr in
                wrapper.dataPoint.restingHeartRate = rhr
                group.leave()
            }

            group.enter()
            self.fetchHeartRateVariability { hrv in
                wrapper.dataPoint.heartRateVariability = hrv
                group.leave()
            }

            group.enter()
            self.fetchBloodPressure { systolic, diastolic in
                wrapper.dataPoint.bloodPressureSystolic = systolic
                wrapper.dataPoint.bloodPressureDiastolic = diastolic
                group.leave()
            }

            group.enter()
            self.fetchBloodOxygen { bo2 in
                wrapper.dataPoint.bloodOxygen = bo2
                group.leave()
            }

            group.enter()
            self.fetchActiveEnergy { energy in
                wrapper.dataPoint.activeEnergy = energy
                group.leave()
            }

            group.enter()
            self.fetchDistance { distance in
                wrapper.dataPoint.distance = distance
                group.leave()
            }

            group.enter()
            self.fetchFlightsClimbed { flights in
                wrapper.dataPoint.flightsClimbed = flights
                group.leave()
            }

            group.enter()
            self.fetchSleepData { duration in
                wrapper.dataPoint.sleepDuration = duration
                group.leave()
            }

            // Wait for all fetches to complete before updating
            group.notify(queue: DispatchQueue.main) {
                let finalData = wrapper.dataPoint
                self.healthData = finalData
                print("✅ Health data fetched: steps=\(finalData.steps ?? 0), HR=\(finalData.heartRate ?? 0), distance=\(finalData.distance ?? 0)km")
                continuation.resume()
            }
        }
    }
    
    // MARK: - Individual Metric Fetchers
    
    private func fetchSteps(completion: @escaping (Int?) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("❌ Failed to create step count type")
            completion(nil)
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print("❌ Steps query error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let result = result, let sum = result.sumQuantity() else {
                print("⚠️ No step data available")
                completion(nil)
                return
            }
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            print("✅ Steps fetched: \(steps)")
            completion(steps)
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
