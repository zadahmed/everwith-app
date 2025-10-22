//
//  RestoreView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import Photos
import PhotosUI

struct RestoreView: View {
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var showPhotoPicker = false
    @State private var showingBefore = false
    @State private var showSaveSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Animation states
    @State private var animateElements = false
    @State private var headerScale: CGFloat = 0.9
    @State private var contentOpacity: Double = 0
    @State private var buttonPressed = false
    @State private var imageScale: CGFloat = 0.8
    @State private var progressRotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean White Background with Subtle Gradient Band
                CleanWhiteBackground()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea(.all, edges: .all)
                
                VStack(spacing: 0) {
                // Enhanced Header with Animation
                HStack {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                                .foregroundColor(.deepPlum)
                                .scaleEffect(buttonPressed ? 0.9 : 1.0)
                            
                            Text("Photo Restore")
                                .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                                .foregroundColor(.deepPlum)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(headerScale)
                    .opacity(animateElements ? 1 : 0)
                    .offset(x: animateElements ? 0 : -20)
                    
                    Spacer()
                }
                .padding(.horizontal, adaptivePadding(for: geometry))
                .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 28 : 38)
                .padding(.bottom, adaptiveSpacing(16, for: geometry))
                
                // Main Content
                if selectedImage == nil {
                    // Step 1: Enhanced Photo Selection
                    VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                        // Animated Icon
                        Image(systemName: "photo.badge.plus")
                            .font(.system(
                                size: adaptiveFontSize(64, for: geometry),
                                weight: .light
                            ))
                            .foregroundColor(.honeyGold.opacity(0.6))
                            .scaleEffect(imageScale)
                            .opacity(contentOpacity)
                            .offset(y: animateElements ? 0 : 30)
                        
                        // Animated Text
                        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            Text("Select a photo to restore")
                                .font(.system(
                                    size: adaptiveFontSize(20, for: geometry),
                                    weight: .semibold
                                ))
                                .foregroundColor(.shadowPlum)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .opacity(contentOpacity)
                                .offset(y: animateElements ? 0 : 20)
                            
                            Text("Upload an old photo and watch it transform into HD quality")
                                .font(.system(
                                    size: adaptiveFontSize(16, for: geometry),
                                    weight: .regular
                                ))
                                .foregroundColor(.softPlum)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                                .opacity(contentOpacity)
                                .offset(y: animateElements ? 0 : 20)
                        }
                        
