//
//  AuthModels.swift
//  Grocery Agent
//

import Foundation

// MARK: - Auth Request Models
struct RegisterRequest: Codable {
    let email: String
    let username: String
    let password: String
    let name: String
    let daily_calories: Int
    let dietary_restrictions: [String]
    let likes: [String]
    let additional_information: String?
    let macros: MacroTarget
    
    struct MacroTarget: Codable {
        let protein: Double
        let carbs: Double
        let fats: Double
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

// MARK: - Auth Response Models
struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let user: User
    
    struct User: Codable {
        let id: Int
        let email: String
        let username: String
        let name: String
        let daily_calories: Int?
        let dietary_restrictions: [String]?
        let likes: [String]?
    }
}

// MARK: - User Profile Models
struct UserProfileResponse: Codable {
    let user: AuthResponse.User
    let profile: UserProfile
    
    struct UserProfile: Codable {
        let daily_calories: Int?
        let dietary_restrictions: [String]?
        let likes: [String]?
        let additional_information: String?
        let macros: UserMacros?
        
        struct UserMacros: Codable {
            let protein: Double
            let carbs: Double
            let fats: Double
        }
    }
}

// MARK: - Update Profile Request
struct UpdateProfileRequest: Codable {
    let daily_calories: Int?
    let dietary_restrictions: [String]?
    let likes: [String]?
    let additional_information: String?
    let target_protein_g: Double?
    let target_carbs_g: Double?
    let target_fat_g: Double?
}

// MARK: - Error Response
struct APIErrorResponse: Codable {
    let detail: String
}

// MARK: - Custom Error
enum APIError: Error, LocalizedError {
    case serverError(String)
    case invalidURL
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .invalidURL:
            return "Invalid URL"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error occurred"
        }
    }
}
