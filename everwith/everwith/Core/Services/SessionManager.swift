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
    }
    
    private func handleAppForegrounded() {
        print("App came to foreground - validating session")
        Task {
            await validateSessionOnForeground()
        }
    }
    
    private func handleAppBecameActive() {
        print("App became active - checking session validity")
        Task {
            await validateSessionOnActive()
        }
    }
    
    private func validateSessionOnForeground() async {
        let isValid = await authService.validateSession()
        if !isValid {
            await MainActor.run {
                self.sessionExpired = true
            }
        }
    }
    
    private func validateSessionOnActive() async {
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
