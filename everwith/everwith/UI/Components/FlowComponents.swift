//
//  FlowComponents.swift
//  EverWith
//
//  Reusable components for Photo Restore and Memory Merge flows
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - Continue Button Component
struct ContinueButton: View {
    let onContinue: () -> Void
    let creditCost: Int
    let isPremium: Bool
    let isEnabled: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: onContinue) {
            HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                if !isPremium {
                    // Show credit cost for free users
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: adaptiveFontSize(14, for: geometry)))
                        Text("\(creditCost)")
                            .font(.system(size: adaptiveFontSize(17, for: geometry), weight: .semibold))
                    }
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.5))
                }
                
                Text("Continue")
                    .font(.system(size: adaptiveFontSize(17, for: geometry), weight: .semibold))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
            }
            .foregroundColor(isEnabled ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: adaptiveSize(56, for: geometry))
            .background(isEnabled ? LinearGradient.primaryBrand : LinearGradient.cardGlow)
            .cornerRadius(adaptiveCornerRadius(16, for: geometry))
            .shadow(color: isEnabled ? Color.blushPink.opacity(0.3) : Color.gray.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Upload Card Component
struct UploadCard: View {
    let label: String
    let image: UIImage?
    let onTap: () -> Void
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .foregroundColor(.subtleBorder)
                    .background(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                            .fill(Color.pureWhite)
                    )
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry)))
                } else {
                    VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: adaptiveFontSize(40, for: geometry), weight: .light))
                            .foregroundStyle(LinearGradient.primaryBrand)
                        
                        Text(label)
                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                            .foregroundColor(.softPlum)
                            .multilineTextAlignment(.center)
                    }
                    .padding(adaptiveSpacing(20, for: geometry))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Progress Animation Component
struct ProgressAnimation: View {
    let title: String
    let subtitle: String
    let progress: Double
    let geometry: GeometryProxy
    let isQueueMode: Bool
    let queueTimeRemaining: Int
    let onPremiumTap: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -200
    @State private var dotOffset1: Double = 0
    @State private var dotOffset2: Double = 0
    @State private var dotOffset3: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.warmLinen.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main Animation Container
                VStack(spacing: adaptiveSpacing(32, for: geometry)) {
                    // Modern Circular Progress Container
                    ZStack {
                        // Outer static circle (background)
                        Circle()
                            .stroke(
                                Color.gray.opacity(0.15),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: adaptiveSize(120, for: geometry), height: adaptiveSize(120, for: geometry))
                        
                        // Animated circular progress
                        Circle()
                            .trim(from: 0, to: max(progress, 0.02))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blushPink, Color.roseMagenta]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: adaptiveSize(120, for: geometry), height: adaptiveSize(120, for: geometry))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: progress)
                        
                        // Pulsing background
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.blushPink.opacity(0.15),
                                        Color.roseMagenta.opacity(0.05)
                                    ]),
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 60
                                )
                            )
                            .frame(width: adaptiveSize(100, for: geometry), height: adaptiveSize(100, for: geometry))
                            .scaleEffect(pulseScale)
                        
                        // App logo
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: adaptiveSize(50, for: geometry), height: adaptiveSize(50, for: geometry))
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .frame(height: adaptiveSize(160, for: geometry))
                    
                    // Dynamic Loading Text
                    VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                        Text(title)
                            .font(.system(size: adaptiveFontSize(28, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                            .multilineTextAlignment(.center)
                        
                        // Stage indicator with icon
                        HStack(spacing: 8) {
                            Image(systemName: isQueueMode ? "clock.fill" : "checkmark.circle.fill")
                                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                .foregroundColor(isQueueMode ? .orange : .blushPink)
                            
                            Text(subtitle)
                                .font(.system(size: adaptiveFontSize(17, for: geometry), weight: .medium))
                                .foregroundColor(isQueueMode ? .deepPlum : .softPlum)
                        }
                        .transition(.opacity.combined(with: .scale))
                        
                        // Animated dots (always visible for feedback)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.blushPink)
                                .frame(width: 6, height: 6)
                                .offset(y: dotOffset1)
                            Circle()
                                .fill(Color.roseMagenta)
                                .frame(width: 6, height: 6)
                                .offset(y: dotOffset2)
                            Circle()
                                .fill(Color.blushPink)
                                .frame(width: 6, height: 6)
                                .offset(y: dotOffset3)
                        }
                        .padding(.top, 4)
                    }
                    
                    // Progress Section
                    VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                        // Modern Progress Bar
                        GeometryReader { progressGeometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.12))
                                    .frame(height: 6)
                                
                                // Progress fill with gradient
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blushPink, Color.roseMagenta]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: progressGeometry.size.width * CGFloat(max(progress, 0.05)), height: 6)
                                    .overlay(
                                        // Shimmer effect
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        .clear,
                                                        .white.opacity(0.5),
                                                        .clear
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .offset(x: shimmerOffset)
                                    )
                            }
                        }
                        .frame(height: 6)
                        .frame(width: adaptiveSize(280, for: geometry))
                        
                        // Progress info
                        if !isQueueMode && progress > 0 {
                            HStack(spacing: 8) {
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: adaptiveFontSize(15, for: geometry), weight: .semibold))
                                    .foregroundColor(.blushPink)
                                
                                Circle()
                                    .fill(Color.blushPink.opacity(0.3))
                                    .frame(width: 3, height: 3)
                                
                                Text("Processing")
                                    .font(.system(size: adaptiveFontSize(15, for: geometry), weight: .medium))
                                    .foregroundColor(.softPlum.opacity(0.7))
                            }
                        }
                    }
                    
                    // Queue Mode UI (subtle and inline)
                    if isQueueMode {
                        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            Text("Estimated time: \(queueTimeRemaining)s")
                                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                .foregroundColor(.orange)
                            
                            // Subtle premium suggestion
                            Button(action: onPremiumTap) {
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Skip the wait")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.orange)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, adaptiveSpacing(30, for: geometry))
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
        
        // Shimmer animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
        
        // Dot bouncing animation
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.0)) {
            dotOffset1 = -4
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2)) {
            dotOffset2 = -4
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4)) {
            dotOffset3 = -4
        }
    }
}

