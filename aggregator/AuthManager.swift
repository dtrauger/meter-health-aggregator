//
//  AuthManager.swift
//  aggregator
//
//  Created by Derek Trauger on 11/20/25.
//

import Foundation
import SwiftUI

@Observable
class AuthManager {
    private let tokenKey = "authToken"
    private let defaults = UserDefaults.standard
    
    var token: String? {
        didSet {
            // Save to UserDefaults whenever token changes
            if let value = token {
                defaults.set(value, forKey: tokenKey)
            } else {
                defaults.removeObject(forKey: tokenKey)
            }
        }
    }
    
    var isAuthenticated: Bool {
        return token != nil && !token!.isEmpty
    }
    
    init() {
        // Load token from UserDefaults on init
        self.token = defaults.string(forKey: tokenKey)
    }
    
    func login(username: String, password: String) -> Bool {
        // For now, accept any non-empty username and password
        guard !username.isEmpty && !password.isEmpty else {
            return false
        }
        
        // Generate a random UUID token (will be replaced with API response later)
        let randomToken = UUID().uuidString
        token = randomToken
        
        return true
    }
    
    func logout() {
        token = nil
    }
}
