//
//  SettingsView.swift
//  aggregator
//
//  Created by Derek Trauger on 11/20/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let token = authManager.token {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auth Token")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(token)
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Authentication")
                }
                
                Section {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Logout")
                        }
                    }
                } header: {
                    Text("Account")
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AuthManager())
}