                        // Enhanced Button with Animation
                        Button(action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                buttonPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showPhotoPicker = true
                                buttonPressed = false
                            }
                        }) {
                            HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                Text("Choose Photo")
                                    .font(.system(
                                        size: adaptiveFontSize(17, for: geometry),
                                        weight: .semibold
                                    ))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: adaptiveSize(280, for: geometry))
                            .frame(height: adaptiveSize(54, for: geometry))
                            .background(LinearGradient.primaryBrand)
                            .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                            .shadow(
                                color: Color.blushPink.opacity(buttonPressed ? 0.3 : 0.2),
                                radius: buttonPressed ? 8 : 12,
                                x: 0,
                                y: buttonPressed ? 4 : 6
                            )
                        }
                        .scaleEffect(buttonPressed ? 0.95 : 1.0)
                        .opacity(contentOpacity)
                        .offset(y: animateElements ? 0 : 20)
                        .padding(.top, adaptiveSpacing(16, for: geometry))
                        
                        Spacer()
                    }
                    .padding(.top, adaptiveSpacing(8, for: geometry))
                } else if processedImage == nil && !isProcessing {
                    // Step 2: Enhanced Preview & Restore
                    ScrollView {
                        VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                            // Enhanced Image Display
                            Image(uiImage: selectedImage!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: geometry.size.height * 0.5)
                                .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                .shadow(
                                    color: .black.opacity(0.15),
                                    radius: 15,
                                    x: 0,
                                    y: 8
                                )
                                .scaleEffect(imageScale)
                                .opacity(contentOpacity)
                                .padding(.horizontal, adaptivePadding(for: geometry))
                                .padding(.top, adaptiveSpacing(8, for: geometry))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: imageScale)
                            
                            VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                                // Enhanced Restore Button
                                Button(action: {
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        buttonPressed = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        restorePhoto()
                                        buttonPressed = false
                                    }
                                }) {
                                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(
                                                size: adaptiveFontSize(18, for: geometry),
                                                weight: .semibold
                                            ))
                                            .rotationEffect(.degrees(buttonPressed ? 10 : 0))
                                            .animation(.easeInOut(duration: 0.2), value: buttonPressed)
                                        
                                        Text("Restore Photo")
                                            .font(.system(
                                                size: adaptiveFontSize(17, for: geometry),
                                                weight: .semibold
                                            ))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: adaptiveSize(54, for: geometry))
                                    .background(LinearGradient.primaryBrand)
                                    .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                    .shadow(
                                        color: Color.blushPink.opacity(buttonPressed ? 0.4 : 0.2),
                                        radius: buttonPressed ? 12 : 16,
                                        x: 0,
                                        y: buttonPressed ? 6 : 8
                                    )
                                }
                                .scaleEffect(buttonPressed ? 0.96 : 1.0)
                                .opacity(contentOpacity)
                                .offset(y: animateElements ? 0 : 20)
                                
                                Button(action: { selectedImage = nil; showPhotoPicker = true }) {
                                    Text("Choose Different Photo")
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .medium
                                        ))
                                        .foregroundColor(.softPlum)
                                }
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                        }
                        .padding(.top, adaptiveSpacing(8, for: geometry))
                    }
                } else if isProcessing {
                    // Step 3: Enhanced Processing Animation
                    VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                        Spacer()
                        
                        // Enhanced Progress Circle
                        ZStack {
                            // Background circle with pulsing effect
                            Circle()
                                .stroke(Color.honeyGold.opacity(0.2), lineWidth: 8)
                                .frame(
                                    width: adaptiveSize(120, for: geometry),
                                    height: adaptiveSize(120, for: geometry)
                                )
                                .scaleEffect(1.0 + sin(progressRotation * .pi / 180) * 0.1)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: progressRotation)
                            
                            // Main progress circle
                            Circle()
                                .stroke(Color.honeyGold.opacity(0.3), lineWidth: 8)
                                .frame(
                                    width: adaptiveSize(100, for: geometry),
                                    height: adaptiveSize(100, for: geometry)
                                )
                            
                            // Animated progress ring
                            Circle()
                                .trim(from: 0, to: processingProgress)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.honeyGold,
                                            Color.honeyGold.opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(
                                    width: adaptiveSize(100, for: geometry),
                                    height: adaptiveSize(100, for: geometry)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: processingProgress)
                            
                            // Percentage text with scale animation
                            Text("\(Int(processingProgress * 100))%")
                                .font(.system(
                                    size: adaptiveFontSize(20, for: geometry),
                                    weight: .bold
                                ))
                                .foregroundColor(.shadowPlum)
                                .scaleEffect(processingProgress > 0 ? 1.0 : 0.8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: processingProgress)
                        }
                        
                        Text("Restoring your photo...")
                            .font(.system(
                                size: adaptiveFontSize(18, for: geometry),
                                weight: .semibold
                            ))
                            .foregroundColor(.shadowPlum)
                        
                        Text("This usually takes 10-30 seconds")
                            .font(.system(
                                size: adaptiveFontSize(14, for: geometry),
                                weight: .regular
                            ))
                            .foregroundColor(.shadowPlum.opacity(0.6))
                        
                        Spacer()
                    }
                } else if let processed = processedImage {
                    // Step 4: Enhanced Result Display
                    ScrollView {
                        VStack(spacing: adaptiveSpacing(20, for: geometry)) {
                            // Enhanced Image Display with Smooth Transitions
                            VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                // Animated Image with Better Transitions
                                ZStack {
                                    Image(uiImage: showingBefore ? selectedImage! : processed)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: geometry.size.height * 0.5)
                                        .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                        .shadow(
                                            color: .black.opacity(0.15),
                                            radius: 15,
                                            x: 0,
                                            y: 8
                                        )
                                        .scaleEffect(imageScale)
                                        .opacity(contentOpacity)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingBefore)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: imageScale)
                                        .padding(.top, adaptiveSpacing(4, for: geometry))
                                
                                // Status Badge
                                HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                    Image(systemName: showingBefore ? "photo" : "sparkles")
                                        .font(.system(
                                            size: adaptiveFontSize(14, for: geometry),
                                            weight: .semibold
                                        ))
                                    Text(showingBefore ? "Original Photo" : "Restored Photo")
                                        .font(.system(
                                            size: adaptiveFontSize(15, for: geometry),
                                            weight: .semibold
                                        ))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, adaptiveSpacing(16, for: geometry))
                                .padding(.vertical, adaptiveSpacing(8, for: geometry))
                                .background(
                                    Capsule()
                                        .fill(showingBefore ? Color.gray.opacity(0.7) : Color.honeyGold)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 4)
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                            .padding(.top, adaptiveSpacing(20, for: geometry))
                            
                            // Compare Toggle Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingBefore.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .semibold
                                        ))
                                    Text(showingBefore ? "Show Restored" : "Show Original")
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .semibold
                                        ))
                                }
                                .foregroundColor(.shadowPlum)
                                .frame(maxWidth: .infinity)
                                .frame(height: adaptiveSize(50, for: geometry))
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(adaptiveCornerRadius(14, for: geometry))
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                        
                            // Action Buttons
                            VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                Button(action: savePhoto) {
                                    HStack {
                                        Image(systemName: showSaveSuccess ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                                            .font(.system(
                                                size: adaptiveFontSize(18, for: geometry),
                                                weight: .semibold
                                            ))
                                        Text(showSaveSuccess ? "Saved!" : "Save to Photos")
                                            .font(.system(
                                                size: adaptiveFontSize(17, for: geometry),
                                                weight: .semibold
                                            ))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: adaptiveSize(54, for: geometry))
                                    .background(showSaveSuccess ? Color.green : Color.honeyGold)
                                    .cornerRadius(adaptiveCornerRadius(16, for: geometry))
                                }
                                .disabled(showSaveSuccess)
                                
                                HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                    Button(action: sharePhoto) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Share")
                                        }
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .medium
                                        ))
                                        .foregroundColor(.shadowPlum)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: adaptiveSize(50, for: geometry))
                                        .background(Color.white.opacity(0.7))
                                        .cornerRadius(adaptiveCornerRadius(14, for: geometry))
                                    }
                                    
                                    Button(action: { 
                                        selectedImage = nil
                                        processedImage = nil
                                        showingBefore = false
                                        showPhotoPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "photo.badge.plus")
                                            Text("New Photo")
                                        }
                                        .font(.system(
                                            size: adaptiveFontSize(16, for: geometry),
                                            weight: .medium
                                        ))
                                        .foregroundColor(.shadowPlum)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: adaptiveSize(50, for: geometry))
                                        .background(Color.white.opacity(0.7))
                                        .cornerRadius(adaptiveCornerRadius(14, for: geometry))
                                    }
                                }
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                            .padding(.bottom, max(geometry.safeAreaInsets.bottom, adaptiveSpacing(20, for: geometry)))
                        }
                        .padding(.top, adaptiveSpacing(8, for: geometry))
                    }
                }
                        }
            }
            .background(Color.softCream)
            .ignoresSafeArea(.all, edges: .all)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: Binding(
            get: { nil },
            set: { newValue in
                if let item = newValue {
                    loadPhoto(from: item)
                }
            }
        ), matching: .images)
        .onReceive(imageProcessingService.$processingProgress) { progress in
            if let p = progress {
                processingProgress = Double(p.currentStepIndex) / Double(p.totalSteps)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                clearError()
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                headerScale = 1.0
                animateElements = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                contentOpacity = 1.0
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.3)) {
                imageScale = 1.0
            }
            
            // Start progress rotation animation
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                progressRotation = 360
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadPhoto(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        }
    }
    
    private func restorePhoto() {
        guard let image = selectedImage else { return }
        
        Task {
            do {
                isProcessing = true
                
                let (result, originalImageUrl) = try await imageProcessingService.restorePhoto(
                    image: image,
                    qualityTarget: .standard,
                    outputFormat: .png,
                    aspectRatio: .original,
                    seed: nil
                )
                
                let restored = try await imageProcessingService.downloadProcessedImage(from: result.outputUrl)
                
                // Save to history
                do {
                    _ = try await imageProcessingService.saveToHistory(
                        imageType: "restore",
                        originalImageUrl: originalImageUrl,
                        processedImageUrl: result.outputUrl,
                        qualityTarget: "standard",
                        outputFormat: "png",
                        aspectRatio: "original"
                    )
                    print("✅ Image saved to history")
                } catch {
                    print("⚠️ Failed to save to history: \(error)")
                    // Don't fail the whole operation if history save fails
                }
                
                await MainActor.run {
                    processedImage = restored
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
                print("❌ Restore failed: \(error)")
            }
        }
    }
    
    private func clearError() {
        errorMessage = nil
        showError = false
    }
    
    private func savePhoto() {
        guard let image = processedImage else { return }
        
        // Haptic feedback for save action
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showSaveSuccess = true
        }
        
        // Success haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSaveSuccess = false
            }
        }
    }
    
    private func sharePhoto() {
        guard let image = processedImage else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Adaptive Sizing Functions (matching HomeView)
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(12, min(16, screenWidth * 0.04))
    }
    
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

#Preview {
    RestoreView()
}