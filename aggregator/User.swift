//
//  User.swift
//  aggregator
//
//  Created by Derek Trauger on 11/21/25.
//

import Foundation
import SwiftData

enum UserType: String, Codable {
    case patient = "patient"
    case staff = "staff"
    case admin = "admin"
}

@Model
final class UserGroup {
    @Attribute(.unique) var id: Int
    var name: String
    
    var users: [User] = []
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

@Model
final class User {
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var mrn: String  // Medical Record Number
    var authToken: String?
    var type: String  // "patient", "staff", or "admin"
    
    @Relationship(deleteRule: .nullify, inverse: \UserGroup.users)
    var groups: [UserGroup] = []
    
    init(firstName: String, lastName: String, dateOfBirth: Date, mrn: String, type: String = "patient", authToken: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.mrn = mrn
        self.type = type
        self.authToken = authToken
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var userType: UserType {
        UserType(rawValue: type) ?? .patient
    }
}
