//
//  AppCoordinator.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import Foundation

@main
struct EverWithApp: App {
    init() {
        configureApp()
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoordinator()
        }
    }
    
    private func configureApp() {
        // Configure RevenueCat first
        RevenueCatConfig.shared.configure()
        
        // Configure global app appearance
        GlobalAppearance.configure()
        
        // Configure Google Sign In when SDK is added
        GoogleSignInConfig.configure()
        
        // Configure any other app-wide settings
        configureAppearance()
    }
    
    private func configureAppearance() {
        // Configure global app appearance if needed
        // This could include navigation bar styling, etc.
    }
}

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
    static let onboardingReset = Notification.Name("onboardingReset")
}

struct AppCoordinator: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var sessionManager = SessionManager.shared
    @State private var hasCompletedOnboarding = false
    @State private var showSessionExpiredAlert = false
    
    var body: some View {
        content
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: hasCompletedOnboarding)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: authService.authenticationState)
            .environmentObject(authService)
            .environmentObject(sessionManager)
            .onAppear {
                checkOnboardingStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
                hasCompletedOnboarding = true
                // Force check authentication state after onboarding completes
                // If user is not authenticated, they should see the auth screen
                print("📱 ONBOARDING COMPLETED: Checking auth state")
                Task {
                    // Give it a moment for state to update
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    // Force authentication check
                    await MainActor.run {
                        if case .loading = authService.authenticationState {
                            print("⚠️ AUTH STATE: Still loading, setting to unauthenticated")
                            authService.authenticationState = .unauthenticated
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .onboardingReset)) { _ in
                hasCompletedOnboarding = false
            }
            .onReceive(sessionManager.$sessionExpired) { expired in
                if expired {
                    showSessionExpiredAlert = true
                }
            }
            .alert("Session Expired", isPresented: $showSessionExpiredAlert) {
                Button("OK") {
                    sessionManager.clearSessionExpired()
                    // Force logout
                    Task {
                        await authService.signOut()
                    }
                }
            } message: {
                Text("Your session has expired. Please sign in again.")
            }
    }
    
    private func checkOnboardingStatus() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        print("📱 ONBOARDING: Status - \(hasCompletedOnboarding ? "completed" : "not completed")")
    }
    
    @ViewBuilder
    private var content: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
                .transition(.opacity)
        } else {
            switch authService.authenticationState {
            case .loading:
                LoadingView()
                    .onAppear {
                        print("🔄 App loaded - checking for existing session...")
                    }
                    .transition(.opacity)
            case .authenticated(let user):
                MainTabView(user: user)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .unauthenticated:
                ModernAuthenticationView()
                    .transition(.opacity)
            case .error(let message):
                GeometryReader { geometry in
                    ErrorView(
                        error: message,
                        onRetry: {
                            authService.authenticationState = .unauthenticated
                        },
                        onDismiss: {
                            authService.authenticationState = .unauthenticated
                        },
                        geometry: geometry
                    )
                    .transition(.opacity)
                }
            }
        }
    }
}