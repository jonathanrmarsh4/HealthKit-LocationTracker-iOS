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
        let typesToRead: Set<HKSampleType> = [
            HKQuantityType.workoutType(),
            HKObjectType.activitySummaryType(),
            HKCategoryType.sleepAnalysis(),
            HKQuantityType(.stepCount),
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic),
            HKQuantityType(.oxygenSaturation),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.flightsClimbed)
        ].compactMap { $0 as? HKSampleType }
        
        do {
            try await healthStore.requestAuthorization(toShare: nil, read: typesToRead)
            DispatchQueue.main.async {
                self.checkAuthorization()
                print("✅ HealthKit authorization requested")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
                print("❌ HealthKit auth failed: \(error)")
            }
        }
    }
    
    private func checkAuthorization() {
        let stepCountType = HKQuantityType(.stepCount)
        let status = healthStore.authorizationStatus(for: stepCountType)
        DispatchQueue.main.async {
            self.isAuthorized = status == .sharingAuthorized
        }
    }
    
    // MARK: - Fetch Health Data
    
    func fetchHealthData() async {
        queue.async {
            var dataPoint = HealthDataPoint(timestamp: Date())
            
            // Fetch each metric
            self.fetchSteps { steps in
                dataPoint.steps = steps
            }
            
            self.fetchHeartRate { hr in
                dataPoint.heartRate = hr
            }
            
            self.fetchRestingHeartRate { rhr in
                dataPoint.restingHeartRate = rhr
            }
            
            self.fetchHeartRateVariability { hrv in
                dataPoint.heartRateVariability = hrv
            }
            
            self.fetchBloodPressure { systolic, diastolic in
                dataPoint.bloodPressureSystolic = systolic
                dataPoint.bloodPressureDiastolic = diastolic
            }
            
            self.fetchBloodOxygen { bo2 in
                dataPoint.bloodOxygen = bo2
            }
            
            self.fetchActiveEnergy { energy in
                dataPoint.activeEnergy = energy
            }
            
            self.fetchDistance { distance in
                dataPoint.distance = distance
            }
            
            self.fetchFlightsClimbed { flights in
                dataPoint.flightsClimbed = flights
            }
            
            self.fetchSleepData { duration in
                dataPoint.sleepDuration = duration
            }
            
            DispatchQueue.main.async {
                self.healthData = dataPoint
                print("✅ Health data fetched")
            }
        }
    }
    
    // MARK: - Individual Metric Fetchers
    
    private func fetchSteps(completion: @escaping (Int?) -> Void) {
        let stepType = HKQuantityType(.stepCount)
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
        let heartRateType = HKQuantityType(.heartRate)
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
        let restingHRType = HKQuantityType(.restingHeartRate)
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
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()), end: Date())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            completion(sample.quantity.doubleValue(for: HKUnit.millisecond()))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBloodPressure(completion: @escaping (Int?, Int?) -> Void) {
        let bpSystolic = HKQuantityType(.bloodPressureSystolic)
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
        let o2Type = HKQuantityType(.oxygenSaturation)
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
        let energyType = HKQuantityType(.activeEnergyBurned)
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
        let distanceType = HKQuantityType(.distanceWalkingRunning)
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
        let flightType = HKQuantityType(.flightsClimbed)
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
        let sleepType = HKCategoryType.sleepAnalysis()
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
