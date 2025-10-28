//
//  PhotoRestoreFlow.swift
//  EverWith
//
//  Photo Restore Mode Flow
//  Flow: Upload → Processing → Result
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - Photo Restore Flow Coordinator
struct PhotoRestoreFlow: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    @StateObject private var monetizationManager = MonetizationManager.shared
    
    @State private var currentStep: RestoreStep = .upload
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var originalImageUrl: String?
    @State private var processedImageUrl: String?
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var queueTimeRemaining = 12
    @State private var queueTimer: Timer?
    
    enum RestoreStep {
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
        
        // Track first photo upload
        print("📊 First photo uploaded for restore")
        
        // Check access before processing
        Task {
            let hasAccess = await monetizationManager.checkAccess(for: .restore)
            
            if !hasAccess {
                // Show credit needed paywall
                monetizationManager.triggerCreditNeededUpsell()
                return
            }
            
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentStep = .processing
                }
            }
            
            // Process with monetization
            monetizationManager.processImageWithMonetization(
                image: image,
                mode: .restore,
                onResult: { result in
                    Task { @MainActor in
                        processedImage = result
                        isProcessing = false
                        
                        // Track first result viewed
                        print("📊 First result viewed")
                        
                        // Track feature usage
                        print("📊 Restore used")
                        
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentStep = .result
                        }
                    }
                },
                onError: { error in
                    Task { @MainActor in
                        isProcessing = false
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            )
        }
    }
    
    private func savePhoto() {
        guard let image = processedImage else { return }
        
        // Use centralized export function
        monetizationManager.exportImageToPhotos(image: image) { success in
            if success {
                print("📊 Image saved successfully")
            }
        }
    }
    
    private func sharePhoto() {
        guard let image = processedImage else { return }
        
        // Use centralized export function
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
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                            .foregroundColor(.deepPlum)
                        
                        Text("Restore Memories")
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
                    // Title and Subtitle
                    VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                        Text("Fix, colorize, and relive your favorite old photos")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                            .foregroundColor(.softPlum)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
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
                    .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 30)
                    
                    // Change Photo Button (if image selected)
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
            
            // Continue Button (always visible to show credit cost)
            ContinueButton(
                onContinue: onContinue,
                creditCost: MonetizationManager.shared.getCreditCost(for: .restore),
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

// MARK: - Screen 2: Processing View
struct RestoreProcessingView: View {
    let progress: Double
    let geometry: GeometryProxy
    @StateObject private var monetizationManager = MonetizationManager.shared
    @State private var queueTimeRemaining = 12
    @State private var queueTimer: Timer?
    @State private var showContent = false
    @State private var currentStageIndex = 0
    
    let loadingStages = [
        ("Uploading photo", "arrow.up.circle.fill"),
        ("Analyzing details", "magnifyingglass"),
        ("Enhancing quality", "wand.and.rays"),
        ("Finalizing result", "sparkles")
    ]
    
    var body: some View {
        ZStack {
            ProgressAnimation(
                title: "Restoring Your Memory",
                subtitle: currentStageIndex < loadingStages.count ? loadingStages[currentStageIndex].0 : "Processing...",
                progress: progress,
                geometry: geometry,
                isQueueMode: monetizationManager.revenueCatService.subscriptionStatus.tier == .free && queueTimeRemaining > 0,
                queueTimeRemaining: queueTimeRemaining,
                onPremiumTap: {
                    MonetizationManager.shared.triggerQueuePriorityUpsell()
                }
            )
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.9)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            
            if monetizationManager.revenueCatService.subscriptionStatus.tier == .free {
                startQueueTimer()
            }
        }
        .onDisappear {
            queueTimer?.invalidate()
        }
        .onChange(of: progress) { newProgress in
            updateStage(for: newProgress)
        }
    }
    
    private func startQueueTimer() {
        queueTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if queueTimeRemaining > 0 {
                queueTimeRemaining -= 1
            } else {
                queueTimer?.invalidate()
            }
        }
    }
    
    private func updateStage(for progress: Double) {
        let newStage = min(Int(progress * Double(loadingStages.count)), loadingStages.count - 1)
        if newStage != currentStageIndex {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStageIndex = newStage
            }
        }
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
    @StateObject private var monetizationManager = MonetizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                            .foregroundColor(.deepPlum)
                        
                        Text("Your Restored Photo")
                            .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
            .padding(.top, adaptiveSpacing(16, for: geometry))
            .padding(.bottom, adaptiveSpacing(16, for: geometry))
            .opacity(animateElements ? 1 : 0)
            .offset(y: animateElements ? 0 : -20)
            
            // Before/After Toggle
            BeforeAfterToggleButton(
                beforeImage: beforeImage,
                afterImage: afterImage,
                geometry: geometry
            )
            .frame(height: geometry.size.height * 0.7)
            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
            .opacity(animateElements ? 1 : 0)
            .scaleEffect(animateElements ? 1.0 : 0.95)
            
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
            
            // HD Upgrade Prompt for free users
            if monetizationManager.revenueCatService.subscriptionStatus.tier == .free {
                HDUpgradePrompt()
                    .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                    .padding(.top, adaptiveSpacing(16, for: geometry))
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateElements = true
            }
        }
    }
}

// MARK: - HD Upgrade Prompt
struct HDUpgradePrompt: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "4k.tv")
                    .foregroundColor(.yellow)
                Text("Unlock HD Quality")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("Remove watermark and get crystal clear 4K quality")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Upgrade Now") {
                MonetizationManager.shared.triggerPostResultUpsell(resultImage: UIImage())
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.yellow)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    PhotoRestoreFlow()
        .environmentObject(ImageProcessingService.shared)
}
