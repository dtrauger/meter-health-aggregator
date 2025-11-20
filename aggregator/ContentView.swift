//
//  ContentView.swift
//  aggregator
//
//  Created by Derek Trauger on 10/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView(authManager: authManager)
                    .transition(.opacity)
            } else {
                LoginView(authManager: authManager)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

struct MainTabView: View {
    @Bindable var authManager: AuthManager
    
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
            
            SettingsView(authManager: authManager)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: HealthDataEntry.self, inMemory: true)
}

