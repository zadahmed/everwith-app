//
//  OnboardingView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var permissionState: PermissionState = .notRequested
    @State private var onboardingState: OnboardingState = .cards
    @State private var showPermissionDeniedSheet = false
    @State private var showFilesPicker = false
    
    private let cards = OnboardingCard.cards
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.warmLinen.opacity(0.3),
                        Color.sky.opacity(0.1),
                        Color.honeyGold.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // iOS 26 Liquid Glass Header
                    LiquidGlassHeader()
                        .padding(.top, geometry.safeAreaInsets.top)
                    
                    // Main Content
                    TabView(selection: $currentPage) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                            OnboardingCardView(card: card)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.5), value: currentPage)
                    
                    // Bottom Section
                    VStack(spacing: ModernDesignSystem.Spacing.lg) {
                        // Page Indicators
                        HStack(spacing: ModernDesignSystem.Spacing.sm) {
                            ForEach(0..<cards.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPage ? Color.honeyGold : Color.charcoal.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                            }
                        }
                        .padding(.bottom, ModernDesignSystem.Spacing.sm)
                        
                        // Primary CTA Button
                        Button(action: {
                            if currentPage < cards.count - 1 {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentPage += 1
                                }
                            } else {
                                // Safe permission request
                                requestPhotoPermission()
                            }
                        }) {
                            HStack {
                                Text(currentPage < cards.count - 1 ? "Continue" : "Get started")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                
                                if currentPage < cards.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.charcoal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.honeyGold)
                            .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                            .shadow(
                                color: Color.honeyGold.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                        
                        // Skip Button (only on first two pages)
                        if currentPage < cards.count - 1 {
                            Button("Skip for now") {
                                skipOnboarding()
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.charcoal.opacity(0.6))
                            .padding(.bottom, ModernDesignSystem.Spacing.md)
                        }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + ModernDesignSystem.Spacing.lg)
                }
            }
        }
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showPermissionDeniedSheet) {
            PermissionDeniedSheet(
                onTryAgain: {
                    showPermissionDeniedSheet = false
                    requestPhotoPermission()
                },
                onUseFiles: {
                    showPermissionDeniedSheet = false
                    showFilesPicker = true
                }
            )
        }
        .sheet(isPresented: $showFilesPicker) {
            // Simple file picker placeholder
            VStack {
                Text("File Picker")
                    .font(.title)
                Text("This would open the file picker")
                    .foregroundColor(.secondary)
                Button("Close") {
                    showFilesPicker = false
                }
            }
            .padding()
        }
    }
    
    // MARK: - Private Methods
    private func requestPhotoPermission() {
        onboardingState = .requestingPermission
        
        // Check current authorization status first
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch currentStatus {
        case .authorized, .limited:
            // Already authorized, proceed
            permissionState = .granted
            onboardingState = .permissionGranted
            completeOnboarding()
        case .denied, .restricted:
            // Permission denied or restricted
            permissionState = .denied
            onboardingState = .permissionDenied
            showPermissionDeniedSheet = true
        case .notDetermined:
            // Request permission
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        permissionState = .granted
                        onboardingState = .permissionGranted
                        completeOnboarding()
                    case .denied:
                        permissionState = .denied
                        onboardingState = .permissionDenied
                        showPermissionDeniedSheet = true
                    case .restricted:
                        permissionState = .restricted
                        onboardingState = .permissionDenied
                        showPermissionDeniedSheet = true
                    case .notDetermined:
                        permissionState = .notRequested
                        onboardingState = .cards
                    @unknown default:
                        permissionState = .denied
                        onboardingState = .permissionDenied
                        showPermissionDeniedSheet = true
                    }
                }
            }
        @unknown default:
            // Handle unknown status
            permissionState = .denied
            onboardingState = .permissionDenied
            showPermissionDeniedSheet = true
        }
    }
    
    private func skipOnboarding() {
        // Skip onboarding and proceed to main app
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed and navigate to main app
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onboardingState = .completed
        
        // Post notification to update app state with delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
        }
        
        print("Onboarding completed!")
    }
}

// MARK: - Liquid Glass Header
struct LiquidGlassHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            // Status bar area with subtle glass effect
            Rectangle()
                .fill(Color.clear)
                .frame(height: 44)
                .background(
                    // Liquid glass effect that refracts wallpaper
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear,
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .background(.ultraThinMaterial)
                        .overlay(
                            // Subtle refraction effect
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.2),
                                            Color.clear
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                )
            
            // App branding area
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EverWith")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.charcoal)
                    
                    Text("Welcome to your journey")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.7))
                }
                
                Spacer()
                
                // Subtle logo
                Circle()
                    .fill(Color.brandGradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("EW")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.vertical, ModernDesignSystem.Spacing.md)
        }
    }
}

// MARK: - Onboarding Card View
struct OnboardingCardView: View {
    let card: OnboardingCard
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.xl) {
            Spacer()
            
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: card.gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: card.icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
            }
            .cleanGlassmorphism(
                style: ModernDesignSystem.GlassEffect.subtle,
                shadow: ModernDesignSystem.Shadow.light
            )
            
            // Content
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    Text(card.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                        .multilineTextAlignment(.center)
                    
                    Text(card.subtitle)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.charcoal.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Text(card.description)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            }
            .padding(ModernDesignSystem.Spacing.xl)
            .cleanGlassmorphism(
                style: ModernDesignSystem.GlassEffect.light,
                blur: ModernDesignSystem.BlurEffect.subtle,
                shadow: ModernDesignSystem.Shadow.subtle
            )
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            
            Spacer()
        }
    }
}

// MARK: - Permission Denied Sheet
struct PermissionDeniedSheet: View {
    let onTryAgain: () -> Void
    let onUseFiles: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.xl) {
            // Header
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.honeyGold)
                
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    Text("Photos Access Needed")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                        .multilineTextAlignment(.center)
                    
                    Text("To restore your precious memories, we need access to your photo library.")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(ModernDesignSystem.Spacing.xl)
            
            // Options
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                Button(action: onTryAgain) {
                    Text("Try Again")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.charcoal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.honeyGold)
                        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                }
                
                Button(action: onUseFiles) {
                    HStack {
                        Image(systemName: "folder")
                            .font(.system(size: 16, weight: .medium))
                        Text("Pick from Files")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.charcoal.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                            .stroke(Color.charcoal.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            
            Spacer()
        }
        .padding(.top, ModernDesignSystem.Spacing.xl)
        .background(Color.warmLinen)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    OnboardingView()
}
