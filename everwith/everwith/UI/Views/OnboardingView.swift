//
//  OnboardingView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import PhotosUI
import Foundation

// MARK: - Onboarding Card Data
struct OnboardingCardData {
    let imageName: String
    let title: String
    let subtitle: String
    let description: String
    let features: [String]
}

struct OnboardingView: View {
    @State private var permissionState: PermissionState = .notRequested
    @State private var onboardingState: OnboardingState = .cards
    @State private var showPermissionDeniedSheet = false
    @State private var showFilesPicker = false
    @State private var isAnimating = false
    @State private var showContent = false
    @State private var currentCardIndex = 0
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var headerScale: CGFloat = 0.9
    @State private var contentOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    
    private let onboardingCards = [
        OnboardingCardData(
            imageName: "OnboardingWelcome",
            title: "Welcome to Everwith",
            subtitle: "Where memories come alive",
            description: "Transform your precious photos with AI-powered magic. Restore faded memories and create beautiful moments together.",
            features: ["AI-powered restoration", "Professional quality", "Easy to use"]
        ),
        OnboardingCardData(
            imageName: "OnboardingRestore",
            title: "Restore Old Photos",
            subtitle: "Bring faded memories back to life",
            description: "Our advanced AI technology can restore damaged, faded, or low-quality photos to stunning clarity. See your memories in HD quality.",
            features: ["HD quality restoration", "Color enhancement", "Damage repair"]
        ),
        OnboardingCardData(
            imageName: "OnboardingTogether",
            title: "Create Together",
            subtitle: "Merge loved ones in one frame",
            description: "Combine photos of family members who were never photographed together. Create beautiful memories that never existed before.",
            features: ["Realistic merging", "Multiple styles", "Natural results"]
        ),
        OnboardingCardData(
            imageName: "OnboardingPremium",
            title: "Unlock Premium",
            subtitle: "Unlimited possibilities",
            description: "Get unlimited access to all features, priority processing, and exclusive styles. Start your journey with a free trial.",
            features: ["Unlimited processing", "Priority queue", "Premium styles"]
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Brand Background with Gradient
                CleanWhiteBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Status bar spacer
                    Spacer()
                        .frame(height: max(geometry.safeAreaInsets.top, 20))
                    
                    // Main Content
                    VStack(spacing: 0) {
                        // Progress Indicator with top padding
                        OnboardingProgressIndicator(
                            currentIndex: min(currentCardIndex, onboardingCards.count - 1),
                            totalCount: onboardingCards.count,
                            geometry: geometry
                        )
                        .padding(.horizontal, adaptivePadding(for: geometry))
                        .padding(.top, adaptiveSpacing(16, for: geometry))
                        .padding(.bottom, adaptiveSpacing(12, for: geometry))
                        
                        // Scrollable Cards
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    ForEach(0..<onboardingCards.count, id: \.self) { index in
                                        SingleOnboardingCard(
                                            cardData: onboardingCards[index],
                                            geometry: geometry
                                        )
                                        .id(index)
                                        .frame(width: geometry.size.width - (geometry.adaptivePadding() * 2))
                                    }
                                }
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentCardIndex)
                            }
                            .scrollTargetBehavior(.paging)
                            .disabled(true)
                            .onChange(of: currentCardIndex) { newIndex in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    proxy.scrollTo(newIndex, anchor: .center)
                                }
                            }
                        }
                        .frame(height: geometry.size.height * 0.65) // Increased to 65% of screen height
                        
                        Spacer()
                            .frame(height: adaptiveSpacing(8, for: geometry))
                        
                        // Action Section
                        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                            // Card Navigation
                            if currentCardIndex < onboardingCards.count - 1 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        if currentCardIndex < onboardingCards.count - 1 {
                                            currentCardIndex += 1
                                        }
                                    }
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }) {
                                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                        Text("Next")
                                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                                    }
                                    .foregroundColor(.deepPlum)
                                    .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                                    .padding(.vertical, adaptiveSpacing(10, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                            .fill(Color.pureWhite)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                                    .stroke(LinearGradient.cardGlow, lineWidth: 1)
                                            )
                                            .shadow(
                                                color: Color.cardShadow,
                                                radius: adaptiveSpacing(8, for: geometry),
                                                x: 0,
                                                y: adaptiveSpacing(2, for: geometry)
                                            )
                                    )
                                }
                            }
                            
                            // Primary CTA Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    requestPhotoPermission()
                                }
                            }) {
                                HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                    Text("Get Started")
                                        .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .bold, design: .rounded))
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .bold))
                                }
                                .foregroundColor(.pureWhite)
                                .frame(maxWidth: .infinity)
                                .frame(height: adaptiveSize(56, for: geometry))
                                .background(
                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                        .fill(LinearGradient.primaryBrand)
                                        .shadow(
                                            color: Color.blushPink.opacity(0.4),
                                            radius: adaptiveSpacing(12, for: geometry),
                                            x: 0,
                                            y: adaptiveSpacing(6, for: geometry)
                                        )
                                )
                            }
                            .scaleEffect(buttonScale)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: buttonScale)
                            .padding(.horizontal, adaptivePadding(for: geometry))
                            
                            // Footer Links
                            HStack(spacing: adaptiveSpacing(24, for: geometry)) {
                                Button("Privacy") {
                                    showPrivacyPolicy = true
                                }
                                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                .foregroundColor(.softPlum)
                                
                                Text("•")
                                    .font(.system(size: adaptiveFontSize(14, for: geometry)))
                                    .foregroundColor(.softPlum.opacity(0.4))
                                
                                Button("Terms") {
                                    showTermsOfService = true
                                }
                                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                .foregroundColor(.softPlum)
                            }
                            .padding(.bottom, adaptiveSpacing(8, for: geometry))
                        }
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20) + adaptiveSpacing(32, for: geometry))
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                headerScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
                contentOpacity = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                buttonScale = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
                isAnimating = true
            }
        }
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
            FilesPickerView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                Text("Privacy Policy")
                    .navigationTitle("Privacy Policy")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showTermsOfService) {
            NavigationStack {
                Text("Terms of Service")
                    .navigationTitle("Terms of Service")
                    .navigationBarTitleDisplayMode(.inline)
            }
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
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onboardingState = .completed
        

        // Clear any existing authentication state to force re-authentication
        // This ensures that even if there's a cached session, user goes through auth flow
        UserDefaults.standard.removeObject(forKey: "current_user")
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "token_expiry")
        
        print("🧹 ONBOARDING: Cleared any existing auth state")
        
        // Post notification to update app state with delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
        }
        
        print("✅ ONBOARDING: Completed and ready for authentication")
    }
    
    // MARK: - Adaptive Sizing Functions
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(12, min(16, screenWidth * 0.04))
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return base * scaleFactor
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return base * scaleFactor
    }
}

