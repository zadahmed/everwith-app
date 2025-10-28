//
//  ReuniteFlow.swift
//  EverWith
//
//  Reunite Flow - Lost Connection
//

import SwiftUI
import PhotosUI
import UIKit

struct ReuniteFlow: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    @StateObject private var monetizationManager = MonetizationManager.shared
    
    @State private var currentStep: ReuniteStep = .upload
    @State private var selectedImages: [UIImage] = []
    @State private var processedImage: UIImage?
    @State private var processedImageUrl: String?
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var backgroundPrompt: String = "warm emotional background"
    
    enum ReuniteStep {
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
                    ReuniteUploadView(
                        selectedImages: $selectedImages,
                        backgroundPrompt: $backgroundPrompt,
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
                    if let processed = processedImage {
                        MergeResultView(
                            mergedImage: processed,
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
        guard selectedImages.count >= 2 else { return }
        
        Task {
            let hasAccess = await monetizationManager.checkAccess(for: .merge)
            
            if !hasAccess {
                monetizationManager.triggerCreditNeededUpsell()
                return
            }
            
            // Consume the credit
            let accessUsed = await monetizationManager.requestAccess(for: .merge)
            guard accessUsed else {
                await MainActor.run {
                    errorMessage = "Failed to use credit"
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
                let result = try await imageProcessingService.processReunite(
                    imageA: selectedImages[0],
                    imageB: selectedImages[1],
                    backgroundPrompt: backgroundPrompt.isEmpty ? nil : backgroundPrompt
                )
                
                // Save to history
                if case .completed(let jobResult) = imageProcessingService.processingState {
                    Task {
                        do {
                            let _ = try await imageProcessingService.saveToHistory(
                                imageType: "reunite",
                                originalImageUrl: nil,
                                processedImageUrl: jobResult.outputUrl,
                                qualityTarget: "standard",
                                outputFormat: "png",
                                aspectRatio: "4:5",
                                backgroundPrompt: backgroundPrompt.isEmpty ? nil : backgroundPrompt
                            )
                            print("✅ Saved reunite image to history")
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
        selectedImages = []
        processedImage = nil
        processedImageUrl = nil
        processingProgress = 0.0
        backgroundPrompt = "warm emotional background"
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = .upload
        }
    }
}

// MARK: - Reunite Upload View
struct ReuniteUploadView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var backgroundPrompt: String
    let onContinue: () -> Void
    let onDismiss: () -> Void
    let geometry: GeometryProxy
    
    @State private var showPhotoPicker = false
    @State private var currentPickerSlot: Int = 0
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
                        
                        Text("Lost Connection")
                            .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, adaptivePadding(for: geometry))
            .padding(.bottom, adaptiveSpacing(16, for: geometry))
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : -20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: adaptiveSpacing(32, for: geometry)) {
                    Text("Reunite with loved ones")
                        .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                        .foregroundColor(.softPlum)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                    
                    // Two Upload Slots
                    HStack(spacing: adaptiveSpacing(16, for: geometry)) {
                        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            UploadCard(
                                label: "Person 1",
                                image: selectedImages.count > 0 ? selectedImages[0] : nil,
                                onTap: {
                                    currentPickerSlot = 0
                                    showPhotoPicker = true
                                },
                                geometry: geometry
                            )
                            .frame(height: geometry.size.height * 0.35)
                        }
                        
                        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                            UploadCard(
                                label: "Person 2",
                                image: selectedImages.count > 1 ? selectedImages[1] : nil,
                                onTap: {
                                    currentPickerSlot = 1
                                    showPhotoPicker = true
                                },
                                geometry: geometry
                            )
                            .frame(height: geometry.size.height * 0.35)
                        }
                    }
                    .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 30)
                }
                .padding(.top, adaptiveSpacing(20, for: geometry))
                .padding(.bottom, adaptiveSpacing(100, for: geometry))
            }
            
            Spacer()
            
            ContinueButton(
                onContinue: onContinue,
                creditCost: MonetizationManager.shared.getCreditCost(for: .merge),
                isPremium: MonetizationManager.shared.revenueCatService.subscriptionStatus.tier != .free,
                isEnabled: selectedImages.count >= 2,
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
                        if currentPickerSlot == 0 {
                            if selectedImages.count > 0 {
                                selectedImages[0] = image
                            } else {
                                selectedImages.append(image)
                            }
                        } else {
                            if selectedImages.count > 1 {
                                selectedImages[1] = image
                            } else {
                                selectedImages.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

