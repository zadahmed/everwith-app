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
    
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -200
    @State private var dotOffset1: Double = 0
    @State private var dotOffset2: Double = 0
    @State private var dotOffset3: Double = 0
    @State private var currentStage = 0
    
    let loadingStages = [
        "Analyzing your photo…",
        "Detecting facial features…",
        "Applying AI enhancement…",
        "Adding final touches…"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.warmLinen.opacity(0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main Animation Container
                VStack(spacing: adaptiveSpacing(40, for: geometry)) {
                    // Enhanced Animated Logo Container
                    ZStack {
                        // Outer rotating gradient ring
                        Circle()
                            .trim(from: 0.25, to: 1.0)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [Color.blushPink, Color.roseMagenta, Color.blushPink]),
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: adaptiveSize(140, for: geometry), height: adaptiveSize(140, for: geometry))
                            .rotationEffect(.degrees(rotationAngle))
                            .blur(radius: 2)
                            .shadow(color: .blushPink.opacity(0.3), radius: 10)
                        
                        // Middle rotating circle (faster)
                        Circle()
                            .trim(from: 0.5, to: 1.0)
                            .stroke(
                                LinearGradient.primaryBrand,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: adaptiveSize(110, for: geometry), height: adaptiveSize(110, for: geometry))
                            .rotationEffect(.degrees(rotationAngle * 1.5))
                        
                        // Inner pulsing circle with gradient
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.blushPink,
                                        Color.roseMagenta
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 50
                                )
                            )
                            .frame(width: adaptiveSize(100, for: geometry), height: adaptiveSize(100, for: geometry))
                            .scaleEffect(pulseScale)
                            .opacity(0.8)
                            .blur(radius: 8)
                        
                        // App logo with shadow
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: adaptiveSize(60, for: geometry), height: adaptiveSize(60, for: geometry))
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .frame(height: adaptiveSize(180, for: geometry))
                    
                    // Dynamic Loading Text
                    VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                        Text(title)
                            .font(.system(size: adaptiveFontSize(26, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                            .multilineTextAlignment(.center)
                            .id("title-\(currentStage)")
                        
                        HStack(spacing: 4) {
                            // Animated dots
                            Circle()
                                .fill(Color.blushPink)
                                .frame(width: 8, height: 8)
                                .offset(y: dotOffset1)
                            Circle()
                                .fill(Color.roseMagenta)
                                .frame(width: 8, height: 8)
                                .offset(y: dotOffset2)
                            Circle()
                                .fill(Color.blushPink)
                                .frame(width: 8, height: 8)
                                .offset(y: dotOffset3)
                        }
                        .padding(.top, 4)
                        
                        // Subtle subtitle
                        Text(subtitle)
                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .regular))
                            .foregroundColor(.softPlum.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, adaptiveSpacing(50, for: geometry))
                            .lineSpacing(4)
                    }
                    
                    // Modern Progress Bar
                    if progress > 0 {
                        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            // Animated progress bar with gradient
                            GeometryReader { progressGeometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 8)
                                    
                                    // Progress fill with gradient
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blushPink, Color.roseMagenta]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: progressGeometry.size.width * CGFloat(progress), height: 8)
                                        .overlay(
                                            // Shimmer effect
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            .clear,
                                                            .white.opacity(0.4),
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
                            .frame(height: 8)
                            .frame(width: adaptiveSize(280, for: geometry))
                            
                            // Progress percentage with animation
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                                .foregroundColor(.blushPink)
                        }
                        .padding(.top, adaptiveSpacing(8, for: geometry))
                    } else {
                        // Initial loading state
                        VStack(spacing: 8) {
                            Text("Preparing…")
                                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                .foregroundColor(.softPlum.opacity(0.6))
                        }
                        .padding(.top, adaptiveSpacing(8, for: geometry))
                    }
                }
                .padding(.horizontal, adaptiveSpacing(30, for: geometry))
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: progress) { newProgress in
            updateStage(for: newProgress)
        }
    }
    
    private func startAnimations() {
        // Continuous rotation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
        
        // Shimmer animation - loop from -200 to 400 and reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
        
        // Dot bouncing animation
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.0)) {
            dotOffset1 = -6
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2)) {
            dotOffset2 = -6
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4)) {
            dotOffset3 = -6
        }
    }
    
    private func updateStage(for progress: Double) {
        let newStage = Int(progress * Double(loadingStages.count))
        if newStage != currentStage && newStage < loadingStages.count {
            currentStage = newStage
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

// MARK: - Before/After Slider Component
struct BeforeAfterSlider: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    let geometry: GeometryProxy
    
    @State private var sliderPosition: CGFloat = 0.5
    
    var body: some View {
        GeometryReader { imageGeometry in
            ZStack {
                // After image (full)
                Image(uiImage: afterImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: imageGeometry.size.width)
                
                // Before image (masked)
                Image(uiImage: beforeImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: imageGeometry.size.width)
                    .mask(
                        Rectangle()
                            .frame(width: imageGeometry.size.width * sliderPosition)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
                
                // Before label
                if sliderPosition > 0.15 {
                    VStack {
                        HStack {
                            Text("Before")
                                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(12)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                // After label
                if sliderPosition < 0.85 {
                    VStack {
                        HStack {
                            Spacer()
                            Text("After")
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
                
                // Slider handle
                VStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 3)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.3), radius: 8)
                                .overlay(
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 12, weight: .bold))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(.deepPlum)
                                )
                        )
                }
                .frame(width: 44)
                .offset(x: imageGeometry.size.width * sliderPosition - imageGeometry.size.width / 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newPosition = (value.location.x / imageGeometry.size.width)
                            sliderPosition = min(max(newPosition, 0), 1)
                        }
                )
            }
        }
    }
}

