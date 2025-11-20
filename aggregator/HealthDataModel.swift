//
//  HealthDataModel.swift
//  aggregator
//
//  Created by Derek Trauger on 11/5/25.
//

import Foundation
import SwiftData
import HealthKit

@Model
final class HealthDataEntry {
    var date: Date
    var heartRate: Double?
    var weight: Double?
    var bloodOxygen: Double?
    var bloodGlucose: Double?
    var systolicBP: Double?
    var diastolicBP: Double?
    var respiratoryRate: Double?
    var steps: Double?
    var exerciseMinutes: Double?
    
    // Source information (app/device name)
    var heartRateSource: String?
    var weightSource: String?
    var bloodOxygenSource: String?
    var bloodGlucoseSource: String?
    var systolicBPSource: String?
    var diastolicBPSource: String?
    var respiratoryRateSource: String?
    var stepsSource: String?
    var exerciseMinutesSource: String?
    
    // Source bundle identifiers
    var heartRateSourceBundle: String?
    var weightSourceBundle: String?
    var bloodOxygenSourceBundle: String?
    var bloodGlucoseSourceBundle: String?
    var systolicBPSourceBundle: String?
    var diastolicBPSourceBundle: String?
    var respiratoryRateSourceBundle: String?
    var stepsSourceBundle: String?
    var exerciseMinutesSourceBundle: String?
    
    // Source version (product version)
    var heartRateSourceVersion: String?
    var weightSourceVersion: String?
    var bloodOxygenSourceVersion: String?
    var bloodGlucoseSourceVersion: String?
    var systolicBPSourceVersion: String?
    var diastolicBPSourceVersion: String?
    var respiratoryRateSourceVersion: String?
    var stepsSourceVersion: String?
    var exerciseMinutesSourceVersion: String?
    
    // Operating system version
    var heartRateSourceOS: String?
    var weightSourceOS: String?
    var bloodOxygenSourceOS: String?
    var bloodGlucoseSourceOS: String?
    var systolicBPSourceOS: String?
    var diastolicBPSourceOS: String?
    var respiratoryRateSourceOS: String?
    var stepsSourceOS: String?
    var exerciseMinutesSourceOS: String?
    
    // Sample identifiers (UUIDs from HealthKit)
    var heartRateId: String?
    var weightId: String?
    var bloodOxygenId: String?
    var bloodGlucoseId: String?
    var systolicBPId: String?
    var diastolicBPId: String?
    var respiratoryRateId: String?
    var stepsId: String?
    var exerciseMinutesId: String?
    
    // Metadata flags
    var heartRateWasUserEntered: Bool?
    var weightWasUserEntered: Bool?
    var bloodOxygenWasUserEntered: Bool?
    var bloodGlucoseWasUserEntered: Bool?
    var systolicBPWasUserEntered: Bool?
    var diastolicBPWasUserEntered: Bool?
    var respiratoryRateWasUserEntered: Bool?
    var stepsWasUserEntered: Bool?
    var exerciseMinutesWasUserEntered: Bool?
    
    // Complete metadata (stored as JSON string for flexibility)
    var heartRateMetadata: String?
    var weightMetadata: String?
    var bloodOxygenMetadata: String?
    var bloodGlucoseMetadata: String?
    var systolicBPMetadata: String?
    var diastolicBPMetadata: String?
    var respiratoryRateMetadata: String?
    var stepsMetadata: String?
    var exerciseMinutesMetadata: String?
    
    // Complete HKSample as JSON (all properties)
    var heartRateCompleteSample: String?
    var weightCompleteSample: String?
    var bloodOxygenCompleteSample: String?
    var bloodGlucoseCompleteSample: String?
    var systolicBPCompleteSample: String?
    var diastolicBPCompleteSample: String?
    var respiratoryRateCompleteSample: String?
    var stepsCompleteSample: String?
    var exerciseMinutesCompleteSample: String?
    
    init(date: Date) {
        self.date = date
    }
    
    convenience init(
        date: Date,
        heartRate: Double? = nil,
        weight: Double? = nil,
        bloodOxygen: Double? = nil,
        bloodGlucose: Double? = nil,
        systolicBP: Double? = nil,
        diastolicBP: Double? = nil,
        respiratoryRate: Double? = nil
    ) {
        self.init(date: date)
        self.heartRate = heartRate
        self.weight = weight
        self.bloodOxygen = bloodOxygen
        self.bloodGlucose = bloodGlucose
        self.systolicBP = systolicBP
        self.diastolicBP = diastolicBP
        self.respiratoryRate = respiratoryRate
    }
}

enum HealthMetricType: String, CaseIterable {
    case heartRate = "Heart Rate"
    case weight = "Weight"
    case bloodOxygen = "Blood Oxygen"
    case bloodGlucose = "Blood Glucose"
    case bloodPressure = "Blood Pressure"
    case respiratoryRate = "Respiratory Rate"
    case steps = "Steps"
    case exerciseMinutes = "Exercise Minutes"
    
    var unit: String {
        switch self {
        case .heartRate:
            return "bpm"
        case .weight:
            return "lbs"
        case .bloodOxygen:
            return "%"
        case .bloodGlucose:
            return "mg/dL"
        case .bloodPressure:
            return "mmHg"
        case .respiratoryRate:
            return "breaths/min"
        case .steps:
            return "steps"
        case .exerciseMinutes:
            return "min"
        }
    }
    
    var formatSpecifier: String {
        switch self {
        case .heartRate, .bloodOxygen, .steps, .exerciseMinutes:
            return "%.0f"  // Whole numbers
        case .weight, .bloodGlucose, .bloodPressure, .respiratoryRate:
            return "%.1f"  // One decimal place
        }
    }
    
    var systemImageName: String {
        switch self {
        case .heartRate:
            return "heart.fill"
        case .weight:
            return "scalemass.fill"
        case .bloodOxygen:
            return "lungs.fill"
        case .bloodGlucose:
            return "drop.fill"
        case .bloodPressure:
            return "heart.circle.fill"
        case .respiratoryRate:
            return "wind"
        case .steps:
            return "figure.walk"
        case .exerciseMinutes:
            return "figure.run"
        }
    }
}

struct HealthDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let type: HealthMetricType
}