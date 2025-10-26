//
//  APIClient.swift
//  Grocery Agent
//

import Foundation
import Combine

@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()
    
    private let baseURL = "http://localhost:8000"
    private var accessToken: String?
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AuthResponse.User?
    
    private init() {
        // Load saved token if available
        if let token = UserDefaults.standard.string(forKey: "access_token"), !token.isEmpty {
            self.accessToken = token
            // Only set authenticated if we actually have a valid token
            // We'll verify on first API call
            self.isAuthenticated = true
            print("✅ Loaded saved token on init: \(token.prefix(20))...")
        } else {
            // Clear any stale data
            UserDefaults.standard.removeObject(forKey: "access_token")
            self.isAuthenticated = false
            print("ℹ️ No saved token found on init")
        }
    }
    
    // MARK: - Authentication
    
    func register(request: RegisterRequest) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try JSONEncoder().encode(request)
        urlRequest.httpBody = body
        
        logRequest(url: url, method: "POST", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            if let error = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                print("❌ Registration failed: \(error.detail)")
                throw APIError.serverError(error.detail)
            }
            print("❌ Registration failed with status: \(httpResponse.statusCode)")
            throw APIError.serverError("Registration failed")
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        logAPIResponse(authResponse, endpoint: "/auth/register")
        
        // Store token and user
        self.accessToken = authResponse.access_token
        self.currentUser = authResponse.user
        self.isAuthenticated = true
        
        UserDefaults.standard.set(authResponse.access_token, forKey: "access_token")
        
        return authResponse
    }
    
    func login(request: LoginRequest) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try JSONEncoder().encode(request)
        urlRequest.httpBody = body
        
        logRequest(url: url, method: "POST", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            if let error = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                print("❌ Login failed: \(error.detail)")
                throw APIError.serverError(error.detail)
            }
            print("❌ Login failed with status: \(httpResponse.statusCode)")
            throw APIError.serverError("Login failed")
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        logAPIResponse(authResponse, endpoint: "/auth/login")
        
        // Store token and user
        self.accessToken = authResponse.access_token
        self.currentUser = authResponse.user
        self.isAuthenticated = true
        
        UserDefaults.standard.set(authResponse.access_token, forKey: "access_token")
        
        return authResponse
    }
    
    func logout() {
        print("🚪 Logging out user...")
        self.accessToken = nil
        self.currentUser = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "access_token")
        print("✅ Logout complete - returning to landing page")
    }
    
    // MARK: - User Profile
    
    func getUserProfile() async throws -> UserProfileResponse {
        let url = URL(string: "\(baseURL)/profile")!
        var request = try makeAuthenticatedRequest(url: url, method: "GET")
        
        logRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Get profile failed with status: \(httpResponse.statusCode)")
            if let error = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                print("   Error: \(error.detail)")
                throw APIError.serverError(error.detail)
            }
            throw APIError.serverError("Failed to get profile")
        }
        
        let profile = try JSONDecoder().decode(UserProfileResponse.self, from: data)
        logAPIResponse(profile, endpoint: "/profile")
        
        return profile
    }
    
    func updateProfile(request: UpdateProfileRequest) async throws {
        let url = URL(string: "\(baseURL)/profile")!
        let body = try JSONEncoder().encode(request)
        var urlRequest = try makeAuthenticatedRequest(url: url, method: "PUT", body: body)
        
        logRequest(url: url, method: "PUT", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Update profile failed with status: \(httpResponse.statusCode)")
            if let error = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                print("   Error: \(error.detail)")
                throw APIError.serverError(error.detail)
            }
            throw APIError.serverError("Failed to update profile")
        }
        
        print("✅ Profile updated successfully")
    }
    
    // MARK: - Recipe Generation
    
    func generateRecipe(request: RecipeGenerationRequest) async throws -> RecipeGenerationResponse {
        let url = URL(string: "\(baseURL)/recipe")!
        let body = try JSONEncoder().encode(request)
        var urlRequest = try makeAuthenticatedRequest(url: url, method: "POST", body: body)
        
        logRequest(url: url, method: "POST", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Generate recipe failed with status: \(httpResponse.statusCode)")
            if let error = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                print("   Error: \(error.detail)")
                throw APIError.serverError(error.detail)
            }
            throw APIError.serverError("Failed to generate recipe")
        }
        
        let recipeResponse = try JSONDecoder().decode(RecipeGenerationResponse.self, from: data)
        logAPIResponse(recipeResponse, endpoint: "/recipe")
        
        return recipeResponse
    }
    
    // MARK: - Grocery List
    
    func createGroceryList(request: GroceryListRequest) async throws -> GroceryListResponse {
        let url = URL(string: "\(baseURL)/grocery")!
        let body = try JSONEncoder().encode(request)
        var urlRequest = try makeAuthenticatedRequest(url: url, method: "POST", body: body)
        
        logRequest(url: url, method: "POST", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Create grocery list failed with status: \(httpResponse.statusCode)")
            if let error = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                print("   Error: \(error.detail)")
                throw APIError.serverError(error.detail)
            }
            throw APIError.serverError("Failed to create grocery list")
        }
        
        let groceryResponse = try JSONDecoder().decode(GroceryListResponse.self, from: data)
        logAPIResponse(groceryResponse, endpoint: "/grocery")
        
        return groceryResponse
    }
    
    func createGroceryListFromRecipe(request: GroceryListFromRecipeRequest) async throws -> GroceryListFromRecipeResponse {
        let url = URL(string: "\(baseURL)/grocery/from-recipe")!
        let body = try JSONEncoder().encode(request)
        var urlRequest = try makeAuthenticatedRequest(url: url, method: "POST", body: body)
        
        logRequest(url: url, method: "POST", body: body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Create grocery list from recipe failed with status: \(httpResponse.statusCode)")
            if let error = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                print("   Error: \(error.detail)")
                throw APIError.serverError(error.detail)
            }
            throw APIError.serverError("Failed to create grocery list from recipe")
        }
        
        let groceryResponse = try JSONDecoder().decode(GroceryListFromRecipeResponse.self, from: data)
        logAPIResponse(groceryResponse, endpoint: "/grocery/from-recipe")
        
        return groceryResponse
    }
    
    // MARK: - Daily Meal Planning
    
    func generateDailyMeals(day: String) async throws -> DailyMealResponse {
        var components = URLComponents(string: "\(baseURL)/daily-meals/generate-by-day")!
        components.queryItems = [URLQueryItem(name: "day", value: day)]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var urlRequest = try makeAuthenticatedRequest(url: url, method: "POST")
        
        logRequest(url: url, method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Generate daily meals failed with status: \(httpResponse.statusCode)")
            if let error = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                print("   Error: \(error.detail)")
                throw APIError.serverError(error.detail)
            }
            throw APIError.serverError("Failed to generate daily meals")
        }
        
        let mealsResponse = try JSONDecoder().decode(DailyMealResponse.self, from: data)
        logAPIResponse(mealsResponse, endpoint: "/daily-meals/generate-by-day")
        
        return mealsResponse
    }
    
    // MARK: - System Endpoints
    
    func healthCheck() async throws -> HealthCheckResponse {
        let url = URL(string: "\(baseURL)/health")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        logRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Health check failed with status: \(httpResponse.statusCode)")
            throw APIError.serverError("Health check failed")
        }
        
        let healthResponse = try JSONDecoder().decode(HealthCheckResponse.self, from: data)
        logAPIResponse(healthResponse, endpoint: "/health")
        
        return healthResponse
    }
    
    func getRoot() async throws -> RootResponse {
        let url = URL(string: "\(baseURL)/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        logRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Get root failed with status: \(httpResponse.statusCode)")
            throw APIError.serverError("Failed to get root")
        }
        
        let rootResponse = try JSONDecoder().decode(RootResponse.self, from: data)
        logAPIResponse(rootResponse, endpoint: "/")
        
        return rootResponse
    }
    
    // MARK: - Helper Methods
    
    private func logAPIResponse<T: Codable>(_ response: T, endpoint: String) {
        if let jsonData = try? JSONEncoder().encode(response),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📥 Response from \(endpoint):")
            print(jsonString.prefix(500)) // Limit to first 500 chars
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
    }
    
    private func logRequest(url: URL, method: String, body: Data? = nil) {
        print("📤 Request: \(method) \(url.absoluteString)")
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            print("   Body: \(bodyString.prefix(200))")
        }
    }
    
    private func makeAuthenticatedRequest(url: URL, method: String, body: Data? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Using token: \(token.prefix(20))...")
        } else {
            print("❌ No access token available!")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}
