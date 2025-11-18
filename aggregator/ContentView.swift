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
        HealthDataView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: HealthDataEntry.self, inMemory: true)
}
