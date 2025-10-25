//
//  Constants.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation

struct Constants {
    
    // MARK: - App Information
    struct App {
        static let name = "Everwith"
        static let tagline = "Together in every photo."
        static let bundleIdentifier = "com.matrix.everwith"
        static let version = "1.0.0"
    }
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://api.everwith.app"
        static let timeout: TimeInterval = 30.0
    }
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let currentUser = "current_user"
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let lastSyncDate = "last_sync_date"
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let short: Double = 0.2
        static let medium: Double = 0.3
        static let long: Double = 0.5
    }
    
    // MARK: - File Names
    struct Files {
        static let googleServiceInfo = "GoogleService-Info"
        static let appConfig = "AppConfig"
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToRestore = Notification.Name("navigateToRestore")
    static let navigateToTogether = Notification.Name("navigateToTogether")
}
