//
//  AppCoordinator.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

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

struct AppCoordinator: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var sessionManager = SessionManager.shared
    @State private var hasCompletedOnboarding = false
    @State private var showRestoreView = false
    @State private var showTogetherView = false
    @State private var showExportView = false
    @State private var showSessionExpiredAlert = false
    
    var body: some View {
        Group {
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
                    HomeView(user: user)
                        .onReceive(NotificationCenter.default.publisher(for: .navigateToRestore)) { _ in
                            showRestoreView = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .navigateToTogether)) { _ in
                            showTogetherView = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .navigateToExport)) { _ in
                            showExportView = true
                        }
                        .sheet(isPresented: $showRestoreView) {
                            RestoreView()
                        }
                        .sheet(isPresented: $showTogetherView) {
                            TogetherSceneView()
                        }
                        .sheet(isPresented: $showExportView) {
                            ExportView()
                        }
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
                    ErrorView(message: message) {
                        authService.authenticationState = .unauthenticated
                    }
                    .transition(.opacity)
                }
            }
        }
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
    
    private func checkOnboardingStatus() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}