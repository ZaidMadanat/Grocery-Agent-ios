//
//  LandingView.swift
//  Grocery Agent
//

import SwiftUI

struct LandingView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showOnboarding = false
    @FocusState private var focusedField: AuthField?
    
    enum AuthField {
        case name, email, username, password, confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.mint.opacity(0.2), .blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo/Header
                        header
                        
                        // Auth form
                        authForm
                        
                        // Toggle between login/signup
                        toggleModeButton
                        
                        // Submit button
                        submitButton
                        
                        if let errorMessage = authViewModel.errorMessage {
                            errorBanner(errorMessage)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.circle.fill")
                .font(.system(size: 80))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)
            
            Text("Grocery Agent")
                .font(.largeTitle.bold())
            
            Text(authViewModel.mode == .login 
                ? "Welcome back!" 
                : "Start your meal planning journey")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var authForm: some View {
        VStack(spacing: 16) {
            if authViewModel.mode == .signup {
                // Name field (signup only)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Full Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("John Doe", text: $authViewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .focused($focusedField, equals: .name)
                        .autocapitalization(.words)
                }
                
                // Username field (signup only)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Username")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("username", text: $authViewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .username)
                }
            }
            
            // Email field
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("you@example.com", text: $authViewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Password", text: $authViewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(authViewModel.mode == .login ? .password : .newPassword)
                    .focused($focusedField, equals: .password)
            }
            
            // Confirm password field (signup only)
            if authViewModel.mode == .signup {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Password")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("Confirm Password", text: $authViewModel.confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                    
                    if !authViewModel.password.isEmpty && !authViewModel.passwordsMatch {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("Passwords must match")
                                .font(.caption2)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
    
    private var toggleModeButton: some View {
        Button(action: {
            withAnimation {
                authViewModel.toggleMode()
            }
        }) {
            HStack {
                Text(authViewModel.mode == .login 
                    ? "Don't have an account?" 
                    : "Already have an account?")
                    .foregroundStyle(.secondary)
                Text(authViewModel.mode == .login ? "Sign Up" : "Log In")
                    .foregroundStyle(Color.accentColor)
                    .bold()
            }
            .font(.subheadline)
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            Task {
                await authViewModel.submitAuth()
            }
        }) {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(authViewModel.mode == .login ? "Log In" : "Sign Up")
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!authViewModel.canSubmit || authViewModel.isLoading || !authViewModel.passwordsMatch)
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(.red)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    LandingView(authViewModel: AuthViewModel())
}
