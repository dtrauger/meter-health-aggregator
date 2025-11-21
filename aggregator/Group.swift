//
//  Group.swift
//  aggregator
//
//  Created by Derek Trauger on 11/21/25.
//

import Foundation
import SwiftData

@Model
final class Group {
    @Attribute(.unique) var id: Int
    var name: String
    
    var users: [User]?
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.users = []
    }
}
