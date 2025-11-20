//
//  ContentView.swift
//  aggregator
//
//  Created by Derek Trauger on 10/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
            
            HealthDataView()
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: HealthDataEntry.self, inMemory: true)
}
