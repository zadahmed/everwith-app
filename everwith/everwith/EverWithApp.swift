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
            .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
                hasCompletedOnboarding = true
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
    
    @ViewBuilder
    private var content: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
                .onAppear {
                    checkOnboardingStatus()
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 1.05))
                ))
        } else {
            switch authService.authenticationState {
            case .loading:
                LoadingView()
                    .onAppear {
                        // Ensure session is being validated
                        print("🔄 App loaded - checking for existing session...")
                    }
                    .transition(.opacity)
            case .authenticated(let user):
                MainTabView(user: user)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .unauthenticated:
                ModernAuthenticationView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            case .error(let message):
                GeometryReader { geometry in
                    ErrorView(
                        error: message,
                        onRetry: {
                            // Retry by setting to unauthenticated and letting user sign in again
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
    
    private func checkOnboardingStatus() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}