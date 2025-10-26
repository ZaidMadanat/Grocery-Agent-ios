//
//  AuthViewModel.swift
//  Grocery Agent
//

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    enum AuthMode {
        case login
        case signup
    }
    
    @Published var mode: AuthMode = .login
    
    // Common fields
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    // Signup specific fields
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var dailyCalories: String = "2000"
    @Published var dietaryRestrictions: [String] = []
    @Published var likes: [String] = []
    @Published var additionalInformation: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var authToken: String?
    @Published var needsOnboarding: Bool = false  // Track if user needs to complete onboarding
    
    private let apiClient = APIClient.shared
    
    var canSubmit: Bool {
        if mode == .login {
            return !email.isEmpty && !password.isEmpty
        } else {
            // Signup requires email, password, name, username, and matching passwords
            return !email.isEmpty && 
                   !password.isEmpty && 
                   !name.isEmpty && 
                   !username.isEmpty && 
                   password == confirmPassword &&
                   !username.isEmpty
        }
    }
    
    var passwordsMatch: Bool {
        if mode == .signup {
            return password == confirmPassword
        }
        return true
    }
    
    func toggleMode() {
        mode = mode == .login ? .signup : .login
        errorMessage = nil
        // Clear passwords when switching modes
        password = ""
        confirmPassword = ""
    }
    
    func submitAuth() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            if mode == .login {
                try await handleLogin()
            } else {
                try await handleSignup()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleLogin() async throws {
        let request = LoginRequest(email: email, password: password)
        let response = try await apiClient.login(request: request)
        self.authToken = response.access_token
        self.isAuthenticated = true
        self.needsOnboarding = false  // Existing user doesn't need onboarding
    }
    
    private func handleSignup() async throws {
        // Parse daily calories with validation
        let calories = Int(dailyCalories) ?? 2000
        
        // Calculate macros in grams from percentages (default 30% protein, 40% carbs, 30% fat)
        // Using standard 4 calories per gram for protein/carbs, 9 for fat
        let proteinGrams = (Double(calories) * 0.30) / 4.0  // 30% of calories from protein
        let carbsGrams = (Double(calories) * 0.40) / 4.0    // 40% of calories from carbs
        let fatsGrams = (Double(calories) * 0.30) / 9.0     // 30% of calories from fats
        
        let request = RegisterRequest(
            email: email,
            username: username,
            password: password,
            name: name,
            daily_calories: calories,
            dietary_restrictions: dietaryRestrictions,
            likes: likes,
            additional_information: additionalInformation.isEmpty ? nil : additionalInformation,
            macros: RegisterRequest.MacroTarget(
                protein: proteinGrams,
                carbs: carbsGrams,
                fats: fatsGrams
            )
        )
        
        let response = try await apiClient.register(request: request)
        self.authToken = response.access_token
        self.isAuthenticated = true
        self.needsOnboarding = true  // New user needs to complete onboarding
    }
}