// MARK: - Single Onboarding Card
struct SingleOnboardingCard: View {
    let cardData: OnboardingCardData
    let geometry: GeometryProxy
    @State private var imageScale: CGFloat = 0.9
    @State private var imageOpacity: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        GeometryReader { cardGeometry in
            VStack(spacing: 0) {
                // Hero Image Section - Takes 65% of card space
                ZStack {
                    // Background glow effect
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blushPink.opacity(0.1),
                                    Color.roseMagenta.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: cardGeometry.size.width * 0.85, 
                               height: cardGeometry.size.width * 0.85)
                        .blur(radius: adaptiveSpacing(30, for: geometry))
                        .opacity(imageOpacity)
                    
                    // Main product image - Large and centered
                    Image(cardData.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: cardGeometry.size.width * 0.95, 
                               height: cardGeometry.size.width * 0.95)
                        .scaleEffect(imageScale)
                        .shadow(
                            color: Color.black.opacity(0.15),
                            radius: adaptiveSpacing(25, for: geometry),
                            x: 0,
                            y: adaptiveSpacing(10, for: geometry)
                        )
                        .opacity(imageOpacity)
                }
                .frame(width: cardGeometry.size.width)
                .frame(height: cardGeometry.size.height * 0.72)
                
                // Content Section - Takes only 28% of card space, super simple
                VStack(spacing: adaptiveSpacing(4, for: geometry)) {
                    // Title - Simple and short
                    Text(cardData.title)
                        .font(.system(size: adaptiveFontSize(24, for: geometry), weight: .bold, design: .rounded))
                        .foregroundColor(.deepPlum)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .opacity(textOpacity)
                        .padding(.horizontal, adaptiveSpacing(8, for: geometry))
                    
                    // Subtitle - Short
                    Text(cardData.subtitle)
                        .font(.system(size: adaptiveFontSize(15, for: geometry), weight: .medium))
                        .foregroundColor(.softPlum)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .opacity(textOpacity)
                        .padding(.horizontal, adaptiveSpacing(8, for: geometry))
                }
                .frame(width: cardGeometry.size.width)
                .frame(height: cardGeometry.size.height * 0.28)
            }
        }
        .padding(adaptiveSpacing(8, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: adaptiveCornerRadius(24, for: geometry))
                .fill(Color.pureWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(24, for: geometry))
                        .stroke(LinearGradient.cardGlow, lineWidth: 1)
                )
                .shadow(
                    color: Color.cardShadow,
                    radius: adaptiveSpacing(20, for: geometry),
                    x: 0,
                    y: adaptiveSpacing(8, for: geometry)
                )
        )
        .padding(.horizontal, adaptiveSpacing(16, for: geometry))
        .onAppear {
            // Staggered animations for maximum impact
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                imageScale = 1.0
                imageOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }
        }
    }
    
    // MARK: - Adaptive Functions
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Progress Indicator
struct OnboardingProgressIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(8, for: geometry)) {
            ForEach(0..<totalCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(2, for: geometry))
                    .fill(index <= currentIndex ? AnyShapeStyle(LinearGradient.primaryBrand) : AnyShapeStyle(Color.softPlum.opacity(0.3)))
                    .frame(height: adaptiveSize(4, for: geometry))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentIndex)
            }
        }
    }
    
    // MARK: - Adaptive Functions
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Files Picker View
struct FilesPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    CleanWhiteBackground()
                        .ignoresSafeArea()
                    
                    VStack(spacing: adaptiveSpacing(32, for: geometry)) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blushPink.opacity(0.1),
                                            Color.roseMagenta.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: adaptiveSize(120, for: geometry), height: adaptiveSize(120, for: geometry))
                            
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: adaptiveFontSize(50, for: geometry), weight: .medium))
                                .foregroundStyle(LinearGradient.primaryBrand)
                        }
                        
                        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                            Text("No problem—use Files instead.")
                                .font(.system(size: adaptiveFontSize(24, for: geometry), weight: .bold, design: .rounded))
                                .foregroundColor(.deepPlum)
                                .multilineTextAlignment(.center)
                                .lineLimit(geometry.isSmallScreen ? 3 : 2)
                                .minimumScaleFactor(0.8)
                            
                            Text("Select photos from your Files app to restore them.")
                                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .regular))
                                .foregroundColor(.softPlum)
                                .multilineTextAlignment(.center)
                                .lineLimit(geometry.isSmallScreen ? 4 : 3)
                                .minimumScaleFactor(0.9)
                        }
                        
                        Spacer()
                        
                        Button("Open Files") {
                            // Handle file picker
                            dismiss()
                        }
                        .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .bold, design: .rounded))
                        .foregroundColor(.pureWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: adaptiveSize(56, for: geometry))
                        .background(
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                .fill(LinearGradient.primaryBrand)
                                .shadow(
                                    color: Color.blushPink.opacity(0.4),
                                    radius: adaptiveSpacing(12, for: geometry),
                                    x: 0,
                                    y: adaptiveSpacing(6, for: geometry)
                                )
                        )
                        .padding(.horizontal, adaptivePadding(for: geometry))
                    }
                    .padding(adaptiveSpacing(32, for: geometry))
                }
                .navigationTitle("Files")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.deepPlum)
                    }
                }
            }
        }
    }
    
    // MARK: - Adaptive Functions
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(12, min(16, screenWidth * 0.04))
    }
}

