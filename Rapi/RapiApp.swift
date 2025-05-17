//
//  RapiApp.swift
//  Rapi
//
//  Created by mario on 17/5/25.
//

import SwiftUI

// ThemeSetting enum moved to Models/ThemeSetting.swift

@main
struct RapiApp: App {
    @AppStorage("themeSetting") private var themeSetting: ThemeSetting = .system
    
    // Initialize the shared data cache service
    @StateObject private var dataCacheService = DataCacheService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeSetting.toColorScheme())
                .environmentObject(dataCacheService)
                .onAppear {
                    // Set a system-wide accent color (this is optional)
                    UINavigationBar.appearance().tintColor = UIColor.systemBlue
                }
        }
    }
}
