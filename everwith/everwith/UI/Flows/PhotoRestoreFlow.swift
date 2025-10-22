//
//  PhotoRestoreFlow.swift
//  EverWith
//
//  Photo Restore Mode Flow
//  Flow: Upload → Processing → Result
//

import SwiftUI
import PhotosUI

// MARK: - Photo Restore Flow Coordinator
struct PhotoRestoreFlow: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    
    @State private var currentStep: RestoreStep = .upload
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var originalImageUrl: String?
    @State private var processedImageUrl: String?
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var errorMessage: String?
    @State private var showError = false
    
    enum RestoreStep {
        case upload
        case processing
        case result
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CleanWhiteBackground()
                    .ignoresSafeArea(.all)
                
                switch currentStep {
                case .upload:
                    RestoreUploadView(
                        selectedImage: $selectedImage,
                        onContinue: { startProcessing() },
                        onDismiss: { dismiss() },
                        geometry: geometry
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                          removal: .move(edge: .leading).combined(with: .opacity)))
                    
                case .processing:
                    RestoreProcessingView(
                        progress: processingProgress,
                        geometry: geometry
                    )
                    .transition(.opacity)
                    
                case .result:
                    if let original = selectedImage, let processed = processedImage {
                        RestoreResultView(
                            beforeImage: original,
                            afterImage: processed,
                            onSave: { savePhoto() },
                            onShare: { sharePhoto() },
                            onTryAnother: { resetFlow() },
                            onDismiss: { dismiss() },
                            geometry: geometry
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                              removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                errorMessage = nil
                currentStep = .upload
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onReceive(imageProcessingService.$processingProgress) { progress in
            if let p = progress {
                processingProgress = Double(p.currentStepIndex) / Double(p.totalSteps)
            }
        }
    }
    
    private func startProcessing() {
        guard let image = selectedImage else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = .processing
        }
        
        Task {
            do {
                isProcessing = true
                
                let (result, originalUrl) = try await imageProcessingService.restorePhoto(
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
                        originalImageUrl: originalUrl,
                        processedImageUrl: result.outputUrl,
                        qualityTarget: "standard",
                        outputFormat: "png",
                        aspectRatio: "original"
                    )
                } catch {
                    print("⚠️ Failed to save to history: \(error)")
                }
                
                await MainActor.run {
                    processedImage = restored
                    originalImageUrl = originalUrl
                    processedImageUrl = result.outputUrl
                    isProcessing = false
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentStep = .result
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func savePhoto() {
        guard let image = processedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
    
    private func resetFlow() {
        selectedImage = nil
        processedImage = nil
        originalImageUrl = nil
        processedImageUrl = nil
        processingProgress = 0.0
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = .upload
        }
    }
}

// MARK: - Screen 1: Upload View
struct RestoreUploadView: View {
    @Binding var selectedImage: UIImage?
    let onContinue: () -> Void
    let onDismiss: () -> Void
    let geometry: GeometryProxy
    
    @State private var showPhotoPicker = false
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: geometry.adaptiveSpacing(8)) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: geometry.adaptiveFontSize(18), weight: .semibold))
                            .foregroundColor(.deepPlum)
                        
                        Text("Restore Memories")
                            .font(.system(size: geometry.adaptiveFontSize(20), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, geometry.adaptivePadding())
            .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 28 : 38)
            .padding(.bottom, geometry.adaptiveSpacing(16))
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : -20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: geometry.adaptiveSpacing(32)) {
                    // Title and Subtitle
                    VStack(spacing: geometry.adaptiveSpacing(12)) {
                        Text("Fix, colorize, and relive your favorite old photos")
                            .font(.system(size: geometry.adaptiveFontSize(18), weight: .medium))
                            .foregroundColor(.softPlum)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, geometry.adaptiveSpacing(20))
                    }
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    
                    // Upload Card
                    UploadCard(
                        label: "Select a photo to restore",
                        image: selectedImage,
                        onTap: { showPhotoPicker = true },
                        geometry: geometry
                    )
                    .frame(height: geometry.size.height * 0.5)
                    .padding(.horizontal, geometry.adaptiveSpacing(20))
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 30)
                    
                    // Change Photo Button (if image selected)
                    if selectedImage != nil {
                        Button(action: { showPhotoPicker = true }) {
                            Text("Change Photo")
                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                                .foregroundColor(.softPlum)
                        }
                        .opacity(animateElements ? 1 : 0)
                    }
                }
                .padding(.top, geometry.adaptiveSpacing(20))
                .padding(.bottom, geometry.adaptiveSpacing(100))
            }
            
            Spacer()
            
            // Continue Button
            if selectedImage != nil {
                Button(action: onContinue) {
                    HStack(spacing: geometry.adaptiveSpacing(12)) {
                        Text("Continue")
                            .font(.system(size: geometry.adaptiveFontSize(17), weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.adaptiveSize(56))
                    .background(LinearGradient.primaryBrand)
                    .cornerRadius(geometry.adaptiveCornerRadius(16))
                    .shadow(color: Color.blushPink.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, geometry.adaptiveSpacing(20))
                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 40)
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: Binding(
            get: { nil },
            set: { newValue in
                if let item = newValue {
                    loadPhoto(from: item)
                }
            }
        ), matching: .images)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateElements = true
            }
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedImage = image
                    }
                }
            }
        }
    }
    
}

// MARK: - Screen 2: Processing View
struct RestoreProcessingView: View {
    let progress: Double
    let geometry: GeometryProxy
    
    var body: some View {
        ProgressAnimation(
            title: "Bringing your photo back to life…",
            subtitle: "This might take a few seconds — we're restoring every detail.",
            progress: progress,
            geometry: geometry
        )
    }
}

// MARK: - Screen 3: Result View
struct RestoreResultView: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    let onSave: () -> Void
    let onShare: () -> Void
    let onTryAnother: () -> Void
    let onDismiss: () -> Void
    let geometry: GeometryProxy
    
    @State private var animateElements = false
    @State private var isSaved = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: geometry.adaptiveSpacing(8)) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: geometry.adaptiveFontSize(18), weight: .semibold))
                            .foregroundColor(.deepPlum)
                        
                        Text("Your Restored Photo")
                            .font(.system(size: geometry.adaptiveFontSize(20), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, geometry.adaptiveSpacing(20))
            .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 16 : 24)
            .padding(.bottom, geometry.adaptiveSpacing(16))
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : -20)
            
            // Before/After Slider
            BeforeAfterSlider(
                beforeImage: beforeImage,
                afterImage: afterImage,
                geometry: geometry
            )
            .frame(height: geometry.size.height * 0.6)
            .padding(.horizontal, geometry.adaptiveSpacing(20))
            .opacity(animateElements ? 1 : 0)
            .scaleEffect(animateElements ? 1.0 : 0.95)
            
            // Swipe hint
            Text("← Swipe to compare →")
                .font(.system(size: geometry.adaptiveFontSize(15), weight: .medium))
                .foregroundColor(.softPlum)
                .padding(.top, geometry.adaptiveSpacing(16))
                .opacity(animateElements ? 1 : 0)
            
            Spacer()
            
            // Action Buttons
            ResultActionButtons(
                onSave: {
                    onSave()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isSaved = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isSaved = false
                        }
                    }
                },
                onShare: onShare,
                onTryAnother: onTryAnother,
                geometry: geometry,
                isSaved: isSaved
            )
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateElements = true
            }
        }
    }
}

#Preview {
    PhotoRestoreFlow()
        .environmentObject(ImageProcessingService.shared)
}

