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
    
    var isAuthenticated: Bool {
        return token != nil && !token!.isEmpty
    }
    
    var token: String? {
        get {
            defaults.string(forKey: tokenKey)
        }
        set {
            defaults.set(newValue, forKey: tokenKey)
        }
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
