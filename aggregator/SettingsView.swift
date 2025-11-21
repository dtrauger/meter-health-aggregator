//
//  SettingsView.swift
//  aggregator
//
//  Created by Derek Trauger on 11/20/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var authManager: AuthManager
    let modelContext: ModelContext
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                if let user = authManager.currentUser {
                    Section {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(user.fullName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Type")
                            Spacer()
                            Text(user.type.capitalized)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Date of Birth")
                            Spacer()
                            Text(user.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("MRN")
                            Spacer()
                            Text(user.mrn)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("User Information")
                    }
                    
                    // Groups Section
                    if !user.groups.isEmpty {
                        Section {
                            ForEach(user.groups, id: \.id) { group in
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.blue)
                                    Text(group.name)
                                }
                            }
                        } header: {
                            Text("Groups")
                        }
                    }
                    
                    Section {
                        if let token = user.authToken {
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
                    logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
    
    private func logout() {
        if let user = authManager.currentUser {
            // Clear the auth token
            user.authToken = nil
            try? modelContext.save()
        }
        
        authManager.logout()
    }
}

#Preview {
    SettingsView(authManager: AuthManager(), modelContext: ModelContext(try! ModelContainer(for: User.self)))
}
