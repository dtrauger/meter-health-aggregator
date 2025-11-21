//
//  APIService.swift
//  aggregator
//
//  Created by Derek Trauger on 11/21/25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        }
    }
}

struct APIResponse<T: Decodable>: Decodable {
    let status: ResponseStatus
    let user: T?
    let group: [GroupResponse]?
    
    struct ResponseStatus: Decodable {
        let message: String
        let code: Int
    }
    
    enum CodingKeys: String, CodingKey {
        case status
        case user
        case group = "group"  // Also try "groups" as fallback
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        status = try container.decode(ResponseStatus.self, forKey: .status)
        user = try container.decodeIfPresent(T.self, forKey: .user)
        
        // Try to decode "group" first, if that fails try as empty array
        group = try? container.decodeIfPresent([GroupResponse].self, forKey: .group)
    }
}

struct GroupResponse: Decodable {
    let id: Int
    let name: String
}

struct UserResponse: Decodable {
    let firstName: String
    let lastName: String
    let dob: String
    let mrn: Int
    let authToken: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case dob
        case mrn
        case authToken = "auth_token"
        case type
    }
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://inlyten.com"
    
    private init() {}
    
    func login(username: String, password: String) async throws -> (user: UserResponse, groups: [GroupResponse]) {
        // Construct URL
        guard let url = URL(string: "\(baseURL)/auth/") else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        let body: [String: String] = [
            "username": username,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Perform request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Debug: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Raw API Response:")
            print(jsonString)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        
        do {
            let apiResponse = try decoder.decode(APIResponse<UserResponse>.self, from: data)
            
            // Check status code from the response JSON
            guard apiResponse.status.code == 200 else {
                // Use the message from the status object
                throw APIError.serverError(apiResponse.status.message)
            }
            
            // Return user data
            guard let user = apiResponse.user else {
                throw APIError.serverError("No user data in response")
            }
            
            let groups = apiResponse.group ?? []
            
            return (user: user, groups: groups)
        } catch let apiError as APIError {
            // Re-throw APIErrors (including serverError from status check)
            throw apiError
        } catch let decodingError as DecodingError {
            // Print detailed decoding error
            print("❌ Decoding Error Details:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("  Key '\(key.stringValue)' not found at: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                print("  Debug description: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("  Type mismatch for type '\(type)' at: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                print("  Debug description: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("  Value not found for type '\(type)' at: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                print("  Debug description: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("  Data corrupted at: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                print("  Debug description: \(context.debugDescription)")
            @unknown default:
                print("  Unknown decoding error")
            }
            throw APIError.decodingError(decodingError)
        } catch {
            throw APIError.networkError(error)
        }
    }
}
