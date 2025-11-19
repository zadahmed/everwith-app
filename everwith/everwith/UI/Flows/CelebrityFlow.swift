//
//  CelebrityFlow.swift
//  EverWith
//
//  Celebrity Transformation Flow - Famous Frame
//

import SwiftUI
import PhotosUI
import UIKit

struct CelebrityFlow: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    @StateObject private var monetizationManager = MonetizationManager.shared
    
    @State private var currentStep: CelebrityStep = .upload
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var processedImageUrl: String?
    @State private var originalImageUrl: String?
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var celebrityStyle: CelebrityStyle = .movieStar
    
    enum CelebrityStep {
        case upload
        case processing
        case result
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CleanWhiteBackground()
                    .ignoresSafeArea()
                
                switch currentStep {
                case .upload:
                    CelebrityUploadView(
                        selectedImage: $selectedImage,
                        celebrityStyle: $celebrityStyle,
                        onContinue: { startProcessing() },
                        onDismiss: { dismiss() },
                        geometry: geometry
                    )
                    
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
        .sheet(isPresented: $monetizationManager.showPaywall) {
            PaywallView(trigger: monetizationManager.currentPaywallTrigger)
        }
        .onReceive(imageProcessingService.$processingProgress) { progress in
            if let p = progress {
                processingProgress = Double(p.currentStepIndex) / Double(p.totalSteps)
            }
        }
    }
    
    private func startProcessing() {
        guard let image = selectedImage else { return }
        
        Task {
            let hasAccess = await monetizationManager.checkAccess(for: .merge)
            
            if !hasAccess {
                monetizationManager.triggerCreditNeededUpsell()
                return
            }
            
            // Consume the credit
            let result = await monetizationManager.requestAccess(for: .merge)
            guard result.0 else {
                await MainActor.run {
                    errorMessage = result.1 ?? "Failed to use credit"
                    showError = true
                }
                return
            }
            
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentStep = .processing
                }
            }
            
            do {
                let result = try await imageProcessingService.processCelebrity(
                    image: image,
                    celebrityStyle: celebrityStyle
                )
                
                // Get the processed image URL from the API result
                if case .completed(let jobResult) = imageProcessingService.processingState {
                    processedImageUrl = jobResult.outputUrl
                    
                    // Save to history
                    Task {
                        do {
                            let _ = try await imageProcessingService.saveToHistory(
                                imageType: "celebrity",
                                originalImageUrl: originalImageUrl,
                                processedImageUrl: jobResult.outputUrl,
                                qualityTarget: "standard",
                                outputFormat: "png",
                                aspectRatio: "original"
                            )
                            print("✅ Saved celebrity image to history")
                        } catch {
                            print("❌ Failed to save to history: \(error)")
                        }
                    }
                }
                
                await MainActor.run {
                    processedImage = result
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentStep = .result
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func savePhoto() {
        guard let image = processedImage else { return }
        monetizationManager.exportImageToPhotos(image: image)
    }
    
    private func sharePhoto() {
        guard let image = processedImage else { return }
        let imageToShare = monetizationManager.exportImageToShare(image: image)
        let activityVC = UIActivityViewController(
            activityItems: [imageToShare],
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
        processedImageUrl = nil
        originalImageUrl = nil
        processingProgress = 0.0
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = .upload
        }
    }
}

// MARK: - Celebrity Upload View
struct CelebrityUploadView: View {
    @Binding var selectedImage: UIImage?
    @Binding var celebrityStyle: CelebrityStyle
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
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                            .foregroundColor(.deepPlum)
                        
                        Text("Famous Frame")
                            .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, adaptivePadding(for: geometry))
            .padding(.top, adaptiveSpacing(16, for: geometry))
            .padding(.bottom, adaptiveSpacing(16, for: geometry))
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : -20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: adaptiveSpacing(32, for: geometry)) {
                    Text("Get the celebrity treatment")
                        .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                        .foregroundColor(.softPlum)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                    
                    UploadCard(
                        label: "Select your photo",
                        image: selectedImage,
                        onTap: { showPhotoPicker = true },
                        geometry: geometry
                    )
                    .frame(height: geometry.size.height * 0.5)
                    .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 30)
                    
                    // Style Selection
                    CelebrityStyleSelectionView(
                        celebrityStyle: $celebrityStyle,
                        geometry: geometry
                    )
                    .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                    .opacity(animateElements ? 1 : 0)
                    
                    if selectedImage != nil {
                        Button(action: { showPhotoPicker = true }) {
                            Text("Change Photo")
                                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                .foregroundColor(.softPlum)
                        }
                        .opacity(animateElements ? 1 : 0)
                    }
                }
                .padding(.top, adaptiveSpacing(20, for: geometry))
                .padding(.bottom, adaptiveSpacing(100, for: geometry))
            }
            
            Spacer()
            
            ContinueButton(
                onContinue: onContinue,
                creditCost: MonetizationManager.shared.getCreditCost(for: .merge),
                isPremium: MonetizationManager.shared.revenueCatService.subscriptionStatus.tier != .free,
                isEnabled: selectedImage != nil,
                geometry: geometry
            )
            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 8 : 16)
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : 40)
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

// MARK: - Celebrity Style Selection View
struct CelebrityStyleSelectionView: View {
    @Binding var celebrityStyle: CelebrityStyle
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: adaptiveSpacing(12, for: geometry)) {
            Text("Choose style")
                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                .foregroundColor(.deepPlum)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                    ForEach(CelebrityStyle.allCases, id: \.self) { style in
                        CelebrityStyleButton(
                            style: style,
                            isSelected: celebrityStyle == style,
                            geometry: geometry
                        ) {
                            withAnimation { celebrityStyle = style }
                        }
                    }
                }
                .padding(.horizontal, adaptiveSpacing(4, for: geometry))
            }
        }
    }
}

// MARK: - Celebrity Style Button
struct CelebrityStyleButton: View {
    let style: CelebrityStyle
    let isSelected: Bool
    let geometry: GeometryProxy
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(style.displayName)
                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                .foregroundColor(isSelected ? .pureWhite : .deepPlum)
                .padding(.horizontal, adaptiveSpacing(16, for: geometry))
                .padding(.vertical, adaptiveSpacing(10, for: geometry))
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                .fill(LinearGradient.primaryBrand)
                        } else {
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                .fill(Color.pureWhite)
                                .overlay(
                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                        .stroke(LinearGradient.cardGlow, lineWidth: 1)
                                )
                        }
                    }
                )
        }
    }
}

