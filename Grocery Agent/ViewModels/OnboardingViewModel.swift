//
//  OnboardingViewModel.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome
        case dietary
        case caloriesAndMeals
        case macros
        case review

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .dietary: return "Dietary Preferences"
            case .caloriesAndMeals: return "Daily Goals"
            case .macros: return "Macro Focus"
            case .review: return "Review"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome: return "Meet your new grocery co-pilot."
            case .dietary: return "Tell us how you eat."
            case .caloriesAndMeals: return "Set your targets."
            case .macros: return "Fine-tune your macro focus."
            case .review: return "Confirm and launch."
            }
        }
    }

    @Published var step: Step = .welcome
    @Published var selectedRestrictions: Set<DietaryRestriction> = []
    @Published var otherRestrictionInput: String = ""
    @Published var customRestrictions: [String] = []
    @Published var dailyCalorieGoal: Double = 2100
    @Published var mealTypes: Set<MealType> = [.breakfast, .lunch, .dinner]
    @Published var macroFocus: MacroPriorities = .balanced
    @Published var showValidationError: Bool = false

    func advance() {
        guard canAdvance else {
            showValidationError = true
            return
        }

        showValidationError = false
        if let nextStep = Step(rawValue: step.rawValue + 1) {
            step = nextStep
        }
    }

    func goBack() {
        showValidationError = false
        if let previous = Step(rawValue: step.rawValue - 1) {
            step = previous
        }
    }

    var canAdvance: Bool {
        switch step {
        case .welcome:
            return true
        case .dietary:
            if selectedRestrictions.contains(.other) {
                return !parsedCustomRestrictions.isEmpty
            }
            return true
        case .caloriesAndMeals:
            return dailyCalorieGoal >= 1000 && !mealTypes.isEmpty
        case .macros:
            return macroFocus.protein > 0 || macroFocus.carbs > 0 || macroFocus.fats > 0
        case .review:
            return true
        }
    }

    var parsedCustomRestrictions: [String] {
        otherRestrictionInput
            .split(whereSeparator: { $0 == "," || $0 == ";" || $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func finalizePreferences() async throws -> UserPreferences {
        let normalizedMacro = macroFocus.normalized
        let dietarySelections = selectedRestrictions.filter { $0 != .other }
        
        // Send preferences to backend API
        let allRestrictions = Array(dietarySelections).map { $0.rawValue.lowercased() } + parsedCustomRestrictions
        let allLikes: [String] = [] // Can be populated from additional preferences in future
        
        let updateRequest = UpdateProfileRequest(
            daily_calories: Int(dailyCalorieGoal),
            dietary_restrictions: allRestrictions,
            likes: allLikes,
            additional_information: otherRestrictionInput.isEmpty ? nil : otherRestrictionInput,
            target_protein_g: normalizedMacro.protein,
            target_carbs_g: normalizedMacro.carbs,
            target_fat_g: normalizedMacro.fats
        )
        
        try await APIClient.shared.updateProfile(request: updateRequest)
        
        // Return local preferences after successful API update
        return UserPreferences(
            dietaryRestrictions: Array(dietarySelections),
            customRestrictions: parsedCustomRestrictions,
            dailyCalorieGoal: Int(dailyCalorieGoal),
            mealTypes: mealTypes,
            macroPriorities: normalizedMacro
        )
    }

    func toggleRestriction(_ restriction: DietaryRestriction) {
        if selectedRestrictions.contains(restriction) {
            selectedRestrictions.remove(restriction)
        } else {
            selectedRestrictions.insert(restriction)
        }

        if restriction != .other {
            showValidationError = false
        }
    }

    func toggleMealType(_ mealType: MealType) {
        if mealTypes.contains(mealType) {
            mealTypes.remove(mealType)
        } else {
            mealTypes.insert(mealType)
        }
    }

    func updateMacroFocus(protein: Double, carbs: Double, fats: Double) {
        macroFocus = MacroPriorities(protein: protein, carbs: carbs, fats: fats)
    }
}
