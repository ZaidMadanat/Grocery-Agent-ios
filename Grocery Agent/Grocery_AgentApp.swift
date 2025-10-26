//
//  Grocery_AgentApp.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/25/25.
//

import SwiftUI

@main
struct Grocery_AgentApp: App {
    init() {
        // FOR TESTING: Uncomment to force logout and show landing page
        // APIClient.shared.logout()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
