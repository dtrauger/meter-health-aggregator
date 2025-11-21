//
//  LoginView.swift
//  aggregator
//
//  Created by Derek Trauger on 11/20/25.
//

import SwiftUI
import SwiftData

struct LoginView: View {
    @Bindable var authManager: AuthManager
    let modelContext: ModelContext
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = "Please enter both username and password"
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // App Icon/Logo
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
                
                // Title
                Text("Welcome")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 16) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter username", text: $username)
                            .textFieldStyle(.plain)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    // Error Message
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Login Button
                    Button {
                        login()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Login")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(username.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(isLoading || username.isEmpty || password.isEmpty)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func login() {
        showError = false
        isLoading = true
        
        Task {
            do {
                // Call async login method
                let success = try await authManager.login(username: username, password: password)
                
                await MainActor.run {
                    isLoading = false
                    
                    if success, let user = authManager.currentUser {
                        // Save groups to SwiftData first
                        for group in authManager.currentGroups {
                            modelContext.insert(group)
                        }
                        
                        // Save user to SwiftData
                        modelContext.insert(user)
                        try? modelContext.save()
                    } else {
                        errorMessage = authManager.lastError ?? "Login failed"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = authManager.lastError ?? error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    LoginView(authManager: AuthManager(), modelContext: ModelContext(try! ModelContainer(for: User.self)))
}
