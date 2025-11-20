//
//  HealthKitManager.swift
//  aggregator
//
//  Created by Derek Trauger on 11/5/25.
//

import Foundation
import HealthKit
import SwiftData

@Observable
class HealthKitManager {
    private let healthStore = HKHealthStore()
    var isAuthorized = false
    var authorizationError: Error?
    var authorizationMessage: String?
    
    private let typesToRead: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
        HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
    ]
    
    init() {
        checkHealthDataAvailability()
        checkAccessByQuery()
    }
    
    private func checkHealthDataAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationMessage = "HealthKit is not available on this device"
            print("HealthKit is not available on this device")
            return
        }
    }
    
    private func checkAccessByQuery() {
        guard HKHealthStore.isHealthDataAvailable(),
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return
        }
        
        // Perform a quick query to see if we have access
        // HealthKit doesn't reliably report authorization status for privacy reasons,
        // so we attempt a query to determine if we have access
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if error == nil {
                    // Successfully queried, we have access
                    self?.isAuthorized = true
                    self?.authorizationMessage = "HealthKit access granted"
                } else {
                    // Query failed, likely no access
                    self?.isAuthorized = false
                    self?.authorizationMessage = "Please grant HealthKit permissions to view your health data"
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // Helper function to convert metadata dictionary to JSON string
    private func metadataToJSON(_ metadata: [String: Any]?) -> String? {
        guard let metadata = metadata, !metadata.isEmpty else { return nil }
        
        // Convert metadata to a serializable format
        var serializableMetadata: [String: Any] = [:]
        for (key, value) in metadata {
            // Convert various types to JSON-compatible types
            if let stringValue = value as? String {
                serializableMetadata[key] = stringValue
            } else if let numberValue = value as? NSNumber {
                serializableMetadata[key] = numberValue
            } else if let dateValue = value as? Date {
                serializableMetadata[key] = ISO8601DateFormatter().string(from: dateValue)
            } else if let boolValue = value as? Bool {
                serializableMetadata[key] = boolValue
            } else {
                // Convert other types to string representation
                serializableMetadata[key] = String(describing: value)
            }
        }
        
        // Convert to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: serializableMetadata, options: [.sortedKeys, .prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return nil
    }
    
    // Helper function to convert OperatingSystemVersion to string
    private func osVersionToString(_ version: OperatingSystemVersion) -> String {
        if version.patchVersion == 0 {
            return "\(version.majorVersion).\(version.minorVersion)"
        }
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    // Helper function to get the appropriate unit for a quantity type
    private func getUnitForQuantityType(_ quantityType: HKQuantityType) -> HKUnit {
        switch quantityType.identifier {
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return HKUnit(from: "count/min")
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return HKUnit.pound()
        case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
            return HKUnit.percent()
        case HKQuantityTypeIdentifier.bloodGlucose.rawValue:
            return HKUnit(from: "mg/dL")
        case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
             HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
            return HKUnit(from: "mmHg")
        case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
            return HKUnit(from: "count/min")
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return HKUnit.count()
        case HKQuantityTypeIdentifier.appleExerciseTime.rawValue:
            return HKUnit.minute()
        default:
            // Fallback to a generic unit if type is unknown
            return HKUnit.count()
        }
    }
    
    // Helper function to convert HKSample to complete JSON dictionary
    private func sampleToJSON(_ sample: HKQuantitySample) -> String? {
        var sampleDict: [String: Any] = [:]
        
        // UUID
        sampleDict["uuid"] = sample.uuid.uuidString
        
        // Sample Type
        sampleDict["sampleType"] = sample.sampleType.identifier
        
        // Dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        sampleDict["startDate"] = dateFormatter.string(from: sample.startDate)
        sampleDict["endDate"] = dateFormatter.string(from: sample.endDate)
        
        // Quantity and Unit - determine appropriate unit based on quantity type
        let unit = self.getUnitForQuantityType(sample.quantityType)
        sampleDict["quantity"] = [
            "value": sample.quantity.doubleValue(for: unit),
            "unit": unit.unitString
        ]
        
        // Source
        var sourceDict: [String: Any] = [:]
        sourceDict["name"] = sample.sourceRevision.source.name
        sourceDict["bundleIdentifier"] = sample.sourceRevision.source.bundleIdentifier
        sampleDict["source"] = sourceDict
        
        // Source Revision
        var sourceRevisionDict: [String: Any] = [:]
        sourceRevisionDict["source"] = sourceDict
        sourceRevisionDict["version"] = sample.sourceRevision.version ?? ""
        sourceRevisionDict["productType"] = sample.sourceRevision.productType ?? ""
        
        // Operating System Version
        let osVersion = sample.sourceRevision.operatingSystemVersion
        sourceRevisionDict["operatingSystemVersion"] = [
            "majorVersion": osVersion.majorVersion,
            "minorVersion": osVersion.minorVersion,
            "patchVersion": osVersion.patchVersion,
            "stringValue": osVersionToString(osVersion)
        ]
        sampleDict["sourceRevision"] = sourceRevisionDict
        
        // Device (if available)
        if let device = sample.device {
            var deviceDict: [String: Any?] = [:]
            deviceDict["name"] = device.name
            deviceDict["manufacturer"] = device.manufacturer
            deviceDict["model"] = device.model
            deviceDict["hardwareVersion"] = device.hardwareVersion
            deviceDict["firmwareVersion"] = device.firmwareVersion
            deviceDict["softwareVersion"] = device.softwareVersion
            deviceDict["localIdentifier"] = device.localIdentifier
            deviceDict["udiDeviceIdentifier"] = device.udiDeviceIdentifier
            sampleDict["device"] = deviceDict.compactMapValues { $0 ?? NSNull() }
        } else {
            sampleDict["device"] = NSNull()
        }
        
        // Was User Entered (always include, default to false/0 if unknown)
        let wasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
        sampleDict["wasUserEntered"] = wasUserEntered ? 1 : 0
        
        // Metadata (complete)
        if let metadata = sample.metadata, !metadata.isEmpty {
            var metadataDict: [String: Any] = [:]
            for (key, value) in metadata {
                if let stringValue = value as? String {
                    metadataDict[key] = stringValue
                } else if let numberValue = value as? NSNumber {
                    metadataDict[key] = numberValue
                } else if let dateValue = value as? Date {
                    metadataDict[key] = dateFormatter.string(from: dateValue)
                } else if let boolValue = value as? Bool {
                    metadataDict[key] = boolValue
                } else if let quantityValue = value as? HKQuantity {
                    // Handle HKQuantity metadata values
                    metadataDict[key] = quantityValue.description
                } else {
                    metadataDict[key] = String(describing: value)
                }
            }
            sampleDict["metadata"] = metadataDict
        } else {
            sampleDict["metadata"] = [:]
        }
        
        // Has Undetermined Duration
        sampleDict["hasUndeterminedDuration"] = sample.hasUndeterminedDuration
        
        // Convert to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: sampleDict, options: [.sortedKeys, .prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return nil
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationMessage = "HealthKit is not available on this device"
            return
        }
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.authorizationError = error
                
                if let error = error {
                    self?.authorizationMessage = "HealthKit authorization failed: \(error.localizedDescription)"
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                    self?.isAuthorized = false
                } else {
                    // After authorization dialog, check actual access by doing a query
                    self?.checkAccessByQuery()
                }
            }
        }
    }
    
    func fetchHealthData(for days: Int = 30, completion: @escaping ([HealthDataEntry]) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationMessage = "HealthKit is not available on this device"
            completion([])
            return
        }
        
        guard isAuthorized else {
            authorizationMessage = "Please grant HealthKit permissions to view your health data"
            completion([])
            return
        }
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        var healthEntries: [Date: HealthDataEntry] = [:]
        let dispatchGroup = DispatchGroup()
        
        // Heart Rate
        dispatchGroup.enter()
        fetchQuantityData(for: .heartRate, predicate: predicate) { samples in
            for sample in samples {
                let date = Calendar.current.startOfDay(for: sample.startDate)
                if healthEntries[date] == nil {
                    healthEntries[date] = HealthDataEntry(date: date)
                }
                let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                healthEntries[date]?.heartRate = value
                healthEntries[date]?.heartRateSource = sample.sourceRevision.source.name
                healthEntries[date]?.heartRateSourceBundle = sample.sourceRevision.source.bundleIdentifier
                healthEntries[date]?.heartRateSourceVersion = sample.sourceRevision.version
                healthEntries[date]?.heartRateSourceOS = self.osVersionToString(sample.sourceRevision.operatingSystemVersion)
                healthEntries[date]?.heartRateId = sample.uuid.uuidString
                healthEntries[date]?.heartRateWasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
                healthEntries[date]?.heartRateMetadata = self.metadataToJSON(sample.metadata)
                healthEntries[date]?.heartRateCompleteSample = self.sampleToJSON(sample)
            }
            dispatchGroup.leave()
        }
        
        // Weight
        dispatchGroup.enter()
        fetchQuantityData(for: .bodyMass, predicate: predicate) { samples in
            for sample in samples {
                let date = Calendar.current.startOfDay(for: sample.startDate)
                if healthEntries[date] == nil {
                    healthEntries[date] = HealthDataEntry(date: date)
                }
                let value = sample.quantity.doubleValue(for: HKUnit.pound())
                healthEntries[date]?.weight = value
                healthEntries[date]?.weightSource = sample.sourceRevision.source.name
                healthEntries[date]?.weightSourceBundle = sample.sourceRevision.source.bundleIdentifier
                healthEntries[date]?.weightSourceVersion = sample.sourceRevision.version
                healthEntries[date]?.weightSourceOS = self.osVersionToString(sample.sourceRevision.operatingSystemVersion)
                healthEntries[date]?.weightId = sample.uuid.uuidString
                healthEntries[date]?.weightWasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
                healthEntries[date]?.weightMetadata = self.metadataToJSON(sample.metadata)
                healthEntries[date]?.weightCompleteSample = self.sampleToJSON(sample)
            }
            dispatchGroup.leave()
        }
        
        // Blood Oxygen
        dispatchGroup.enter()
        fetchQuantityData(for: .oxygenSaturation, predicate: predicate) { samples in
            for sample in samples {
                let date = Calendar.current.startOfDay(for: sample.startDate)
                if healthEntries[date] == nil {
                    healthEntries[date] = HealthDataEntry(date: date)
                }
                let value = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
                healthEntries[date]?.bloodOxygen = value
                healthEntries[date]?.bloodOxygenSource = sample.sourceRevision.source.name
                healthEntries[date]?.bloodOxygenSourceBundle = sample.sourceRevision.source.bundleIdentifier
                healthEntries[date]?.bloodOxygenSourceVersion = sample.sourceRevision.version
                healthEntries[date]?.bloodOxygenSourceOS = self.osVersionToString(sample.sourceRevision.operatingSystemVersion)
                healthEntries[date]?.bloodOxygenId = sample.uuid.uuidString
                healthEntries[date]?.bloodOxygenWasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
                healthEntries[date]?.bloodOxygenMetadata = self.metadataToJSON(sample.metadata)
                healthEntries[date]?.bloodOxygenCompleteSample = self.sampleToJSON(sample)
            }
            dispatchGroup.leave()
        }
        
        // Blood Glucose
        dispatchGroup.enter()
        fetchQuantityData(for: .bloodGlucose, predicate: predicate) { samples in
            for sample in samples {
                let date = Calendar.current.startOfDay(for: sample.startDate)
                if healthEntries[date] == nil {
                    healthEntries[date] = HealthDataEntry(date: date)
                }
                let value = sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
                healthEntries[date]?.bloodGlucose = value
                healthEntries[date]?.bloodGlucoseSource = sample.sourceRevision.source.name
                healthEntries[date]?.bloodGlucoseSourceBundle = sample.sourceRevision.source.bundleIdentifier
                healthEntries[date]?.bloodGlucoseSourceVersion = sample.sourceRevision.version
                healthEntries[date]?.bloodGlucoseSourceOS = self.osVersionToString(sample.sourceRevision.operatingSystemVersion)
                healthEntries[date]?.bloodGlucoseId = sample.uuid.uuidString
                healthEntries[date]?.bloodGlucoseWasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
                healthEntries[date]?.bloodGlucoseMetadata = self.metadataToJSON(sample.metadata)
                healthEntries[date]?.bloodGlucoseCompleteSample = self.sampleToJSON(sample)
            }
            dispatchGroup.leave()
        }
        
        // Blood Pressure Systolic
        dispatchGroup.enter()
        fetchQuantityData(for: .bloodPressureSystolic, predicate: predicate) { samples in
            for sample in samples {
                let date = Calendar.current.startOfDay(for: sample.startDate)
                if healthEntries[date] == nil {
                    healthEntries[date] = HealthDataEntry(date: date)
                }
                let value = sample.quantity.doubleValue(for: HKUnit(from: "mmHg"))
                healthEntries[date]?.systolicBP = value
                healthEntries[date]?.systolicBPSource = sample.sourceRevision.source.name
                healthEntries[date]?.systolicBPSourceBundle = sample.sourceRevision.source.bundleIdentifier
                healthEntries[date]?.systolicBPSourceVersion = sample.sourceRevision.version
                healthEntries[date]?.systolicBPSourceOS = self.osVersionToString(sample.sourceRevision.operatingSystemVersion)
                healthEntries[date]?.systolicBPId = sample.uuid.uuidString
                healthEntries[date]?.systolicBPWasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
                healthEntries[date]?.systolicBPMetadata = self.metadataToJSON(sample.metadata)
                healthEntries[date]?.systolicBPCompleteSample = self.sampleToJSON(sample)
            }
            dispatchGroup.leave()
        }
        
        // Blood Pressure Diastolic
        dispatchGroup.enter()
        fetchQuantityData(for: .bloodPressureDiastolic, predicate: predicate) { samples in
            for sample in samples {
                let date = Calendar.current.startOfDay(for: sample.startDate)
                if healthEntries[date] == nil {
                    healthEntries[date] = HealthDataEntry(date: date)
                }
                let value = sample.quantity.doubleValue(for: HKUnit(from: "mmHg"))
                healthEntries[date]?.diastolicBP = value
                healthEntries[date]?.diastolicBPSource = sample.sourceRevision.source.name
                healthEntries[date]?.diastolicBPSourceBundle = sample.sourceRevision.source.bundleIdentifier
                healthEntries[date]?.diastolicBPSourceVersion = sample.sourceRevision.version
                healthEntries[date]?.diastolicBPSourceOS = self.osVersionToString(sample.sourceRevision.operatingSystemVersion)
                healthEntries[date]?.diastolicBPId = sample.uuid.uuidString
                healthEntries[date]?.diastolicBPWasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
                healthEntries[date]?.diastolicBPMetadata = self.metadataToJSON(sample.metadata)
                healthEntries[date]?.diastolicBPCompleteSample = self.sampleToJSON(sample)
            }
            dispatchGroup.leave()
        }
        
        // Respiratory Rate
        dispatchGroup.enter()
        fetchQuantityData(for: .respiratoryRate, predicate: predicate) { samples in
            for sample in samples {
                let date = Calendar.current.startOfDay(for: sample.startDate)
                if healthEntries[date] == nil {
                    healthEntries[date] = HealthDataEntry(date: date)
                }
                let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                healthEntries[date]?.respiratoryRate = value
                healthEntries[date]?.respiratoryRateSource = sample.sourceRevision.source.name
                healthEntries[date]?.respiratoryRateSourceBundle = sample.sourceRevision.source.bundleIdentifier
                healthEntries[date]?.respiratoryRateSourceVersion = sample.sourceRevision.version
                healthEntries[date]?.respiratoryRateSourceOS = self.osVersionToString(sample.sourceRevision.operatingSystemVersion)
                healthEntries[date]?.respiratoryRateId = sample.uuid.uuidString
                healthEntries[date]?.respiratoryRateWasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
                healthEntries[date]?.respiratoryRateMetadata = self.metadataToJSON(sample.metadata)
                healthEntries[date]?.respiratoryRateCompleteSample = self.sampleToJSON(sample)
            }
            dispatchGroup.leave()
        }
        
        // Steps - use statistics query for accurate daily totals
        dispatchGroup.enter()
        fetchDailySumData(for: .stepCount, startDate: startDate, endDate: endDate) { dailyTotals in
            for (date, value) in dailyTotals {
                let dayStart = Calendar.current.startOfDay(for: date)
                if healthEntries[dayStart] == nil {
                    healthEntries[dayStart] = HealthDataEntry(date: dayStart)
                }
                healthEntries[dayStart]?.steps = value
            }
            dispatchGroup.leave()
        }
        
        // Exercise Minutes - use statistics query for accurate daily totals
        dispatchGroup.enter()
        fetchDailySumData(for: .appleExerciseTime, startDate: startDate, endDate: endDate) { dailyTotals in
            for (date, value) in dailyTotals {
                let dayStart = Calendar.current.startOfDay(for: date)
                if healthEntries[dayStart] == nil {
                    healthEntries[dayStart] = HealthDataEntry(date: dayStart)
                }
                healthEntries[dayStart]?.exerciseMinutes = value
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            let sortedEntries = healthEntries.values.sorted { $0.date < $1.date }
            completion(sortedEntries)
        }
    }
    
    private func fetchQuantityData(for identifier: HKQuantityTypeIdentifier, predicate: NSPredicate, completion: @escaping ([HKQuantitySample]) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion([])
            return
        }
        
        let query = HKSampleQuery(
            sampleType: quantityType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching \(identifier.rawValue): \(error.localizedDescription)")
                completion([])
                return
            }
            
            let quantitySamples = samples as? [HKQuantitySample] ?? []
            completion(quantitySamples)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchDailySumData(for identifier: HKQuantityTypeIdentifier, startDate: Date, endDate: Date, completion: @escaping ([Date: Double]) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion([:])
            return
        }
        
        // Create a daily interval for statistics collection
        var interval = DateComponents()
        interval.day = 1
        
        let calendar = Calendar.current
        let anchorDate = calendar.startOfDay(for: startDate)
        
        // Determine the appropriate unit
        let unit = getUnitForQuantityType(quantityType)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, results, error in
            if let error = error {
                print("Error fetching statistics for \(identifier.rawValue): \(error.localizedDescription)")
                completion([:])
                return
            }
            
            var dailyTotals: [Date: Double] = [:]
            
            results?.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    let value = sum.doubleValue(for: unit)
                    dailyTotals[statistics.startDate] = value
                }
            }
            
            completion(dailyTotals)
        }
        
        healthStore.execute(query)
    }
    
    func getDataPoints(from entries: [HealthDataEntry], for type: HealthMetricType) -> [HealthDataPoint] {
        return entries.compactMap { entry in
            var value: Double?
            
            switch type {
            case .heartRate:
                value = entry.heartRate
            case .weight:
                value = entry.weight
            case .bloodOxygen:
                value = entry.bloodOxygen
            case .bloodGlucose:
                value = entry.bloodGlucose
            case .bloodPressure:
                // For blood pressure, we'll show systolic as the primary value
                value = entry.systolicBP
            case .respiratoryRate:
                value = entry.respiratoryRate
            case .steps:
                value = entry.steps
            case .exerciseMinutes:
                value = entry.exerciseMinutes
            }
            
            guard let unwrappedValue = value else { return nil }
            return HealthDataPoint(date: entry.date, value: unwrappedValue, type: type)
        }
    }
}