//
//  ContentView.swift
//  aggregator
//
//  Created by Derek Trauger on 10/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var authManager = AuthManager()
    
    var body: some View {
        ZStack {
            if authManager.isAuthenticated {
                MainTabView(authManager: authManager, modelContext: modelContext)
                    .transition(.opacity)
            } else {
                LoginView(authManager: authManager, modelContext: modelContext)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .onAppear {
            loadCurrentUser()
        }
    }
    
    private func loadCurrentUser() {
        // Load the most recent user with a valid auth token
        if let user = users.first(where: { $0.authToken != nil && !$0.authToken!.isEmpty }) {
            authManager.currentUser = user
        }
    }
}

struct MainTabView: View {
    @Bindable var authManager: AuthManager
    let modelContext: ModelContext
    
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
            
            SettingsView(authManager: authManager, modelContext: modelContext)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [User.self, HealthDataEntry.self], inMemory: true)
}

