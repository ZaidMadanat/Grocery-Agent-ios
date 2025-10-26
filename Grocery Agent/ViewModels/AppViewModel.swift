//
//  AppViewModel.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var preferences: UserPreferences?
    @Published private(set) var weeklyPlan: [MealPlanDay] = []
    @Published private(set) var groceryItems: [GroceryItem] = []
    @Published private(set) var inventoryItems: [InventoryItem] = []
    @Published private(set) var notifications: [AgentNotification] = []

    private let preferenceStore: PreferenceStore

    init(preferenceStore: PreferenceStore) {
        self.preferenceStore = preferenceStore
        bootstrap()
    }

    init() {
        self.preferenceStore = PreferenceStore()
        bootstrap()
    }

    var isOnboarded: Bool {
        // User is onboarded if they have preferences AND have completed onboarding
        // We also check if they're authenticated to ensure proper flow
        preferences != nil && APIClient.shared.isAuthenticated
    }

    func bootstrap() {
        if let stored = preferenceStore.loadPreferences() {
            preferences = stored
        } else {
            // Use sample values for new users until onboarding completes.
            preferences = nil
        }

        // Load initial data
        weeklyPlan = MockDataService.weeklyPlan()
        groceryItems = MockDataService.groceryItems()
        inventoryItems = MockDataService.inventoryItems()
        notifications = MockDataService.notifications()
        
        // Fetch user profile from API if authenticated
        if APIClient.shared.isAuthenticated {
            Task {
                await fetchUserProfile()
            }
        }
    }
    
    @MainActor
    func fetchUserProfileIfNeeded() async {
        // Only fetch if we're authenticated and haven't fetched yet
        guard APIClient.shared.isAuthenticated else {
            print("ℹ️ Not authenticated, skipping profile fetch")
            return
        }
        await fetchUserProfile()
    }
    
    private func fetchUserProfile() async {
        print("📡 Attempting to fetch user profile...")
        print("   isAuthenticated: \(APIClient.shared.isAuthenticated)")
        do {
            let profile = try await APIClient.shared.getUserProfile()
            print("✅ Successfully fetched user profile")
            
            // Update or create preferences from API response
            var prefs = preferences ?? UserPreferences(
                dietaryRestrictions: [],
                customRestrictions: [],
                dailyCalorieGoal: 2000,
                mealTypes: [.breakfast, .lunch, .dinner],
                macroPriorities: .balanced
            )
            
            // Update from API response
            if let dailyCalories = profile.profile.daily_calories {
                prefs.dailyCalorieGoal = dailyCalories
            }
            
            // Update macros if available
            // The API returns percentages (sum to ~1.0), which MacroPriorities expects
            if let macros = profile.profile.macros {
                prefs.macroPriorities = MacroPriorities(
                    protein: macros.protein,
                    carbs: macros.carbs,
                    fats: macros.fats
                )
                print("📊 Updated macro priorities from API:")
                print("   Protein: \(macros.protein * 100)%")
                print("   Carbs: \(macros.carbs * 100)%")
                print("   Fats: \(macros.fats * 100)%")
            }
            
            // Update dietary restrictions
            if let restrictions = profile.profile.dietary_restrictions {
                // Convert string restrictions to enum types (simplified)
                prefs.dietaryRestrictions = []
                prefs.customRestrictions = restrictions
            }
            
            // Save updated preferences
            preferences = prefs
            preferenceStore.save(prefs)
            
            // Update current user info
            APIClient.shared.currentUser = profile.user
            
        } catch {
            print("❌ Failed to fetch user profile: \(error)")
            if let apiError = error as? APIError {
                print("   Error type: \(apiError)")
                if case .serverError(let message) = apiError {
                    print("   Server message: \(message)")
                }
            }
            // Handle error gracefully - user can still use the app
        }
    }

    @MainActor
    func setPreferences(_ newPreferences: UserPreferences) {
        preferences = newPreferences
        preferenceStore.save(newPreferences)
    }

    func updatePreference(_ updateBlock: (inout UserPreferences) -> Void) {
        guard var existing = preferences else { return }
        updateBlock(&existing)
        setPreferences(existing)
    }

    func toggleGroceryItem(_ item: GroceryItem) {
        groceryItems = groceryItems.map { current in
            guard current.id == item.id else { return current }
            var modified = current
            modified.isChecked.toggle()
            return modified
        }
    }

    func updateMealPlan(_ plan: [MealPlanDay]) {
        weeklyPlan = plan
    }

    func removeGroceryItem(_ item: GroceryItem) {
        groceryItems.removeAll { $0.id == item.id }
    }

    func markNotificationRead(_ notification: AgentNotification) {
        notifications = notifications.map { current in
            guard current.id == notification.id else { return current }
            var updated = current
            updated.isRead = true
            return updated
        }
    }

    func resetOnboarding() {
        preferenceStore.reset()
        preferences = nil
    }
}
