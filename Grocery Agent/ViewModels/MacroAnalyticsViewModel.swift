//
//  MacroAnalyticsViewModel.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import Combine
import Foundation

@MainActor
final class MacroAnalyticsViewModel: ObservableObject {
    @Published private(set) var weeklyPlan: [MealPlanDay]

    private let appModel: AppViewModel

    init(appModel: AppViewModel) {
        self.appModel = appModel
        self.weeklyPlan = appModel.weeklyPlan
    }

    struct MacroDataPoint: Identifiable {
        let id = UUID()
        let day: String
        let macro: MacroType
        let value: Double
    }

    enum MacroType: String, CaseIterable {
        case calories = "Calories"
        case protein = "Protein"
        case carbs = "Carbs"
        case fats = "Fats"

        var unit: String {
            switch self {
            case .calories: return "kcals"
            case .protein, .carbs, .fats: return "g"
            }
        }
    }

    func data(for macro: MacroType) -> [MacroDataPoint] {
        weeklyPlan.enumerated().map { index, day in
            let label = DateFormatter.weekdayFormatter.string(from: day.date)
            let value: Double = {
                switch macro {
                case .calories: return Double(day.macros.calories)
                case .protein: return day.macros.protein
                case .carbs: return day.macros.carbs
                case .fats: return day.macros.fats
                }
            }()

            return MacroDataPoint(day: label, macro: macro, value: value)
        }
    }

    func trend(for macro: MacroType) -> Double {
        let values = data(for: macro).map(\.value)
        guard let first = values.first, let last = values.last else { return 0 }
        return last - first
    }
}
