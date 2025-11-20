//
//  DashboardView.swift
//  aggregator
//
//  Created by Derek Trauger on 11/20/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \HealthDataEntry.date, order: .reverse) private var healthEntries: [HealthDataEntry]
    
    // Get the most recent value for each metric
    private func latestValue(for keyPath: KeyPath<HealthDataEntry, Double?>) -> (value: Double, date: Date)? {
        for entry in healthEntries {
            if let value = entry[keyPath: keyPath] {
                return (value, entry.date)
            }
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    // Heart Rate Card
                    if let data = latestValue(for: \.heartRate) {
                        MetricCard(
                            title: "Heart Rate",
                            value: data.value,
                            unit: "bpm",
                            date: data.date,
                            icon: "heart.fill",
                            color: .red,
                            formatSpecifier: "%.0f"
                        )
                    }
                    
                    // Steps Card
                    if let data = latestValue(for: \.steps) {
                        MetricCard(
                            title: "Steps",
                            value: data.value,
                            unit: "steps",
                            date: data.date,
                            icon: "figure.walk",
                            color: .green,
                            formatSpecifier: "%.0f"
                        )
                    }
                    
                    // Exercise Minutes Card
                    if let data = latestValue(for: \.exerciseMinutes) {
                        MetricCard(
                            title: "Exercise",
                            value: data.value,
                            unit: "min",
                            date: data.date,
                            icon: "figure.run",
                            color: .orange,
                            formatSpecifier: "%.0f"
                        )
                    }
                    
                    // Blood Oxygen Card
                    if let data = latestValue(for: \.bloodOxygen) {
                        MetricCard(
                            title: "Blood Oxygen",
                            value: data.value,
                            unit: "%",
                            date: data.date,
                            icon: "lungs.fill",
                            color: .blue,
                            formatSpecifier: "%.0f"
                        )
                    }
                    
                    // Weight Card
                    if let data = latestValue(for: \.weight) {
                        MetricCard(
                            title: "Weight",
                            value: data.value,
                            unit: "lbs",
                            date: data.date,
                            icon: "scalemass.fill",
                            color: .purple,
                            formatSpecifier: "%.1f"
                        )
                    }
                    
                    // Blood Glucose Card
                    if let data = latestValue(for: \.bloodGlucose) {
                        MetricCard(
                            title: "Blood Glucose",
                            value: data.value,
                            unit: "mg/dL",
                            date: data.date,
                            icon: "drop.fill",
                            color: .pink,
                            formatSpecifier: "%.1f"
                        )
                    }
                    
                    // Blood Pressure Card
                    if let systolicData = latestValue(for: \.systolicBP),
                       let diastolicData = latestValue(for: \.diastolicBP),
                       systolicData.date == diastolicData.date {
                        BloodPressureCard(
                            systolic: systolicData.value,
                            diastolic: diastolicData.value,
                            date: systolicData.date
                        )
                    }
                    
                    // Respiratory Rate Card
                    if let data = latestValue(for: \.respiratoryRate) {
                        MetricCard(
                            title: "Respiratory Rate",
                            value: data.value,
                            unit: "breaths/min",
                            date: data.date,
                            icon: "wind",
                            color: .cyan,
                            formatSpecifier: "%.1f"
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let date: Date
    let icon: String
    let color: Color
    let formatSpecifier: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Value
            VStack(spacing: 4) {
                Text("\(value, specifier: formatSpecifier)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Date
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct BloodPressureCard: View {
    let systolic: Double
    let diastolic: Double
    let date: Date
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.red)
            
            // Title
            Text("Blood Pressure")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Value
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(systolic, specifier: "%.0f")")
                        .font(.system(size: 28, weight: .bold))
                    Text("/")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(diastolic, specifier: "%.0f")")
                        .font(.system(size: 28, weight: .bold))
                }
                
                Text("mmHg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Date
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: HealthDataEntry.self, inMemory: true)
}