// MARK: - Permission Denied Sheet
struct PermissionDeniedSheet: View {
    let onTryAgain: () -> Void
    let onUseFiles: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    CleanWhiteBackground()
                        .ignoresSafeArea()
                    
                    VStack(spacing: adaptiveSpacing(32, for: geometry)) {
                        // Header
                        VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blushPink.opacity(0.1),
                                                Color.roseMagenta.opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: adaptiveSize(120, for: geometry), height: adaptiveSize(120, for: geometry))
                                
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: adaptiveFontSize(50, for: geometry), weight: .medium))
                                    .foregroundStyle(LinearGradient.primaryBrand)
                            }
                            
                            VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                                Text("Photos Access Needed")
                                    .font(.system(size: adaptiveFontSize(28, for: geometry), weight: .bold, design: .rounded))
                                    .foregroundColor(.deepPlum)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(geometry.isSmallScreen ? 3 : 2)
                                    .minimumScaleFactor(0.8)
                                
                                Text("To restore your precious memories, we need access to your photo library.")
                                    .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .regular))
                                    .foregroundColor(.softPlum)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(adaptiveSpacing(4, for: geometry))
                                    .lineLimit(geometry.isSmallScreen ? 5 : 3)
                                    .minimumScaleFactor(0.9)
                            }
                        }
                        .padding(.top, adaptiveSpacing(32, for: geometry))
                        
                        Spacer()
                        
                        // Options
                        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                            Button(action: onTryAgain) {
                                Text("Try Again")
                                    .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .bold, design: .rounded))
                                    .foregroundColor(.pureWhite)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: adaptiveSize(56, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                            .fill(LinearGradient.primaryBrand)
                                            .shadow(
                                                color: Color.blushPink.opacity(0.4),
                                                radius: adaptiveSpacing(12, for: geometry),
                                                x: 0,
                                                y: adaptiveSpacing(6, for: geometry)
                                            )
                                    )
                            }
                            
                            Button(action: onUseFiles) {
                                HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                    Image(systemName: "folder")
                                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                    Text("Pick from Files")
                                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
                                }
                                .foregroundColor(.deepPlum)
                                .frame(maxWidth: .infinity)
                                .frame(height: adaptiveSize(48, for: geometry))
                                .background(Color.pureWhite)
                                .overlay(
                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                        .stroke(LinearGradient.cardGlow, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, adaptivePadding(for: geometry))
                        .padding(.bottom, adaptiveSpacing(32, for: geometry))
                    }
                }
                .navigationTitle("Permission")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            onUseFiles() // Default to files if cancelled
                        }
                        .foregroundColor(.deepPlum)
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Adaptive Functions
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(12, min(16, screenWidth * 0.04))
    }
}

#Preview {
    OnboardingView()
}