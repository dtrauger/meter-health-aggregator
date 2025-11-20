//
//  HealthDataView.swift
//  aggregator
//
//  Created by Derek Trauger on 11/5/25.
//

import SwiftUI
import SwiftData
import Charts

struct HealthDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthDataEntry.date, order: .forward) private var healthEntries: [HealthDataEntry]
    @State private var healthKitManager = HealthKitManager()
    @State private var selectedMetric: HealthMetricType = .heartRate
    @State private var isLoading = false
    @State private var showingAuthorizationAlert = false
    @State private var isCheckingAuthorization = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isCheckingAuthorization {
                    // Show loading while checking authorization
                    ProgressView("Checking HealthKit access...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !healthKitManager.isAuthorized {
                    authorizationView
                } else {
                    metricSelector
                    
                    if healthEntries.isEmpty {
                        emptyStateView
                    } else {
                        chartView
                        dataTableView
                    }
                }
            }
            .navigationTitle("Health Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        refreshData()
                    }
                    .disabled(isLoading || !healthKitManager.isAuthorized)
                }
            }
            .task {
                // Wait a moment for authorization check to complete
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                isCheckingAuthorization = false
                
                // Refresh data if authorized
                if healthKitManager.isAuthorized {
                    refreshData()
                }
            }
            .onChange(of: healthKitManager.isAuthorized) { oldValue, newValue in
                // Stop checking state when authorization changes
                isCheckingAuthorization = false
                
                // Auto-refresh when authorization status changes to authorized
                if newValue && !oldValue {
                    refreshData()
                }
            }
            .alert("HealthKit Authorization", isPresented: $showingAuthorizationAlert) {
                Button("Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable HealthKit access in Settings to view your health data.")
            }
        }
    }
    
    private var authorizationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("HealthKit Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This app needs access to your HealthKit data to display your health metrics including heart rate, weight, blood oxygen, blood glucose, blood pressure, and respiratory rate.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if let message = healthKitManager.authorizationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Request Access") {
                healthKitManager.requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
            
            if healthKitManager.authorizationError != nil {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    private var metricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HealthMetricType.allCases, id: \.self) { metric in
                    Button {
                        selectedMetric = metric
                    } label: {
                        HStack {
                            Image(systemName: metric.systemImageName)
                            Text(metric.rawValue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedMetric == metric ? .blue : .gray.opacity(0.2))
                        )
                        .foregroundColor(selectedMetric == metric ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Health Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap refresh to load your health data from HealthKit.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if isLoading {
                ProgressView("Loading...")
                    .padding()
            }
        }
        .padding()
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedMetric.rawValue) Over Time")
                .font(.headline)
                .padding(.horizontal)
            
            if selectedMetric == .bloodPressure {
                bloodPressureChart
            } else {
                regularChart
            }
        }
        .padding(.vertical)
    }
    
    private var regularChart: some View {
        let dataPoints = healthKitManager.getDataPoints(from: healthEntries, for: selectedMetric)
            .sorted { $0.date < $1.date }
        
        // Calculate Y-axis range with padding
        let values = dataPoints.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let range = maxValue - minValue
        let padding = range * 0.1 // 10% padding on each side
        let yMin = max(0, minValue - padding)
        let yMax = maxValue + padding
        
        return Chart(dataPoints) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value(selectedMetric.rawValue, dataPoint.value)
            )
            .foregroundStyle(.blue)
            .symbol(.circle)
            
            AreaMark(
                x: .value("Date", dataPoint.date),
                y: .value(selectedMetric.rawValue, dataPoint.value)
            )
            .foregroundStyle(.blue.opacity(0.1))
        }
        .chartYScale(domain: yMin...yMax)
        .chartYAxisLabel(selectedMetric.unit, position: .leading)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .frame(height: 200)
        .padding(.horizontal)
    }
    
    private var bloodPressureChart: some View {
        let bpEntries = healthEntries
            .filter { $0.systolicBP != nil && $0.diastolicBP != nil }
            .sorted { $0.date < $1.date }
        
        // Calculate Y-axis range for blood pressure with padding
        let systolicValues = bpEntries.compactMap { $0.systolicBP }
        let diastolicValues = bpEntries.compactMap { $0.diastolicBP }
        let allValues = systolicValues + diastolicValues
        
        let minValue = allValues.min() ?? 60
        let maxValue = allValues.max() ?? 140
        let range = maxValue - minValue
        let padding = max(range * 0.1, 5) // At least 5 units padding
        let yMin = max(0, minValue - padding)
        let yMax = maxValue + padding
        
        return Chart {
            ForEach(bpEntries, id: \.date) { entry in
                // Systolic line
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Pressure", entry.systolicBP ?? 0),
                    series: .value("Type", "Systolic")
                )
                .foregroundStyle(.red)
                .symbol(.circle)
                
                // Diastolic line
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Pressure", entry.diastolicBP ?? 0),
                    series: .value("Type", "Diastolic")
                )
                .foregroundStyle(.blue)
                .symbol(.diamond)
            }
        }
        .chartYScale(domain: yMin...yMax)
        .chartYAxisLabel("mmHg", position: .leading)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .frame(height: 200)
        .padding(.horizontal)
    }
    
    private var dataTableView: some View {
        List {
            Section("Recent Data") {
                if selectedMetric == .bloodPressure {
                    // Special handling for blood pressure - show systolic/diastolic
                    let sortedEntries = healthEntries
                        .filter { $0.systolicBP != nil && $0.diastolicBP != nil }
                        .sorted(by: { $0.date > $1.date })
                        .prefix(20)
                    
                    ForEach(Array(sortedEntries), id: \.date) { entry in
                        NavigationLink(destination: HealthDataDetailView(entry: entry, metricType: selectedMetric)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.headline)
                                    Text("Blood Pressure")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("\(Int(entry.systolicBP ?? 0))/\(Int(entry.diastolicBP ?? 0))")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Text("mmHg")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    // Regular metrics
                    let sortedDataPoints = healthKitManager.getDataPoints(from: healthEntries, for: selectedMetric)
                        .sorted(by: { $0.date > $1.date })
                        .prefix(20)
                    
                    ForEach(Array(sortedDataPoints), id: \.id) { dataPoint in
                        // Find the corresponding entry for navigation
                        if let entry = healthEntries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: dataPoint.date) }) {
                            NavigationLink(destination: HealthDataDetailView(entry: entry, metricType: selectedMetric)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(dataPoint.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.headline)
                                        Text(selectedMetric.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(dataPoint.value, specifier: selectedMetric.formatSpecifier)")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        Text(selectedMetric.unit)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func refreshData() {
        guard healthKitManager.isAuthorized else {
            showingAuthorizationAlert = true
            return
        }
        
        isLoading = true
        healthKitManager.fetchHealthData { newEntries in
            // Clear existing data
            for entry in healthEntries {
                modelContext.delete(entry)
            }
            
            // Insert new data
            for entry in newEntries {
                modelContext.insert(entry)
            }
            
            try? modelContext.save()
            isLoading = false
        }
    }
}

#Preview {
    HealthDataView()
        .modelContainer(for: [Item.self, HealthDataEntry.self], inMemory: true)
}