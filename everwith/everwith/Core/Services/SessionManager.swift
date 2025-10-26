//
//  SessionManager.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import UIKit
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var isAppInBackground = false
    @Published var sessionExpired = false
    
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthenticationService
    
    // Optimization: Add debouncing and caching
    private var lastValidationTime: Date = Date.distantPast
    private var validationCooldown: TimeInterval = 30.0 // 30 seconds cooldown
    private var backgroundTime: Date?
    private var minimumBackgroundTime: TimeInterval = 60.0 // Only validate if backgrounded for >1min
    
    private init() {
        // Get the auth service instance
        self.authService = AuthenticationService()
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        // App going to background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.isAppInBackground = true
                self?.handleAppBackgrounded()
            }
            .store(in: &cancellables)
        
        // App coming to foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.isAppInBackground = false
                self?.handleAppForegrounded()
            }
            .store(in: &cancellables)
        
        // App becoming active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppBecameActive()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppBackgrounded() {
        print("App went to background - session validation paused")
        backgroundTime = Date()
    }
    
    private func handleAppForegrounded() {
        print("App came to foreground - checking if validation needed")
        Task {
            await validateSessionIfNeeded(reason: "foreground")
        }
    }
    
    private func handleAppBecameActive() {
        print("App became active - checking if validation needed")
        Task {
            await validateSessionIfNeeded(reason: "active")
        }
    }
    
    // MARK: - Optimized Session Validation
    
    /// Smart validation that avoids unnecessary /auth/me calls
    private func validateSessionIfNeeded(reason: String) async {
        let now = Date()
        
        // Check cooldown period
        if now.timeIntervalSince(lastValidationTime) < validationCooldown {
            print("⏭️ SESSION: Skipping validation - within cooldown period (\(reason))")
            return
        }
        
        // Check if app was backgrounded long enough to warrant validation
        if let backgroundTime = backgroundTime {
            let backgroundDuration = now.timeIntervalSince(backgroundTime)
            if backgroundDuration < minimumBackgroundTime {
                print("⏭️ SESSION: Skipping validation - backgrounded for only \(Int(backgroundDuration))s (\(reason))")
                return
            }
        }
        
        print("✅ SESSION: Proceeding with validation (\(reason))")
        lastValidationTime = now
        
        let isValid = await authService.validateSession()
        if !isValid {
            await MainActor.run {
                self.sessionExpired = true
            }
        }
    }
    
    func clearSessionExpired() {
        sessionExpired = false
    }
}
