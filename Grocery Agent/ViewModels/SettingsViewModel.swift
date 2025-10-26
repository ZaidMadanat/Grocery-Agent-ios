//
//  SettingsViewModel.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isVoiceModeEnabled = true
    @Published var syncStatus = "Synced 5m ago"
    @Published var showResetConfirmation = false
    @Published var showLogoutConfirmation = false

    private let appModel: AppViewModel

    init(appModel: AppViewModel) {
        self.appModel = appModel
    }

    func resetPreferences() {
        appModel.resetOnboarding()
    }
    
    func logout() {
        // Call APIClient logout to clear token
        APIClient.shared.logout()
        
        // Reset onboarding state in AuthViewModel
        // Note: This will need to be passed in or accessed differently
        // For now, we'll just rely on APIClient.shared.isAuthenticated being false
    }
}