// MARK: - Result Action Buttons Component
struct ResultActionButtons: View {
    let onSave: () -> Void
    let onShare: () -> Void
    let onTryAnother: () -> Void
    let geometry: GeometryProxy
    let isSaved: Bool
    
    var body: some View {
        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
            // Save Button
            Button(action: onSave) {
                HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                    Image(systemName: isSaved ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .semibold))
                    Text(isSaved ? "Saved!" : "Save Photo")
                        .font(.system(size: adaptiveFontSize(17, for: geometry), weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: adaptiveSize(56, for: geometry))
                .background(isSaved ? LinearGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient.primaryBrand)
                .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                .shadow(color: Color.blushPink.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isSaved)
            
            // Share Buttons Row
            HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                Button(action: onShare) {
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                        Text("Share")
                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                    }
                    .foregroundColor(.deepPlum)
                    .frame(maxWidth: .infinity)
                    .frame(height: adaptiveSize(50, for: geometry))
                    .background(Color.pureWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
                            .stroke(LinearGradient.cardGlow, lineWidth: 1.5)
                    )
                    .cornerRadius(adaptiveCornerRadius(14, for: geometry))
                }
                
                Button(action: onTryAnother) {
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                        Text("Try Another")
                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                    }
                    .foregroundColor(.deepPlum)
                    .frame(maxWidth: .infinity)
                    .frame(height: adaptiveSize(50, for: geometry))
                    .background(Color.pureWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
                            .stroke(LinearGradient.cardGlow, lineWidth: 1.5)
                    )
                    .cornerRadius(adaptiveCornerRadius(14, for: geometry))
                }
            }
        }
        .padding(.horizontal, adaptiveSpacing(20, for: geometry))
            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
    }
}

// MARK: - Before/After Toggle Button Component
struct BeforeAfterToggleButton: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    let geometry: GeometryProxy
    
    @State private var showingBefore: Bool = false
    
    var body: some View {
        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
            // Image display
            ZStack {
                // Show appropriate image based on state
                Image(uiImage: showingBefore ? beforeImage : afterImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                
                // Label overlay
                VStack {
                    HStack {
                        Spacer()
                        Text(showingBefore ? "Before" : "After")
                            .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(12)
                    }
                    Spacer()
                }
            }
            .frame(maxHeight: .infinity)
            
            // Toggle button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingBefore.toggle()
                }
            }) {
                HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                    Image(systemName: showingBefore ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                    
                    Text(showingBefore ? "Show After" : "Show Before")
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: adaptiveSize(50, for: geometry))
                .background(
                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
                        .fill(LinearGradient.primaryBrand)
                )
                .shadow(color: Color.blushPink.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
        }
    }
}

