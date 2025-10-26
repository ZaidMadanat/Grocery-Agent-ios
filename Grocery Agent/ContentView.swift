//
//  ContentView.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appModel = AppViewModel()
    @ObservedObject private var apiClient = APIClient.shared
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if apiClient.isAuthenticated {
                // User is authenticated
                if authViewModel.needsOnboarding {
                    // New user needs to complete onboarding
                    OnboardingFlowView(appModel: appModel, authViewModel: authViewModel)
                        .transition(.move(edge: .trailing))
                } else {
                    // Existing user or onboarding complete - go to dashboard
                    MainShellView(appModel: appModel)
                        .transition(.opacity.combined(with: .scale))
                }
            } else {
                // User is not authenticated - show landing/auth page
                LandingView(authViewModel: authViewModel)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: apiClient.isAuthenticated)
        .animation(.easeInOut, value: authViewModel.needsOnboarding)
        .onChange(of: apiClient.isAuthenticated) { oldValue, newValue in
            // When user becomes authenticated (login or signup), fetch their profile
            if newValue && !oldValue {
                Task {
                    await appModel.fetchUserProfileIfNeeded()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
