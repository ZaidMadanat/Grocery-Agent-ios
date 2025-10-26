//
//  PreferencesViewModel.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import Combine
import Foundation

@MainActor
final class PreferencesViewModel: ObservableObject {
    @Published var draft: UserPreferences
    @Published var isSaving = false

    private let appModel: AppViewModel

    init(appModel: AppViewModel) {
        self.appModel = appModel
        self.draft = appModel.preferences ?? MockDataService.samplePreferences()
    }

    func saveUpdates() {
        isSaving = true
        Task {
            do {
                // Convert dietary restrictions to strings
                let dietaryRestrictionsStrings = draft.dietaryRestrictions.map { $0.rawValue.lowercased() }
                let allRestrictions = dietaryRestrictionsStrings + draft.customRestrictions
                
                // Convert macro priorities to grams
                // API expects grams, not percentages
                let calories = Double(draft.dailyCalorieGoal)
                let normalized = draft.macroPriorities.normalized
                
                let proteinGrams = (calories * normalized.protein) / 4.0  // 4 cal/g protein
                let carbsGrams = (calories * normalized.carbs) / 4.0      // 4 cal/g carbs
                let fatsGrams = (calories * normalized.fats) / 9.0        // 9 cal/g fats
                
                // Create API request
                let updateRequest = UpdateProfileRequest(
                    daily_calories: draft.dailyCalorieGoal,
                    dietary_restrictions: allRestrictions.isEmpty ? nil : allRestrictions,
                    likes: [], // Can be populated if we add likes to UserPreferences
                    additional_information: draft.customRestrictions.isEmpty ? nil : draft.customRestrictions.joined(separator: ", "),
                    target_protein_g: proteinGrams,
                    target_carbs_g: carbsGrams,
                    target_fat_g: fatsGrams
                )
                
                // Call API to update profile
                try await APIClient.shared.updateProfile(request: updateRequest)
                
                // Update local preferences after successful API call
                appModel.setPreferences(draft)
                
            } catch {
                print("Failed to update profile: \(error)")
                // Still update local preferences even if API fails
                appModel.setPreferences(draft)
            }
            
            isSaving = false
        }
    }

    func toggleMeal(_ meal: MealType) {
        if draft.mealTypes.contains(meal) {
            draft.mealTypes.remove(meal)
        } else {
            draft.mealTypes.insert(meal)
        }
    }

    func toggleRestriction(_ restriction: DietaryRestriction) {
        if draft.dietaryRestrictions.contains(restriction) {
            draft.dietaryRestrictions.removeAll { $0 == restriction }
        } else {
            draft.dietaryRestrictions.append(restriction)
        }
    }

    func updateCustomRestrictions(_ value: [String]) {
        draft.customRestrictions = value
    }
}
