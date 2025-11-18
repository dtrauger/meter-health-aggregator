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
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        // Create a dictionary representation of the entry
        var dataDict: [String: Any] = [
            "date": ISO8601DateFormatter().string(from: entry.date),
            "metricType": metricType.rawValue
        ]
        
        // Add only the relevant values based on metric type
        switch metricType {
        case .heartRate:
            if let value = entry.heartRate {
                dataDict["heartRate"] = value
                dataDict["unit"] = "bpm"
            }
        case .weight:
            if let value = entry.weight {
                dataDict["weight"] = value
                dataDict["unit"] = "lbs"
            }
        case .bloodOxygen:
            if let value = entry.bloodOxygen {
                dataDict["bloodOxygen"] = value
                dataDict["unit"] = "%"
            }
        case .bloodGlucose:
            if let value = entry.bloodGlucose {
                dataDict["bloodGlucose"] = value
                dataDict["unit"] = "mg/dL"
            }
        case .bloodPressure:
            if let systolic = entry.systolicBP, let diastolic = entry.diastolicBP {
                dataDict["systolicBP"] = systolic
                dataDict["diastolicBP"] = diastolic
                dataDict["unit"] = "mmHg"
            }
        case .respiratoryRate:
            if let value = entry.respiratoryRate {
                dataDict["respiratoryRate"] = value
                dataDict["unit"] = "breaths/min"
            }
        }
        
        // Convert to JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: dataDict, options: [.prettyPrinted, .sortedKeys]),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            jsonString = jsonStr
        } else {
            jsonString = "Error: Unable to generate JSON"
        }
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
