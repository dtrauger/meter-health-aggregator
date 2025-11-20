//
//  HealthDataDetailView.swift
//  aggregator
//
//  Created by Derek Trauger on 11/17/25.
//

import SwiftUI
import SwiftData

struct HealthDataDetailView: View {
    let entry: HealthDataEntry
    let metricType: HealthMetricType
    
    @State private var jsonString: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with date and metric
                VStack(alignment: .leading, spacing: 8) {
                    Text(metricType.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(entry.date.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                // JSON output
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Raw JSON Data")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = jsonString
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text(jsonString)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Health Data Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateJSON()
        }
    }
    
    private func generateJSON() {
        // Try to use the complete sample JSON first
        var completeSampleJSON: String?
        
        switch metricType {
        case .heartRate:
            completeSampleJSON = entry.heartRateCompleteSample
        case .weight:
            completeSampleJSON = entry.weightCompleteSample
        case .bloodOxygen:
            completeSampleJSON = entry.bloodOxygenCompleteSample
        case .bloodGlucose:
            completeSampleJSON = entry.bloodGlucoseCompleteSample
        case .bloodPressure:
            // For blood pressure, combine both systolic and diastolic complete samples
            if let systolicJSON = entry.systolicBPCompleteSample,
               let diastolicJSON = entry.diastolicBPCompleteSample {
                // Create combined blood pressure JSON
                var combinedDict: [String: Any] = [:]
                combinedDict["systolic"] = parseJSONString(systolicJSON)
                combinedDict["diastolic"] = parseJSONString(diastolicJSON)
                
                if let jsonData = try? JSONSerialization.data(withJSONObject: combinedDict, options: [.prettyPrinted, .sortedKeys]),
                   let jsonStr = String(data: jsonData, encoding: .utf8) {
                    self.jsonString = jsonStr
                    return
                }
            }
        case .respiratoryRate:
            completeSampleJSON = entry.respiratoryRateCompleteSample
        case .steps:
            completeSampleJSON = entry.stepsCompleteSample
        case .exerciseMinutes:
            completeSampleJSON = entry.exerciseMinutesCompleteSample
        }
        
        // If we have complete sample JSON, use it
        if let completeJSON = completeSampleJSON {
            jsonString = completeJSON
        } else {
            // Fallback to empty structure
            jsonString = """
            {
              "error": "No complete sample data available",
              "metricType": "\(metricType.rawValue)",
              "date": "\(ISO8601DateFormatter().string(from: entry.date))"
            }
            """
        }
    }
    
    // Helper to parse JSON string back to dictionary
    private func parseJSONString(_ jsonString: String) -> [String: Any]? {
        guard let jsonData = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }
        return dict
    }
}

#Preview {
    NavigationStack {
        HealthDataDetailView(
            entry: HealthDataEntry(
                date: Date(),
                heartRate: 72.5,
                weight: 180.0,
                bloodOxygen: 98.0
            ),
            metricType: .heartRate
        )
    }
}
