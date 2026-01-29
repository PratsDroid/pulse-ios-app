//
//  PulseApp.swift
//  Pulse
//
//  Created by Sonu on 1/27/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct PulseApp: App {
    init() {
        // Configure appearance for dark theme
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            WatchlistView()
        }
    }
    
    private func configureAppearance() {
        #if os(iOS)
        // Navigation bar appearance - supports both light and dark mode
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Background color will adapt based on system appearance
        appearance.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 1)
                : UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        }
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Tab bar appearance - supports both light and dark mode
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
                : UIColor.white
        }
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        #endif
    }
}
