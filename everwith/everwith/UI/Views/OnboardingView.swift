//
//  OnboardingView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @State private var permissionState: PermissionState = .notRequested
    @State private var onboardingState: OnboardingState = .cards
    @State private var showPermissionDeniedSheet = false
    @State private var showFilesPicker = false
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Elegant background with depth
                ElegantBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Status bar spacer
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 20)
                    
                    // Main Content
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Single Card Content
                        SingleOnboardingCard()
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: showContent)
                        
                        Spacer()
                        
                        // Action Section
                        VStack(spacing: 24) {
                            // Primary CTA Button
                            Button(action: {
                                requestPhotoPermission()
                            }) {
                                HStack(spacing: 12) {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.charcoal)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.honeyGold)
                                        .shadow(
                                            color: Color.honeyGold.opacity(0.4),
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
                                    // Handle privacy action
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.charcoal.opacity(0.6))
                                
                                Text("•")
                                    .font(.system(size: 14))
                                    .foregroundColor(.charcoal.opacity(0.4))
                                
                                Button("Terms") {
                                    // Handle terms action
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.charcoal.opacity(0.6))
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 32)
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

// MARK: - Elegant Background
struct ElegantBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.warmLinen.opacity(0.4),
                    Color.sky.opacity(0.15),
                    Color.honeyGold.opacity(0.08)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: animateGradient)
            
            // Floating orbs for depth
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.honeyGold.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: CGFloat(120 + index * 40), height: CGFloat(120 + index * 40))
                    .offset(
                        x: CGFloat(50 + index * 80),
                        y: CGFloat(-100 + index * 150)
                    )
                    .blur(radius: 20)
                    .opacity(0.6)
            }
        }
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Single Onboarding Card
struct SingleOnboardingCard: View {
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            // Hero Icon with Animation
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.honeyGold.opacity(0.3),
                                Color.honeyGold.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                // Main icon container
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.honeyGold,
                                Color.honeyGold.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
                    .shadow(
                        color: Color.honeyGold.opacity(0.4),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            }
            
            // Content
            VStack(spacing: 20) {
                Text("Restore precious photos.")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                
                Text("Keep control of what you share.")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.charcoal.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 30,
            x: 0,
            y: 15
        )
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                iconScale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.6).delay(0.5)) {
                textOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(1.0)) {
                iconRotation = 5
            }
        }
    }
}

// MARK: - Files Picker View
struct FilesPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Icon
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.honeyGold)
                
                VStack(spacing: 16) {
                    Text("No problem—use Files instead.")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.charcoal)
                        .multilineTextAlignment(.center)
                    
                    Text("Select photos from your Files app to restore them.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                Button("Open Files") {
                    // Handle file picker
                    dismiss()
                }
                .buttonStyle(ModernButtonStyle(style: .primary, size: .large))
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

// MARK: - Permission Denied Sheet
struct PermissionDeniedSheet: View {
    let onTryAgain: () -> Void
    let onUseFiles: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 24) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.honeyGold)
                    
                    VStack(spacing: 16) {
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
                .padding(.top, 32)
                
                Spacer()
                
                // Options
                VStack(spacing: 16) {
                    Button(action: onTryAgain) {
                        Text("Try Again")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.charcoal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.honeyGold)
                                    .shadow(
                                        color: Color.honeyGold.opacity(0.3),
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
                        .foregroundColor(.charcoal.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.charcoal.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(Color.warmLinen)
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

#Preview {
    OnboardingView()
}
