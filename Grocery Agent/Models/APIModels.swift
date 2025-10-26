//
//  APIModels.swift
//  Grocery Agent
//

import Foundation

// MARK: - Recipe Generation Models

struct RecipeGenerationRequest: Codable {
    let user_profile: UserProfile
    let preferences: RecipePreferences
    
    struct UserProfile: Codable {
        let target_macros: TargetMacros
        let likes: [String]
        let dislikes: [String]
    }
    
    struct TargetMacros: Codable {
        let protein_g: Double
        let carbs_g: Double
        let fat_g: Double
        let calories: Int
    }
    
    struct RecipePreferences: Codable {
        let meal_type: String?
        let cuisine: String?
        let dietary_restrictions: String?
        let cook_time: String?
    }
}

struct RecipeGenerationResponse: Codable {
    let recipes: [APIRecipe]
    let message: String
    let next_action: String
    let tools_called: [String]
    let llm_provider: String
}

struct APIRecipe: Codable {
    let title: String
    let description: String
    let cook_time: String
    let prep_time: String
    let servings: Int
    let macros: RecipeMacros
    let ingredients: [RecipeIngredient]
    let instructions: String
    let image_url: String
    let cuisine: String?
    let difficulty: String?
    let tags: [String]
}

struct RecipeMacros: Codable {
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Int
}

struct RecipeIngredient: Codable {
    let name: String
    let quantity: Double
    let unit: String
    let notes: String?
}

// MARK: - Grocery List Models

struct GroceryListRequest: Codable {
    let recipe: GroceryRecipe
    let user_id: String?
    let store_preference: String
    
    struct GroceryRecipe: Codable {
        let title: String
        let ingredients: [GroceryIngredient]
        
        struct GroceryIngredient: Codable {
            let name: String
            let quantity: Double
            let unit: String
        }
    }
}

struct GroceryListFromRecipeRequest: Codable {
    let title: String
    let description: String
    let ingredients: [GroceryListIngredient]
    let servings: Int
    
    struct GroceryListIngredient: Codable {
        let name: String
        let quantity: Double
        let unit: String
    }
}

struct GroceryListResponse: Codable {
    let agent: String
    let list_id: Int
    let store: String
    let items: [APIGroceryItem]
    let total_estimated_cost: Double
    let kroger_items_found: Int
    let total_items: Int
    let message: String
    let order_url: String
    let next_action: String?
    let tools_called: [String]
    let llm_provider: String
}

struct GroceryListFromRecipeResponse: Codable {
    let agent: String
    let list_id: Int
    let store: String
    let items: [APIGroceryItem]
    let total_estimated_cost: Double
    let kroger_items_found: Int
    let total_items: Int
    let message: String
    let order_url: String
    let recipe_title: String
    let llm_provider: String
}

struct APIGroceryItem: Codable, Identifiable {
    let id: UUID = UUID()
    let name: String
    let description: String?
    let quantity: Double
    let unit: String
    let price_per_unit: Double?
    let total_price: Double?
    let image_url: String?
    let kroger_product_id: String?
    let category: String?
    let brand: String?
    let size: String?
    let available: Bool
    let source: String
}

// MARK: - Daily Meal Planning Models

struct DailyMealRequest: Codable {
    let day: String  // "Monday", "Tuesday", etc.
}

struct DailyMealResponse: Codable {
    let breakfast: MealDetail?
    let lunch: MealDetail?
    let dinner: MealDetail?
    let total_calories: Int
    let total_protein: Double
    let total_carbs: Double
    let total_fat: Double
    let macro_validation: MacroValidation?
}

struct MealDetail: Codable {
    let title: String
    let description: String
    let cook_time: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let ingredients: [RecipeIngredient]
    let instructions: String
}

struct MacroValidation: Codable {
    let status: String
    let message: String?
    let differences: MacroDifferences?
}

struct MacroDifferences: Codable {
    let protein_diff: Double
    let carbs_diff: Double
    let fat_diff: Double
    let calories_diff: Int
}

// MARK: - System Models

struct HealthCheckResponse: Codable {
    let status: String
    let message: String
    let version: String
    let agents: [String: String]
}

struct RootResponse: Codable {
    let name: String
    let version: String
    let description: String
    let features: [String]
    let agents: [String]
    let docs: String
    let health: String
}
