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
    
    private let onboardingCards = [
        OnboardingCardData(
            imageName: "OnboardingWelcome",
            title: "Welcome to Everwith",
            subtitle: "AI photo magic"
        ),
        OnboardingCardData(
            imageName: "OnboardingRestore",
            title: "Restore photos",
            subtitle: "Bring memories back"
        ),
        OnboardingCardData(
            imageName: "OnboardingTogether",
            title: "Create together",
            subtitle: "Merge loved ones"
        ),
        OnboardingCardData(
            imageName: "OnboardingPremium",
            title: "Premium features",
            subtitle: "Unlimited access"
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean background
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Status bar spacer
                    Spacer()
                        .frame(height: max(geometry.safeAreaInsets.top, 20) + 20)
                    
                    // Main Content
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Single Card Content
                        SingleOnboardingCard(
                            cardData: onboardingCards[currentCardIndex],
                            geometry: geometry
                        )
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: showContent)
                        
                        Spacer()
                        
                        // Action Section
                        VStack(spacing: 24) {
                            // Card Navigation
                            if currentCardIndex < onboardingCards.count - 1 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        currentCardIndex += 1
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Text("Next")
                                            .font(.system(size: 18, weight: .semibold))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                            .background(.ultraThinMaterial)
                                    )
                                }
                            }
                            
                            // Primary CTA Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    requestPhotoPermission()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.yellow)
                                        .shadow(
                                            color: Color.yellow.opacity(0.4),
                                            radius: 12,
                                            x: 0,
                                            y: 6
                                        )
                                )
                            }
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                            .padding(.horizontal, 32)
                            
                            // Footer Links
                            HStack(spacing: 24) {
                                Button("Privacy") {
                                    showPrivacyPolicy = true
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black.opacity(0.6))
                                
                                Text("•")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black.opacity(0.4))
                                
                                Button("Terms") {
                                    showTermsOfService = true
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black.opacity(0.6))
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20) + 32)
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
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

// MARK: - Single Onboarding Card
struct SingleOnboardingCard: View {
    let cardData: OnboardingCardData
    let geometry: GeometryProxy
    @State private var iconScale: CGFloat = 0.9
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Clean Image Focus
            Image(cardData.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .scaleEffect(iconScale)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            
            // Content
            VStack(spacing: 12) {
                Text(cardData.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(nil)
                    .opacity(textOpacity)
                
                Text(cardData.subtitle)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.black.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.8)
                    .opacity(textOpacity)
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                iconScale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.5).delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Files Picker View
struct FilesPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(spacing: 32) {
                    // Icon
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.yellow)
                    
                    VStack(spacing: 16) {
                        Text("No problem—use Files instead.")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineLimit(geometry.isSmallScreen ? 3 : 2)
                        
                        Text("Select photos from your Files app to restore them.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(geometry.isSmallScreen ? 4 : 3)
                    }
                    
                    Spacer()
                    
                    Button("Open Files") {
                        // Handle file picker
                        dismiss()
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.yellow)
                    )
                    .padding(.horizontal, 32)
                }
                .padding(32)
                .navigationTitle("Files")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Permission Denied Sheet
struct PermissionDeniedSheet: View {
    let onTryAgain: () -> Void
    let onUseFiles: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 24) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.yellow)
                        
                        VStack(spacing: 16) {
                            Text("Photos Access Needed")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .lineLimit(geometry.isSmallScreen ? 3 : 2)
                                .minimumScaleFactor(0.8)
                            
                            Text("To restore your precious memories, we need access to your photo library.")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.black.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .lineLimit(geometry.isSmallScreen ? 5 : 3)
                        }
                    }
                    .padding(.top, 32)
                    
                    Spacer()
                    
                    // Options
                    VStack(spacing: 16) {
                        Button(action: onTryAgain) {
                            Text("Try Again")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.yellow)
                                        .shadow(
                                            color: Color.yellow.opacity(0.3),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                        }
                        
                        Button(action: onUseFiles) {
                            HStack(spacing: 12) {
                                Image(systemName: "folder")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Pick from Files")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.black.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                .background(Color.white)
                .navigationTitle("Permission")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            onUseFiles() // Default to files if cancelled
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    OnboardingView()
}