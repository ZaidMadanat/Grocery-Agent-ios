//
//  DashboardViewModel.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedDayIndex: Int = 0
    @Published private(set) var week: [MealPlanDay] = []
    @Published private(set) var isRegenerating = false

    private let appModel: AppViewModel

    init(appModel: AppViewModel) {
        self.appModel = appModel
        week = appModel.weeklyPlan
        selectCurrentDay()
    }
    
    /// Select the current day (today) based on the week data
    private func selectCurrentDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find the index of today in the week array
        if let index = week.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            selectedDayIndex = index
        } else {
            // If today is not in the week, default to the first day
            selectedDayIndex = 0
        }
    }

    var selectedDay: MealPlanDay? {
        guard week.indices.contains(selectedDayIndex) else { return nil }
        return week[selectedDayIndex]
    }

    var dayLabels: [String] {
        week.map { DateFormatter.weekdayFormatter.string(from: $0.date) }
    }

    func refreshPlan() {
        guard !isRegenerating else { return }
        isRegenerating = true
        Task {
            do {
                // Fetch daily meals from API for each day of the week
                let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                var updatedWeek: [MealPlanDay] = []
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                
                for (index, dayName) in daysOfWeek.enumerated() {
                    // Calculate date for this day
                    guard let date = calendar.date(byAdding: .day, value: index, to: today) else {
                        continue
                    }
                    
                    // Fetch daily meals from API
                    do {
                        let response = try await APIClient.shared.generateDailyMeals(day: dayName)
                        let meals = convertAPIResponseToMealPlan(response: response, date: date)
                        updatedWeek.append(meals)
                    } catch {
                        // If API call fails, use empty meal plan with zero macros
                        print("Failed to fetch meals for \(dayName): \(error)")
                        updatedWeek.append(createEmptyMealPlanDay(date: date))
                    }
                }
                
                // Update the model with API data
                appModel.updateMealPlan(updatedWeek)
                week = updatedWeek
                
                // Re-select current day after refresh
                selectCurrentDay()
                
            } catch {
                print("Failed to refresh meal plan: \(error)")
                // Fallback to empty state on error
            }
            
            isRegenerating = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertAPIResponseToMealPlan(response: DailyMealResponse, date: Date) -> MealPlanDay {
        var meals: [MealType: Meal] = [:]
        var totalMacros = MacroBreakdown.zero
        
        // Convert breakfast
        if let breakfast = response.breakfast {
            let meal = Meal(
                type: .breakfast,
                name: breakfast.title,
                description: breakfast.description,
                calories: breakfast.calories,
                macros: MacroBreakdown(
                    calories: breakfast.calories,
                    protein: breakfast.protein,
                    carbs: breakfast.carbs,
                    fats: breakfast.fat
                )
            )
            meals[.breakfast] = meal
            totalMacros = addMacros(totalMacros, meal.macros)
        }
        
        // Convert lunch
        if let lunch = response.lunch {
            let meal = Meal(
                type: .lunch,
                name: lunch.title,
                description: lunch.description,
                calories: lunch.calories,
                macros: MacroBreakdown(
                    calories: lunch.calories,
                    protein: lunch.protein,
                    carbs: lunch.carbs,
                    fats: lunch.fat
                )
            )
            meals[.lunch] = meal
            totalMacros = addMacros(totalMacros, meal.macros)
        }
        
        // Convert dinner
        if let dinner = response.dinner {
            let meal = Meal(
                type: .dinner,
                name: dinner.title,
                description: dinner.description,
                calories: dinner.calories,
                macros: MacroBreakdown(
                    calories: dinner.calories,
                    protein: dinner.protein,
                    carbs: dinner.carbs,
                    fats: dinner.fat
                )
            )
            meals[.dinner] = meal
            totalMacros = addMacros(totalMacros, meal.macros)
        }
        
        // Use API totals if available, otherwise sum up our meals
        let finalMacros = MacroBreakdown(
            calories: totalMacros.calories,
            protein: totalMacros.protein,
            carbs: totalMacros.carbs,
            fats: totalMacros.fats
        )
        
        return MealPlanDay(
            date: date,
            meals: meals,
            macros: finalMacros
        )
    }
    
    private func addMacros(_ first: MacroBreakdown, _ second: MacroBreakdown) -> MacroBreakdown {
        MacroBreakdown(
            calories: first.calories + second.calories,
            protein: first.protein + second.protein,
            carbs: first.carbs + second.carbs,
            fats: first.fats + second.fats
        )
    }
    
    private func createEmptyMealPlanDay(date: Date) -> MealPlanDay {
        MealPlanDay(
            date: date,
            meals: [:],
            macros: MacroBreakdown.zero
        )
    }

    func meal(for type: MealType) -> Meal? {
        selectedDay?.meals[type]
    }

    func macroGoal(for macro: String) -> Double {
        guard let preferences = appModel.preferences else { return 0 }
        
        // Calculate macro goals in grams from percentages
        switch macro {
        case "protein":
            // Protein: goal % of calories / 4 (calories per gram)
            return (Double(preferences.dailyCalorieGoal) * preferences.macroPriorities.protein) / 4.0
        case "carbs":
            // Carbs: goal % of calories / 4 (calories per gram)
            return (Double(preferences.dailyCalorieGoal) * preferences.macroPriorities.carbs) / 4.0
        case "fats":
            // Fats: goal % of calories / 9 (calories per gram)
            return (Double(preferences.dailyCalorieGoal) * preferences.macroPriorities.fats) / 9.0
        default:
            return 0
        }
    }
}
