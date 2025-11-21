//
//  AuthManager.swift
//  aggregator
//
//  Created by Derek Trauger on 11/20/25.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class AuthManager {
    var currentUser: User?
    var currentGroups: [UserGroup] = []
    var lastError: String?
    
    var isAuthenticated: Bool {
        return currentUser?.authToken != nil && !currentUser!.authToken!.isEmpty
    }
    
    var token: String? {
        return currentUser?.authToken
    }
    
    func login(username: String, password: String) async throws -> Bool {
        // Clear any previous error
        lastError = nil
        
        do {
            // Call API service
            let response = try await APIService.shared.login(username: username, password: password)
            
            // Parse date of birth
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dob = dateFormatter.date(from: response.user.dob) ?? Date()
            
            // Create User object from API response
            currentUser = User(
                firstName: response.user.firstName,
                lastName: response.user.lastName,
                dateOfBirth: dob,
                mrn: String(response.user.mrn),
                type: response.user.type,
                authToken: response.user.authToken
            )
            
            // Create UserGroup objects from API response
            currentGroups = response.groups.map { groupResponse in
                UserGroup(id: groupResponse.id, name: groupResponse.name)
            }
            
            // Link groups to user
            currentUser?.groups = currentGroups
            
            return true
        } catch let error as APIError {
            lastError = error.localizedDescription
            throw error
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    func logout() {
        currentUser = nil
        currentGroups = []
        lastError = nil
    }
}
